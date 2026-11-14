#!/usr/bin/env python3
"""
File: telephony/dispatch_webhook.py
Description: Sends webhook to Node.js/FastAPI backend upon voicemail completion.
"""

import os
import sys
import json
import time
import hmac
import hashlib
import argparse
import urllib.request
import urllib.error

WEBHOOK_URL = os.getenv("BACKEND_WEBHOOK_URL", "http://127.0.0.1:8000/api/v1/internal/telephony/webhook")
WEBHOOK_SECRET = os.getenv("WEBHOOK_HMAC_SECRET", "change_me_to_a_secure_random_key_hex_32")

def parse_args():
    parser = argparse.ArgumentParser(description="Dispatch voicemail webhook")
    parser.add_argument("--session", required=True, help="Call Session / Asterisk UniqueID")
    parser.add_argument("--user", required=True, help="Diverted user phone number (E.164)")
    parser.add_argument("--caller", required=True, help="Caller phone number (E.164)")
    parser.add_argument("--filepath", required=True, help="Absolute path to recorded .wav file")
    parser.add_argument("--duration", type=int, default=0, help="Duration in seconds")
    parser.add_argument("--reason", default="unknown", help="Forwarding reason")
    return parser.parse_args()

def generate_hmac_signature(secret: str, payload_bytes: bytes) -> str:
    return hmac.new(secret.encode("utf-8"), payload_bytes, hashlib.sha256).hexdigest()

def dispatch(args):
    if not os.path.exists(args.filepath) or os.path.getsize(args.filepath) < 1024:
        sys.stderr.write(f"[WARN] Audio file {args.filepath} is missing or empty. Skipping webhook.\n")
        sys.exit(0)

    payload = {
        "callSessionId": args.session,
        "divertedUser": args.user,
        "callerNumber": args.caller,
        "audioLocalPath": args.filepath,
        "durationSeconds": args.duration,
        "forwardReason": args.reason or "unknown",
        "timestamp": int(time.time())
    }

    payload_json = json.dumps(payload, separators=(',', ':'))
    payload_bytes = payload_json.encode('utf-8')
    signature = generate_hmac_signature(WEBHOOK_SECRET, payload_bytes)

    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Asterisk-Telephony-Webhook/1.0",
        "X-Asterisk-Signature": signature
    }

    req = urllib.request.Request(WEBHOOK_URL, data=payload_bytes, headers=headers, method="POST")

    for attempt in range(1, 4):
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                if 200 <= resp.status < 300:
                    sys.stdout.write(f"[INFO] Webhook delivered successfully for session {args.session}\n")
                    return
        except urllib.error.HTTPError as e:
            sys.stderr.write(f"[ERROR] Webhook HTTP Error {e.code}: {e.read().decode('utf-8')}\n")
            if e.code < 500:
                break
        except Exception as e:
            sys.stderr.write(f"[WARN] Attempt {attempt} failed to deliver webhook: {str(e)}\n")
        
        time.sleep(2 ** attempt)

    sys.stderr.write(f"[FATAL] Failed to deliver webhook after 3 attempts for {args.session}\n")

if __name__ == "__main__":
    args = parse_args()
    dispatch(args)

