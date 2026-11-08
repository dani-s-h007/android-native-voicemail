import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from app.database import get_db
from app.models import User, Voicemail, Transcription
from app.dependencies import get_current_user
from app.services.storage import storage_service

router = APIRouter(prefix="/api/v1/voicemails", tags=["Voicemails"])

class UpdateVoicemailRequest(BaseModel):
    isRead: bool | None = None
    isStarred: bool | None = None

@router.get("")
async def list_voicemails(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    offset = (page - 1) * limit

    query = (
        select(Voicemail)
        .options(selectinload(Voicemail.transcription))
        .where(Voicemail.user_id == user.id, Voicemail.deleted_at.is_(None))
        .order_by(Voicemail.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    result = await db.execute(query)
    voicemails = result.scalars().all()

    items = []
    for vm in voicemails:
        items.append({
            "id": str(vm.id),
            "callerNumber": vm.caller_number,
            "audioDurationSeconds": vm.audio_duration_seconds,
            "status": vm.status,
            "isRead": vm.is_read,
            "isStarred": vm.is_starred,
            "forwardReason": vm.forward_reason,
            "createdAt": vm.created_at.isoformat(),
            "transcript": {
                "text": vm.transcription.transcript_text,
                "detectedLanguage": vm.transcription.detected_language,
                "confidence": float(vm.transcription.confidence_score) if vm.transcription.confidence_score else None
            } if vm.transcription else None
        })

    return {"items": items, "page": page, "limit": limit}

@router.get("/{id}/audio")
async def get_voicemail_audio_url(
    id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(Voicemail).where(
        Voicemail.id == id,
        Voicemail.user_id == user.id,
        Voicemail.deleted_at.is_(None)
    )
    result = await db.execute(query)
    vm = result.scalars().first()

    if not vm:
        raise HTTPException(status_code=404, detail="Voicemail not found")

    url = storage_service.get_presigned_url(vm.audio_path, expires_in=900)
    return {"audioUrl": url, "expiresInSeconds": 900}

@router.patch("/{id}")
async def update_voicemail(
    id: uuid.UUID,
    body: UpdateVoicemailRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(Voicemail).where(
        Voicemail.id == id,
        Voicemail.user_id == user.id,
        Voicemail.deleted_at.is_(None)
    )
    result = await db.execute(query)
    vm = result.scalars().first()

    if not vm:
        raise HTTPException(status_code=404, detail="Voicemail not found")

    if body.isRead is not None:
        vm.is_read = body.isRead
    if body.isStarred is not None:
        vm.is_starred = body.isStarred

    await db.commit()
    return {"status": "SUCCESS"}

@router.delete("/{id}", status_code=204)
async def delete_voicemail(
    id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(Voicemail).where(
        Voicemail.id == id,
        Voicemail.user_id == user.id,
        Voicemail.deleted_at.is_(None)
    )
    result = await db.execute(query)
    vm = result.scalars().first()

    if not vm:
        raise HTTPException(status_code=404, detail="Voicemail not found")

    vm.deleted_at = datetime.now(timezone.utc)
    storage_service.delete_file(vm.audio_path)

    await db.commit()
    return None

