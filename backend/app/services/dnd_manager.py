import os
import struct
import time
from typing import Optional, Dict, Any

class DndManager:
    def __init__(self):
        default_dir = "/tmp/voicemail_greetings"
        target_dir = os.getenv("RAM_GREETINGS_DIR", default_dir)
        try:
            os.makedirs(target_dir, exist_ok=True)
            self.greetings_dir = target_dir
        except OSError:
            self.greetings_dir = default_dir
            os.makedirs(self.greetings_dir, exist_ok=True)
        
        # In-memory session registry: phone_number -> metadata
        self._sessions: Dict[str, Dict[str, Any]] = {}

    def get_greeting_path(self, phone_number: str) -> str:
        clean_phone = "".join(filter(lambda c: c.isdigit() or c == "+", phone_number))
        return os.path.join(self.greetings_dir, f"{clean_phone}.wav")

    def validate_wav_header(self, file_bytes: bytes) -> bool:
        """
        Validates standard RIFF/WAVE header to prevent arbitrary file upload.
        """
        if len(file_bytes) < 44:
            return False

        riff = file_bytes[:4]
        wave = file_bytes[8:12]
        if riff != b"RIFF" or wave != b"WAVE":
            return False

        try:
            # Parse format chunk
            audio_format, num_channels, sample_rate = struct.unpack("<HHH", file_bytes[20:26])
            # Audio format 1 is standard linear PCM
            if audio_format != 1:
                return False
            # Telephony mono preferred (1 channel)
            if num_channels not in (1, 2):
                return False
            # Standard rates: 8000, 16000, 22050, 44100, 48000
            if sample_rate < 8000 or sample_rate > 48000:
                return False
            return True
        except Exception:
            return False

    def activate_dnd_session(
        self,
        phone_number: str,
        expires_at: int,
        mode: str,
        greeting_bytes: bytes
    ) -> bool:
        if not self.validate_wav_header(greeting_bytes):
            raise ValueError("Invalid WAV format. Must be valid PCM WAV audio.")

        greeting_path = self.get_greeting_path(phone_number)
        
        # Write to volatile RAM disk
        with open(greeting_path, "wb") as f:
            f.write(greeting_bytes)

        self._sessions[phone_number] = {
            "expires_at": expires_at,
            "mode": mode,
            "updated_at": int(time.time()),
            "greeting_path": greeting_path
        }
        return True

    def deactivate_dnd_session(self, phone_number: str) -> bool:
        session = self._sessions.pop(phone_number, None)
        greeting_path = self.get_greeting_path(phone_number)
        
        if os.path.exists(greeting_path):
            try:
                os.remove(greeting_path)
            except Exception:
                pass
        return True

    def get_dnd_status(self, phone_number: str) -> Dict[str, Any]:
        session = self._sessions.get(phone_number)
        if not session:
            return {"active": False, "remainingSeconds": 0}

        now = int(time.time())
        expires_at = session["expires_at"]
        
        if now >= expires_at:
            self.deactivate_dnd_session(phone_number)
            return {"active": False, "remainingSeconds": 0}

        return {
            "active": True,
            "mode": session["mode"],
            "expiresAt": expires_at,
            "remainingSeconds": expires_at - now
        }

    def purge_expired_sessions(self):
        now = int(time.time())
        expired = [p for p, data in self._sessions.items() if now >= data["expires_at"]]
        for p in expired:
            self.deactivate_dnd_session(p)

dnd_manager = DndManager()

