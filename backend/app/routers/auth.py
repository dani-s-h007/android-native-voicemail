from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Security
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from firebase_admin import auth
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from app.database import get_db
from app.models import User, UserDevice
from app.config import settings

router = APIRouter(prefix="/api/v1", tags=["Authentication & User"])
security = HTTPBearer()

class SyncUserRequest(BaseModel):
    carrier: str = "other"

class DeviceRegisterRequest(BaseModel):
    fcmToken: str
    deviceModel: str = "Android"
    osVersion: str = ""
    appVersion: str = "1.0.0"

@router.post("/auth/sync")
async def sync_user_profile(
    body: SyncUserRequest,
    cred: HTTPAuthorizationCredentials = Security(security),
    db: AsyncSession = Depends(get_db)
):
    try:
        decoded_token = auth.verify_id_token(cred.credentials)
        firebase_uid = decoded_token["uid"]
        phone_number = decoded_token.get("phone_number")
        if not phone_number:
            raise HTTPException(status_code=400, detail="Token must contain verified phone_number")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Token verification failed: {str(e)}")

    query = select(User).where(User.firebase_uid == firebase_uid)
    result = await db.execute(query)
    user = result.scalars().first()

    if not user:
        user = User(
            phone_number=phone_number,
            firebase_uid=firebase_uid,
            carrier=body.carrier,
            forwarding_status="unverified"
        )
        db.add(user)
    else:
        user.carrier = body.carrier
        user.deleted_at = None

    await db.commit()
    await db.refresh(user)

    return {
        "userId": str(user.id),
        "phoneNumber": user.phone_number,
        "carrier": user.carrier,
        "systemForwardingNumber": settings.SYSTEM_FORWARDING_DID,
        "forwardingStatus": user.forwarding_status
    }

@router.post("/users/device")
async def register_device(
    body: DeviceRegisterRequest,
    cred: HTTPAuthorizationCredentials = Security(security),
    db: AsyncSession = Depends(get_db)
):
    decoded_token = auth.verify_id_token(cred.credentials)
    uid = decoded_token["uid"]

    user_res = await db.execute(select(User).where(User.firebase_uid == uid))
    user = user_res.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    dev_query = select(UserDevice).where(
        UserDevice.user_id == user.id,
        UserDevice.fcm_token == body.fcmToken
    )
    dev_res = await db.execute(dev_query)
    device = dev_res.scalars().first()

    if not device:
        device = UserDevice(
            user_id=user.id,
            fcm_token=body.fcmToken,
            device_model=body.deviceModel,
            os_version=body.osVersion,
            app_version=body.appVersion,
            is_active=True
        )
        db.add(device)
    else:
        device.is_active = True
        device.device_model = body.deviceModel

    await db.commit()
    return {"status": "SUCCESS"}

