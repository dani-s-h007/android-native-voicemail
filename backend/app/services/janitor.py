import os
import time
import asyncio
from app.services.ephemeral_storage import ephemeral_storage
from app.services.dnd_manager import dnd_manager

MAX_AUDIO_RETENTION_SECONDS = 86400  # 24 Hours auto-delete

async def run_janitor_loop():
    """
    Background daemon running every 60 seconds to guarantee zero-storage compliance.
    """
    while True:
        try:
            # 1. Clean up expired DND greetings
            dnd_manager.purge_expired_sessions()

            # 2. Clean up uncollected voicemail recordings > 24 hours
            ram_dir = ephemeral_storage.ram_dir
            if os.path.exists(ram_dir):
                now = time.time()
                for filename in os.listdir(ram_dir):
                    if filename.endswith(".wav"):
                        file_path = os.path.join(ram_dir, filename)
                        try:
                            mtime = os.path.getmtime(file_path)
                            if now - mtime > MAX_AUDIO_RETENTION_SECONDS:
                                job_id = filename[:-4]
                                ephemeral_storage.shred_recording(job_id)
                        except Exception:
                            pass
        except Exception:
            pass

        await asyncio.sleep(60)

