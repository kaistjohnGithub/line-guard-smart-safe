from __future__ import annotations

from typing import Any

import requests
from fastapi import HTTPException

from app.config import settings


GEMINI_MODEL_ALIASES = {
    "gemini-2.0-flash": "gemini-2.5-flash",
    "models/gemini-2.0-flash": "gemini-2.5-flash",
    "gemini-2.0-flash-thinking-exp": "gemini-2.5-flash",
}


def _normalize_history(history: list[dict[str, Any]] | None) -> list[dict[str, str]]:
    normalized: list[dict[str, str]] = []
    for item in history or []:
        role = str(item.get("role") or "").strip().lower()
        content = str(item.get("content") or "").strip()
        if role not in {"user", "assistant"} or not content:
            continue
        normalized.append({"role": role, "content": content})
    return normalized[-12:]


def _normalize_gemini_model(model: str | None) -> str:
    requested = (model or settings.gemini_model).strip() or settings.gemini_model
    return GEMINI_MODEL_ALIASES.get(requested, requested)


def _gemini_chat(system_prompt: str, history: list[dict[str, str]], message: str, model: str | None) -> str:
    if not settings.gemini_api_key:
        raise HTTPException(status_code=400, detail="Gemini API key is not configured")

    endpoint_model = _normalize_gemini_model(model)
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{endpoint_model}:generateContent?key={settings.gemini_api_key}"

    contents = []
    for item in history:
        contents.append({
            "role": "model" if item["role"] == "assistant" else "user",
            "parts": [{"text": item["content"]}],
        })
    contents.append({"role": "user", "parts": [{"text": message}]})

    payload = {
        "systemInstruction": {
            "parts": [{"text": system_prompt}]
        },
        "contents": contents,
        "generationConfig": {
            "temperature": 0.2,
            "topP": 0.9,
            "maxOutputTokens": 800,
        },
    }

    try:
        response = requests.post(url, json=payload, timeout=60)
    except requests.RequestException as exc:
        raise HTTPException(status_code=502, detail=f"Gemini request failed: {exc}") from exc

    if not response.ok:
        detail = response.json() if "application/json" in response.headers.get("content-type", "") else response.text
        raise HTTPException(status_code=502, detail=f"Gemini API error: {detail}")

    data = response.json()
    candidates = data.get("candidates") or []
    if not candidates:
        raise HTTPException(status_code=502, detail="Gemini returned no candidates")

    parts = (candidates[0].get("content") or {}).get("parts") or []
    text = "\n".join(part.get("text", "") for part in parts if part.get("text"))
    return text.strip() or "No response returned by Gemini."


def _ollama_chat(system_prompt: str, history: list[dict[str, str]], message: str, model: str | None) -> str:
    endpoint_model = (model or settings.ollama_model).strip() or settings.ollama_model
    url = settings.ollama_base_url.rstrip("/") + "/api/chat"

    payload = {
        "model": endpoint_model,
        "stream": False,
        "options": {
            "temperature": 0.2,
        },
        "messages": [
            {"role": "system", "content": system_prompt},
            *history,
            {"role": "user", "content": message},
        ],
    }

    try:
        response = requests.post(url, json=payload, timeout=90)
    except requests.RequestException as exc:
        raise HTTPException(status_code=502, detail=f"Ollama request failed: {exc}") from exc

    if not response.ok:
        detail = response.json() if "application/json" in response.headers.get("content-type", "") else response.text
        if response.status_code == 404:
            raise HTTPException(
                status_code=502,
                detail=f"Ollama endpoint not found at {url}. Check OLLAMA_BASE_URL and confirm Ollama is running.",
            )
        raise HTTPException(status_code=502, detail=f"Ollama API error: {detail}")

    data = response.json()
    content = ((data.get("message") or {}).get("content") or "").strip()
    return content or "No response returned by Ollama."


def run_camera_chat(
    provider: str,
    system_prompt: str,
    message: str,
    model: str | None = None,
    history: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    normalized_history = _normalize_history(history)
    provider_key = (provider or "").strip().lower()

    if not message.strip():
        raise HTTPException(status_code=400, detail="Message is required")

    if provider_key == "gemini":
        answer = _gemini_chat(system_prompt, normalized_history, message, model)
        model_used = _normalize_gemini_model(model)
    elif provider_key == "ollama":
        answer = _ollama_chat(system_prompt, normalized_history, message, model)
        model_used = (model or settings.ollama_model).strip() or settings.ollama_model
    else:
        raise HTTPException(status_code=400, detail="Unsupported provider. Use 'gemini' or 'ollama'.")

    return {
        "answer": answer,
        "provider": provider_key,
        "model": model_used,
    }
