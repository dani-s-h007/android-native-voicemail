import time
import os
from typing import Dict, Any
from faster_whisper import WhisperModel
from app.config import settings

SUPPORTED_LANGUAGES = {"hi", "ml", "ta", "te", "kn", "en"}

class TranscriptionEngine:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(TranscriptionEngine, cls).__new__(cls)
            cls._instance._init_model()
        return cls._instance

    def _init_model(self):
        print(f"[INFO] Initializing Faster-Whisper ({settings.WHISPER_MODEL_SIZE}) on {settings.WHISPER_DEVICE}...")
        try:
            self.model = WhisperModel(
                model_size_or_path=settings.WHISPER_MODEL_SIZE,
                device=settings.WHISPER_DEVICE,
                compute_type=settings.WHISPER_COMPUTE_TYPE,
                download_root="/tmp/whisper_models"
            )
            print("[INFO] Faster-Whisper initialized successfully.")
        except Exception as e:
            print(f"[WARN] Faster-Whisper model loading deferred: {e}")
            self.model = None

    def transcribe(self, audio_path: str) -> Dict[str, Any]:
        if not os.path.exists(audio_path):
            raise FileNotFoundError(f"Audio file {audio_path} does not exist for transcription.")

        if self.model is None:
            self._init_model()

        start_time = time.time()
        
        segments, info = self.model.transcribe(
            audio_path,
            beam_size=5,
            vad_filter=True,
            vad_parameters=dict(min_silence_duration_ms=500),
            task="transcribe"
        )

        detected_lang = info.language
        lang_prob = float(info.language_probability)

        transcript_text_parts = []
        for segment in segments:
            transcript_text_parts.append(segment.text.strip())

        full_transcript = " ".join(transcript_text_parts).strip()
        processing_time_ms = int((time.time() - start_time) * 1000)

        if not full_transcript:
            full_transcript = "[No audible speech recorded]"

        return {
            "transcript_text": full_transcript,
            "detected_language": detected_lang,
            "confidence_score": round(lang_prob, 3),
            "model_name": f"faster-whisper-{settings.WHISPER_MODEL_SIZE}",
            "processing_time_ms": processing_time_ms
        }

transcription_engine = TranscriptionEngine()

