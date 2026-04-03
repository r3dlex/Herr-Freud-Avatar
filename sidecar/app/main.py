"""
Faster-Whisper STT Sidecar for Herr Freud.
Runs as a Python HTTP service using uvicorn.
"""
import os
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from faster_whisper import WhisperModel
import uvicorn

app = FastAPI(title="Herr Freud STT Sidecar")

MODEL_SIZE = os.getenv("STT_MODEL", "large-v3")
model = None


@app.on_event("startup")
def load_model():
    global model
    compute_type = "float16"  # or "int8" for faster CPU inference
    model = WhisperModel(MODEL_SIZE, compute_type=compute_type)
    print(f"Whisper model '{MODEL_SIZE}' loaded")


class TranscribeRequest(BaseModel):
    file_path: str
    language: Optional[str] = None


class TranscribeResponse(BaseModel):
    transcript: str
    detected_language: str
    confidence: float
    duration_seconds: float


@app.post("/transcribe", response_model=TranscribeResponse)
def transcribe(req: TranscribeRequest):
    if not Path(req.file_path).exists():
        raise HTTPException(status_code=404, detail=f"File not found: {req.file_path}")

    try:
        segments, info = model.transcribe(
            req.file_path,
            language=req.language,
            beam_size=5
        )

        full_transcript = " ".join([s.text for s in segments])

        return TranscribeResponse(
            transcript=full_transcript.strip(),
            detected_language=info.language,
            confidence=info.language_probability,
            duration_seconds=info.duration or 0.0
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
def health():
    return {"status": "ok", "model": MODEL_SIZE}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=9001)