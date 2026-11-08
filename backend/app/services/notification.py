import os
import firebase_admin
from firebase_admin import credentials, messaging
from typing import List, Dict, Any
from app.config import settings

class NotificationService:
    def __init__(self):
        if not firebase_admin._apps:
            if os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
                cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
                firebase_admin.initialize_app(cred)
                print("[INFO] Firebase Admin initialized with service account.")
            else:
                try:
                    firebase_admin.initialize_app()
                    print("[INFO] Firebase initialized with default application credentials.")
                except Exception as e:
                    print(f"[WARN] Firebase Admin not yet configured: {e}")

    def send_voicemail_push(
        self,
        fcm_tokens: List[str],
        voicemail_id: str,
        caller_number: str,
        duration_seconds: int,
        transcript_preview: str,
        detected_language: str
    ):
        if not fcm_tokens:
            return

        title = "New Voicemail"
        body = f"Message from {caller_number} ({duration_seconds}s): {transcript_preview[:80]}..."

        data_payload = {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "type": "NEW_VOICEMAIL",
            "voicemail_id": str(voicemail_id),
            "caller_number": str(caller_number),
            "duration": str(duration_seconds),
            "language": str(detected_language),
            "transcript": str(transcript_preview[:200])
        }

        message = messaging.MulticastMessage(
            tokens=fcm_tokens,
            data=data_payload,
            notification=messaging.Notification(title=title, body=body),
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="voicemail_alerts_channel",
                    sound="default",
                    click_action="FLUTTER_NOTIFICATION_CLICK"
                )
            )
        )

        try:
            response = messaging.send_each_for_multicast(message)
            print(f"[INFO] FCM sent: {response.success_count} success, {response.failure_count} failures.")
        except Exception as e:
            print(f"[ERROR] Failed to send FCM multicast: {e}")

    def send_ephemeral_download_push(
        self,
        fcm_tokens: List[str],
        job_id: str,
        download_url: str,
        caller_number: str,
        duration_seconds: int,
        timestamp: int
    ):
        if not fcm_tokens:
            return

        data_payload = {
            "type": "VOICEMAIL_DOWNLOAD",
            "job_id": str(job_id),
            "download_url": str(download_url),
            "caller_number": str(caller_number),
            "duration": str(duration_seconds),
            "timestamp": str(timestamp)
        }

        # High-priority data-only message ensures instantaneous wake-up in Doze mode
        message = messaging.MulticastMessage(
            tokens=fcm_tokens,
            data=data_payload,
            android=messaging.AndroidConfig(
                priority="high"
            )
        )

        try:
            response = messaging.send_each_for_multicast(message)
            print(f"[INFO] Ephemeral download FCM sent: {response.success_count} success, {response.failure_count} failures.")
        except Exception as e:
            print(f"[ERROR] Failed to send ephemeral FCM multicast: {e}")

notification_service = NotificationService()

