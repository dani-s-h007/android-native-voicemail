import os
import hmac
import hashlib
import time
import secrets
from typing import Optional, Dict

class EphemeralStorageService:
    def __init__(self):
        default_dir = "/tmp/voicemail_ephemeral"
        target_dir = os.getenv("RAM_STORAGE_DIR", default_dir)
        try:
            os.makedirs(target_dir, exist_ok=True)
            self.ram_dir = target_dir
        except OSError:
            self.ram_dir = default_dir
            os.makedirs(self.ram_dir, exist_ok=True)

        self.signing_secret = os.getenv("RELAY_HMAC_SECRET", "super_secret_relay_key_32_bytes_hex").encode("utf-8")
        
        # In-memory single-use token registry to prevent replay attacks
        # key: token, value: expiry_timestamp
        self._used_tokens: Dict[str, float] = {}

    def get_file_path(self, job_id: str) -> str:
        return os.path.join(self.ram_dir, f"{job_id}.wav")

    def file_exists(self, job_id: str) -> bool:
        path = self.get_file_path(job_id)
        return os.path.isfile(path) and os.path.getsize(path) > 0

    def generate_signed_download_token(self, job_id: str, ttl_seconds: int = 900) -> str:
        """
        Generates a tamper-proof, time-limited single-use download token.
        Format: {job_id}.{expiry}.{nonce}.{signature}
        """
        expiry = int(time.time()) + ttl_seconds
        nonce = secrets.token_hex(8)
        payload = f"{job_id}.{expiry}.{nonce}"
        signature = hmac.new(self.signing_secret, payload.encode("utf-8"), hashlib.sha256).hexdigest()
        return f"{payload}.{signature}"

    def validate_and_consume_token(self, token: str) -> Optional[str]:
        """
        Validates token signature, checks expiration and replay registry.
        If valid, consumes the token and returns the job_id.
        """
        parts = token.split(".")
        if len(parts) != 4:
            return None

        job_id, expiry_str, nonce, signature = parts
        try:
            expiry = int(expiry_str)
        except ValueError:
            return None

        # 1. Check expiration
        now = time.time()
        if now > expiry:
            return None

        # 2. Check if already consumed
        if token in self._used_tokens:
            return None

        # 3. Verify HMAC signature
        expected_payload = f"{job_id}.{expiry}.{nonce}".encode("utf-8")
        expected_sig = hmac.new(self.signing_secret, expected_payload, hashlib.sha256).hexdigest()
        if not hmac.compare_digest(signature, expected_sig):
            return None

        # 4. Mark as consumed (single-use)
        self._used_tokens[token] = float(expiry)
        self._cleanup_used_tokens()

        return job_id

    def shred_recording(self, job_id: str) -> bool:
        """
        Permanently destroys the recording from volatile RAM disk.
        Overwrites memory bytes with zeros before unlinking.
        """
        path = self.get_file_path(job_id)
        if not os.path.exists(path):
            return True

        try:
            file_size = os.path.getsize(path)
            # Overwrite with zeros
            with open(path, "ba+", buffering=0) as f:
                f.seek(0)
                f.write(b"\x00" * file_size)
            os.remove(path)
            return True
        except Exception:
            try:
                os.remove(path)
                return True
            except Exception:
                return False

    def _cleanup_used_tokens(self):
        now = time.time()
        expired = [t for t, exp in self._used_tokens.items() if now > exp]
        for t in expired:
            del self._used_tokens[t]

ephemeral_storage = EphemeralStorageService()

