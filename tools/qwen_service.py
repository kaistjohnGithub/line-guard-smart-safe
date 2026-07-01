"""
Qwen Local Service — FastAPI micro-service that runs Qwen inference.
Run this OUTSIDE Docker using the vila-safety micromamba environment.

Start (normal):
    micromamba run -n vila-safety python tools/qwen_service.py

Start (with Flash Attention):
    micromamba run -n vila-safety env USE_FLASH_ATTN=1 python tools/qwen_service.py
"""
import os
import time
import tempfile
from pathlib import Path
from datetime import timedelta

import cv2
import uvicorn
from fastapi import FastAPI, File, Form, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image

# ── Model cache on D drive ─────────────────────────────────
_dir = Path(__file__).parent.parent
MODEL_CACHE = str(_dir / "model" / "hub")
os.environ.setdefault("HF_HUB_CACHE", MODEL_CACHE)
os.environ.setdefault("HF_HUB_DISABLE_XET", "1")

app = FastAPI(title="Qwen Local Service", version="2.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

_model = None
_processor = None
_flash_attn_enabled = False

DEFAULT_PROMPT = (
    "You are a factory safety inspector. Describe this scene in detail:\n"
    "1. Workers visible and their PPE (helmet, vest, gloves, boots)\n"
    "2. Equipment and machinery (forklifts, conveyors, etc.)\n"
    "3. Safety hazards or violations\n"
    "4. Overall safety status: SAFE / WARNING / DANGER"
)
MODEL_ID = os.getenv("QWEN_MODEL", "Qwen/Qwen2.5-VL-3B-Instruct")


def load_model():
    global _model, _processor, _flash_attn_enabled
    if _model:
        return
    import torch
    from transformers import AutoProcessor, Qwen2_5_VLForConditionalGeneration, BitsAndBytesConfig
    print(f"[Qwen] Loading {MODEL_ID} on GPU...")
    bnb = BitsAndBytesConfig(
        load_in_4bit=True, bnb_4bit_compute_dtype=torch.float16,
        bnb_4bit_use_double_quant=True, bnb_4bit_quant_type="nf4"
    )
    kwargs = {"quantization_config": bnb, "device_map": "auto"}

    use_fa = os.getenv("USE_FLASH_ATTN", "0") == "1"
    if use_fa:
        try:
            import flash_attn
            kwargs["attn_implementation"] = "flash_attention_2"
            _flash_attn_enabled = True
            print(f"[Qwen] Flash Attention 2 enabled (flash_attn v{flash_attn.__version__})")
        except ImportError:
            print("[Qwen] USE_FLASH_ATTN=1 but flash_attn not installed — using default attention")

    _model = Qwen2_5_VLForConditionalGeneration.from_pretrained(MODEL_ID, **kwargs)
    _processor = AutoProcessor.from_pretrained(MODEL_ID)
    print(f"[Qwen] Model ready. flash_attn={_flash_attn_enabled}")


def _resize(pil_img, max_dim=640):
    if max(pil_img.size) > max_dim:
        r = max_dim / max(pil_img.size)
        pil_img = pil_img.resize(
            (int(pil_img.width * r), int(pil_img.height * r)), Image.LANCZOS
        )
    return pil_img


def _infer(pil_img, prompt, max_new_tokens=800):
    """Single-frame inference."""
    from qwen_vl_utils import process_vision_info
    import torch
    messages = [{"role": "user", "content": [
        {"type": "image", "image": pil_img},
        {"type": "text",  "text": prompt},
    ]}]
    text = _processor.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    image_inputs, video_inputs = process_vision_info(messages)
    inputs = _processor(text=[text], images=image_inputs, videos=video_inputs,
                        padding=True, return_tensors="pt").to(_model.device)
    with torch.no_grad():
        out = _model.generate(**inputs, max_new_tokens=max_new_tokens,
                              do_sample=False, temperature=None, top_p=None)
    gen = out[:, inputs.input_ids.shape[1]:]
    return _processor.batch_decode(gen, skip_special_tokens=True,
                                   clean_up_tokenization_spaces=False)[0].strip()


def _infer_multi(pil_imgs, prompt, max_new_tokens=400):
    """Multi-frame inference — all frames sent as video type in ONE forward pass."""
    from qwen_vl_utils import process_vision_info
    import torch
    if len(pil_imgs) == 1:
        return _infer(pil_imgs[0], prompt, max_new_tokens)
    messages = [{"role": "user", "content": [
        {"type": "video", "video": pil_imgs},
        {"type": "text",  "text": prompt},
    ]}]
    text = _processor.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    image_inputs, video_inputs = process_vision_info(messages)
    inputs = _processor(text=[text], images=image_inputs, videos=video_inputs,
                        padding=True, return_tensors="pt").to(_model.device)
    with torch.no_grad():
        out = _model.generate(**inputs, max_new_tokens=max_new_tokens,
                              do_sample=False, temperature=None, top_p=None)
    gen = out[:, inputs.input_ids.shape[1]:]
    return _processor.batch_decode(gen, skip_special_tokens=True,
                                   clean_up_tokenization_spaces=False)[0].strip()


@app.on_event("startup")
def startup():
    load_model()


@app.get("/health")
def health():
    import torch
    return {
        "status": "ok",
        "model": MODEL_ID,
        "cuda": torch.cuda.is_available(),
        "gpu": torch.cuda.get_device_name(0) if torch.cuda.is_available() else None,
        "flash_attn": _flash_attn_enabled,
    }


@app.post("/describe-frame")
async def describe_frame_endpoint(
    file: UploadFile = File(...),
    prompt: str = Form(DEFAULT_PROMPT),
    max_new_tokens: int = Form(800),
    resolution: int = Form(640),
):
    """Accept a single image frame, return Qwen description."""
    data = await file.read()
    import numpy as np
    arr = np.frombuffer(data, np.uint8)
    frame_bgr = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if frame_bgr is None:
        raise HTTPException(status_code=400, detail="Cannot decode image")
    pil = Image.fromarray(cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB))
    pil = _resize(pil, max_dim=resolution)
    t0 = time.time()
    desc = _infer(pil, prompt, max_new_tokens=max_new_tokens)
    return {
        "description": desc,
        "latency_ms": int((time.time() - t0) * 1000),
        "settings": {"max_new_tokens": max_new_tokens, "resolution": resolution},
    }


