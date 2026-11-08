import os
import hmac
import hashlib
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Request, Header, HTTPException, BackgroundTasks, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.config import settings
from app.database import get_db, AsyncSessionLocal
from app.models import User, UserDevice, Voicemail, Transcription
from app.services.storage import storage_service
from app.services.transcription import transcription_engine
from app.services.notification import notification_service

router = APIRouter(prefix="/api/v1/internal/telephony", tags=["Telephony Webhook"])

class AsteriskWebhookPayload(BaseModel):
    callSessionId: str
    divertedUser: str
    callerNumber: str
    audioLocalPath: str
    durationSeconds: int
    forwardReason: str = "unknown"
    timestamp: int

async def process_voicemail_pipeline(
    voicemail_id: str,
    audio_local_path: str,
    storage_dest_path: str,
    user_id: str,
    caller_number: str,
    duration_seconds: int
):
    async with AsyncSessionLocal() as session:
        try:
            # 1. Upload audio to storage
            storage_service.upload_file(audio_local_path, storage_dest_path)
            
            # 2. Run Whisper Transcription
            res = transcription_engine.transcribe(audio_local_path)
            
            # 3. Save Transcription to DB
            tx = Transcription(
                voicemail_id=voicemail_id,
                transcript_text=res["transcript_text"],
                detected_language=res["detected_language"],
                confidence_score=res["confidence_score"],
                model_name=res["model_name"],
                processing_time_ms=res["processing_time_ms"]
            )
            session.add(tx)
            
            # 4. Update Voicemail status
            vm_query = select(Voicemail).where(Voicemail.id == voicemail_id)
            vm_res = await session.execute(vm_query)
            vm = vm_res.scalars().first()
            if vm:
                vm.status = "ready"
            
            await session.commit()

            # 5. Fetch FCM tokens
            dev_query = select(UserDevice.fcm_token).where(
                UserDevice.user_id == user_id,
                UserDevice.is_active.is_(True)
            )
            dev_res = await session.execute(dev_query)
            fcm_tokens = dev_res.scalars().all()

            # 6. Push Notification
            if fcm_tokens:
                notification_service.send_voicemail_push(
                    fcm_tokens=fcm_tokens,
                    voicemail_id=str(voicemail_id),
                    caller_number=caller_number,
                    duration_seconds=duration_seconds,
                    transcript_preview=res["transcript_text"],
                    detected_language=res["detected_language"]
                )

        except Exception as e:
            print(f"[ERROR] Voicemail processing pipeline failed: {e}")
            await session.rollback()
        finally:
            if os.path.exists(audio_local_path):
                try:
                    os.remove(audio_local_path)
                except Exception:
                    pass

@router.post("/webhook")
async def handle_asterisk_webhook(
    request: Request,
    background_tasks: BackgroundTasks,
    x_asterisk_signature: str = Header(..., alias="X-Asterisk-Signature"),
    db: AsyncSession = Depends(get_db)
):
    raw_body = await request.body()
    
    # Verify HMAC
    expected_sig = hmac.new(
        settings.WEBHOOK_HMAC_SECRET.encode("utf-8"),
        raw_body,
        hashlib.sha256
    ).hexdigest()

    if not hmac.compare_digest(expected_sig, x_asterisk_signature):
        raise HTTPException(status_code=401, detail="Invalid HMAC signature")

    data = await request.json()
    payload = AsteriskWebhookPayload(**data)

    user_query = select(User).where(User.phone_number == payload.divertedUser, User.deleted_at.is_(None))
    user_result = await db.execute(user_query)
    user = user_result.scalars().first()

    if not user:
        raise HTTPException(status_code=404, detail=f"Diverted user {payload.divertedUser} not registered.")

    existing_vm_query = select(Voicemail).where(Voicemail.call_session_id == payload.callSessionId)
    existing_vm_res = await db.execute(existing_vm_query)
    if existing_vm_res.scalars().first():
        return {"status": "ALREADY_PROCESSED"}

    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(days=user.data_retention_days)
    storage_path = f"voicemails/{user.id}/{payload.callSessionId}.wav"
    file_size = os.path.getsize(payload.audioLocalPath) if os.path.exists(payload.audioLocalPath) else 0

    voicemail = Voicemail(
        user_id=user.id,
        caller_number=payload.callerNumber,
        call_session_id=payload.callSessionId,
        audio_path=storage_path,
        audio_duration_seconds=payload.durationSeconds,
        audio_file_size_bytes=file_size,
        status="transcribing",
        forward_reason=payload.forwardReason,
        created_at=now,
        expires_at=expires_at
    )
    db.add(voicemail)
    await db.commit()
    await db.refresh(voicemail)

    background_tasks.add_task(
        process_voicemail_pipeline,
        voicemail_id=voicemail.id,
        audio_local_path=payload.audioLocalPath,
        storage_dest_path=storage_path,
        user_id=user.id,
        caller_number=payload.callerNumber,
        duration_seconds=payload.durationSeconds
    )

    return {"status": "ACCEPTED", "voicemailId": str(voicemail.id)}

