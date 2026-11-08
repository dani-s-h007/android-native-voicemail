import os
import boto3
from botocore.exceptions import ClientError
from supabase import create_client, Client
from app.config import settings

class StorageService:
    def __init__(self):
        self.storage_type = settings.STORAGE_TYPE
        if self.storage_type == "supabase":
            self.supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)
            self.bucket = settings.SUPABASE_BUCKET_NAME
        elif self.storage_type == "s3":
            self.s3 = boto3.client(
                "s3",
                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
                region_name=settings.AWS_REGION
            )
            self.bucket = settings.AWS_S3_BUCKET

    def upload_file(self, local_path: str, destination_path: str) -> str:
        if not os.path.exists(local_path):
            raise FileNotFoundError(f"Local audio file {local_path} not found.")

        with open(local_path, "rb") as f:
            file_bytes = f.read()

        if self.storage_type == "supabase":
            self.supabase.storage.from_(self.bucket).upload(
                path=destination_path,
                file=file_bytes,
                file_options={"content-type": "audio/wav", "upsert": "true"}
            )
            return destination_path
        elif self.storage_type == "s3":
            self.s3.put_object(
                Bucket=self.bucket,
                Key=destination_path,
                Body=file_bytes,
                ContentType="audio/wav"
            )
            return destination_path
        else:
            return local_path

    def get_presigned_url(self, destination_path: str, expires_in: int = 900) -> str:
        if self.storage_type == "supabase":
            res = self.supabase.storage.from_(self.bucket).create_signed_url(
                path=destination_path,
                expires_in=expires_in
            )
            return res.get("signedURL") or res.get("signedUrl")
        elif self.storage_type == "s3":
            return self.s3.generate_presigned_url(
                ClientMethod="get_object",
                Params={"Bucket": self.bucket, "Key": destination_path},
                ExpiresIn=expires_in
            )
        return f"file://{destination_path}"

    def delete_file(self, destination_path: str):
        try:
            if self.storage_type == "supabase":
                self.supabase.storage.from_(self.bucket).remove([destination_path])
            elif self.storage_type == "s3":
                self.s3.delete_object(Bucket=self.bucket, Key=destination_path)
            elif os.path.exists(destination_path):
                os.remove(destination_path)
        except Exception as e:
            print(f"[WARN] Failed to delete storage file {destination_path}: {e}")

storage_service = StorageService()