@app.post("/analyze")
async def analyze_video(
    file: UploadFile = File(...),
    interval_sec: float = Form(3.0),
    max_frames: int = Form(10),
    max_new_tokens: int = Form(300),
    resolution: int = Form(480),
    multi_frame: int = Form(1),
    prompt: str = Form(DEFAULT_PROMPT),
):
    """Accept video file, extract frames, run Qwen (single or multi-frame), return results."""
    suffix = Path(file.filename or "video.mp4").suffix or ".mp4"
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
    tmp.write(await file.read())
    tmp.close()

    try:
        cap = cv2.VideoCapture(tmp.name)
        if not cap.isOpened():
            raise HTTPException(status_code=400, detail="Cannot open video")
        fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
        step = max(1, int(fps * interval_sec))
        max_frames = min(max_frames, 60)
        multi_frame = max(1, min(multi_frame, 10))

        frames_data, idx, extracted = [], 0, 0
        while cap.isOpened() and extracted < max_frames:
            ret, frame = cap.read()
            if not ret:
                break
            if idx % step == 0:
                ts = idx / fps
                frames_data.append({
                    "frame_idx": idx,
                    "timestamp_sec": round(ts, 2),
                    "timestamp_str": str(timedelta(seconds=int(ts))),
                    "frame": frame.copy(),
                })
                extracted += 1
            idx += 1
        cap.release()

        results = []

        if multi_frame > 1:
            # Group frames into batches → 1 inference call per batch
            for i in range(0, len(frames_data), multi_frame):
                batch = frames_data[i:i + multi_frame]
                pils = [
                    _resize(Image.fromarray(cv2.cvtColor(fd["frame"], cv2.COLOR_BGR2RGB)), resolution)
                    for fd in batch
                ]
                t0 = time.time()
                desc = _infer_multi(pils, prompt, max_new_tokens=max_new_tokens)
                latency = int((time.time() - t0) * 1000)
                mid = batch[len(batch) // 2]
                results.append({
                    "frame_idx": mid["frame_idx"],
                    "timestamp_sec": mid["timestamp_sec"],
                    "timestamp_str": f"{batch[0]['timestamp_str']} – {batch[-1]['timestamp_str']}",
                    "frames_in_batch": len(batch),
                    "description": desc,
                    "latency_ms": latency,
                })
        else:
            for fd in frames_data:
                pil = _resize(Image.fromarray(cv2.cvtColor(fd["frame"], cv2.COLOR_BGR2RGB)), resolution)
                t0 = time.time()
                desc = _infer(pil, prompt, max_new_tokens=max_new_tokens)
                latency = int((time.time() - t0) * 1000)
                results.append({
                    "frame_idx": fd["frame_idx"],
                    "timestamp_sec": fd["timestamp_sec"],
                    "timestamp_str": fd["timestamp_str"],
                    "frames_in_batch": 1,
                    "description": desc,
                    "latency_ms": latency,
                })

        return {
            "total_frames": len(results),
            "frames": results,
            "settings": {
                "max_new_tokens": max_new_tokens,
                "resolution": resolution,
                "interval_sec": interval_sec,
                "multi_frame": multi_frame,
            },
        }

    finally:
        os.unlink(tmp.name)


@app.post("/reload-flash-attn")
async def reload_flash_attn_endpoint(enable: int = Form(1)):
    """Unload and reload model with or without Flash Attention 2 (~30–60s)."""
    global _model, _processor, _flash_attn_enabled
    import gc
    import torch
    print(f"[Qwen] Reloading model with flash_attn={'1' if enable else '0'}…")
    _model = None
    _processor = None
    _flash_attn_enabled = False
    gc.collect()
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    os.environ["USE_FLASH_ATTN"] = "1" if enable else "0"
    load_model()
    return {"status": "ok", "flash_attn": _flash_attn_enabled, "model": MODEL_ID}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001, log_level="info")
