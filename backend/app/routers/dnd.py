from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from app.services.dnd_manager import dnd_manager

router = APIRouter(prefix="/api/v1/dnd", tags=["DND Sessions"])

@router.post("/session")
async def create_or_update_dnd_session(
    phone_number: str = Form(...),
    expires_at: int = Form(...),
    mode: str = Form("meeting"),
    greeting_audio: UploadFile = File(...)
):
    audio_bytes = await greeting_audio.read()
    try:
        success = dnd_manager.activate_dnd_session(
            phone_number=phone_number,
            expires_at=expires_at,
            mode=mode,
            greeting_bytes=audio_bytes
        )
        return {
            "status": "ACTIVE",
            "phoneNumber": phone_number,
            "expiresAt": expires_at,
            "mode": mode
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to activate DND session: {e}")

@router.delete("/session/{phone_number}")
async def end_dnd_session(phone_number: str):
    dnd_manager.deactivate_dnd_session(phone_number)
    return {"status": "DEACTIVATED", "phoneNumber": phone_number}

@router.get("/status/{phone_number}")
async def get_dnd_status(phone_number: str):
    return dnd_manager.get_dnd_status(phone_number)

