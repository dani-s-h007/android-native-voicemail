import os
import hmac
import hashlib
from fastapi import APIRouter, Request, Header, HTTPException, BackgroundTasks, Depends
from fastapi.responses import FileResponse
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.config import settings
from app.database import get_db
from app.models import User, UserDevice
from app.services.ephemeral_storage import ephemeral_storage
from app.services.notification import notification_service

router = APIRouter(tags=["Transient Voicemail Relay"])

class AsteriskRelayPayload(BaseModel):
    jobId: str
    divertedUser: str
    callerNumber: str
    ramFilePath: str
    fileSizeBytes: int
    durationSeconds: int
    forwardReason: str = "unknown"
    createdAt: int

def verify_asterisk_signature(secret: str, raw_body: bytes, provided_sig: str) -> bool:
    expected_sig = hmac.new(secret.encode("utf-8"), raw_body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected_sig, provided_sig)

@router.post("/api/v1/relay/incoming")
async def handle_incoming_voicemail(
    request: Request,
    background_tasks: BackgroundTasks,
    x_relay_signature: str = Header(..., alias="X-Relay-Signature"),
    db: AsyncSession = Depends(get_db)
):
    raw_body = await request.body()
    relay_secret = os.getenv("RELAY_HMAC_SECRET", "super_secret_relay_key_32_bytes_hex")

    if not verify_asterisk_signature(relay_secret, raw_body, x_relay_signature):
        raise HTTPException(status_code=403, detail="Invalid HMAC signature")

    payload = AsteriskRelayPayload.model_validate_json(raw_body)

    # 1. Verify file exists in RAM disk
    if not ephemeral_storage.file_exists(payload.jobId):
        raise HTTPException(status_code=404, detail="Audio file not found in ephemeral storage")

    # 2. Look up recipient user and active FCM tokens
    user_query = select(User).where(User.phone_number == payload.divertedUser)
    user_res = await db.execute(user_query)
    user = user_res.scalars().first()

    if not user:
        # Failsafe: shred file if user is not registered on this relay
        ephemeral_storage.shred_recording(payload.jobId)
        return {"status": "DROPPED", "reason": "User not registered"}

    device_query = select(UserDevice.fcm_token).where(
        UserDevice.user_id == user.id,
        UserDevice.is_active.is_(True)
    )
    device_res = await db.execute(device_query)
    fcm_tokens = device_res.scalars().all()

    # 3. Generate 15-minute one-time signed download token
    token = ephemeral_storage.generate_signed_download_token(payload.jobId, ttl_seconds=900)
    base_url = settings.BASE_URL.rstrip("/")
    download_url = f"{base_url}/api/v1/voicemails/download/{token}"

    # 4. Dispatch High-Priority FCM data message to recipient device
    if fcm_tokens:
        background_tasks.add_task(
            notification_service.send_ephemeral_download_push,
            fcm_tokens=fcm_tokens,
            job_id=payload.jobId,
            download_url=download_url,
            caller_number=payload.callerNumber,
            duration_seconds=payload.durationSeconds,
            timestamp=payload.createdAt
        )

    return {"status": "DISPATCHED", "jobId": payload.jobId}

@router.get("/api/v1/voicemails/download/{token}")
async def download_transient_voicemail(token: str):
    job_id = ephemeral_storage.validate_and_consume_token(token)
    if not job_id:
        raise HTTPException(status_code=403, detail="Download token invalid, expired, or already used")

    file_path = ephemeral_storage.get_file_path(job_id)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Voicemail file has been deleted or expired")

    return FileResponse(
        path=file_path,
        media_type="audio/wav",
        filename=f"voicemail_{job_id}.wav",
        headers={"Cache-Control": "no-store, no-cache, must-revalidate, max-age=0"}
    )

@router.post("/api/v1/voicemails/{job_id}/ack")
async def acknowledge_voicemail_download(job_id: str):
    """
    Called by the Flutter app as soon as audio is saved in app-private storage.
    Permanently shreds the audio file from the relay server's RAM disk.
    """
    shredded = ephemeral_storage.shred_recording(job_id)
    return {"status": "SHREDDED", "jobId": job_id, "success": shredded}

