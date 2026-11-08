import hmac
import hashlib
from fastapi import Header, HTTPException, Depends, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.config import settings
from app.database import get_db
from app.models import User

security = HTTPBearer()

def verify_webhook_hmac(
    x_asterisk_signature: str = Header(..., alias="X-Asterisk-Signature")
):
    if not x_asterisk_signature:
        raise HTTPException(status_code=401, detail="Missing X-Asterisk-Signature header")
    return x_asterisk_signature

async def get_current_user(
    cred: HTTPAuthorizationCredentials = Security(security),
    db: AsyncSession = Depends(get_db)
) -> User:
    token = cred.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        firebase_uid = decoded_token["uid"]
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid or expired authentication token: {str(e)}")

    query = select(User).where(User.firebase_uid == firebase_uid, User.deleted_at.is_(None))
    result = await db.execute(query)
    user = result.scalars().first()

    if not user:
        raise HTTPException(status_code=404, detail="User account not registered or active.")

    return user

