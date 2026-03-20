"""
Qwen2.5-VL model loader — lazy singleton.
Import this module only inside the worker service (needs GPU).
"""
import os
import sys
from pathlib import Path
from PIL import Image
import cv2

_model = None
_processor = None

MODEL_ID = os.getenv("QWEN_MODEL", "Qwen/Qwen2.5-VL-3B-Instruct")
MODEL_CACHE = os.getenv("HF_HUB_CACHE", "/app/model/hub")

DEFAULT_PROMPT = (
    "You are a factory safety inspector. Describe this scene in detail:\n"
    "1. Workers visible and their PPE (helmet, vest, gloves, boots)\n"
    "2. Equipment and machinery (forklifts, conveyors, etc.)\n"
    "3. Safety hazards or violations\n"
    "4. Overall safety status: SAFE / WARNING / DANGER"
)


def load_model():
    global _model, _processor
    if _model is not None:
        return

    import torch
    from transformers import AutoProcessor, Qwen2_5_VLForConditionalGeneration, BitsAndBytesConfig

    os.environ.setdefault("HF_HUB_CACHE", MODEL_CACHE)
    os.environ.setdefault("HF_HUB_DISABLE_XET", "1")

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"[Qwen] Loading {MODEL_ID} on {device.upper()}...")

    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_compute_dtype=torch.float16,
        bnb_4bit_use_double_quant=True,
        bnb_4bit_quant_type="nf4",
    ) if device == "cuda" else None

    _model = Qwen2_5_VLForConditionalGeneration.from_pretrained(
        MODEL_ID,
        quantization_config=bnb_config,
        device_map="auto" if device == "cuda" else None,
        torch_dtype=torch.float16 if device == "cuda" else torch.float32,
    )
    _processor = AutoProcessor.from_pretrained(MODEL_ID)
    print("[Qwen] Model loaded.")


def describe_frame(frame_bgr, prompt: str = None) -> str:
    from qwen_vl_utils import process_vision_info
    import torch

    pil_img = Image.fromarray(cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB))
    messages = [{
        "role": "user",
        "content": [
            {"type": "image", "image": pil_img},
            {"type": "text",  "text": prompt or DEFAULT_PROMPT},
        ],
    }]

    text = _processor.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    image_inputs, video_inputs = process_vision_info(messages)
    inputs = _processor(
        text=[text], images=image_inputs, videos=video_inputs,
        padding=True, return_tensors="pt",
    ).to(_model.device)

    with torch.no_grad():
        output_ids = _model.generate(
            **inputs, max_new_tokens=300,
            do_sample=False, temperature=None, top_p=None,
        )

    generated = output_ids[:, inputs.input_ids.shape[1]:]
    return _processor.batch_decode(
        generated, skip_special_tokens=True, clean_up_tokenization_spaces=False
    )[0].strip()
