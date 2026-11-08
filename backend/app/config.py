from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Indian Visual Voicemail Backend"
    ENVIRONMENT: str = "production"
    
    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgrespassword@localhost:5432/voicemail_db"
    
    # Webhook Security
    WEBHOOK_HMAC_SECRET: str = "change_me_to_a_secure_random_key_hex_32"
    
    # Telephony
    SYSTEM_FORWARDING_DID: str = "+918040000000"
    
    # Storage (S3 / Supabase Storage / Local)
    STORAGE_TYPE: str = "supabase"
    SUPABASE_URL: str = "https://your-project.supabase.co"
    SUPABASE_SERVICE_ROLE_KEY: str = "your-supabase-service-role-key"
    SUPABASE_BUCKET_NAME: str = "voicemail-recordings"
    
    # S3 Fallback Configuration
    AWS_ACCESS_KEY_ID: str = ""
    AWS_SECRET_ACCESS_KEY: str = ""
    AWS_REGION: str = "ap-south-1"
    AWS_S3_BUCKET: str = "voicemail-recordings"
    
    # Firebase Admin SDK
    FIREBASE_CREDENTIALS_PATH: str = "/etc/voicemail/firebase-service-account.json"
    
    # Transcription Configuration
    WHISPER_MODEL_SIZE: str = "small"
    WHISPER_DEVICE: str = "cpu"
    WHISPER_COMPUTE_TYPE: str = "int8"
    
    class Config:
        env_file = ".env"
        extra = "allow"

settings = Settings()

