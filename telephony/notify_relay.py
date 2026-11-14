#!/usr/bin/env python3
"""
File: telephony/notify_relay.py
Description: Asynchronously notifies local FastAPI relay backend of new ephemeral audio.
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

RELAY_WEBHOOK_URL = os.getenv("RELAY_WEBHOOK_URL", "http://127.0.0.1:8000/api/v1/relay/incoming")
RELAY_HMAC_SECRET = os.getenv("RELAY_HMAC_SECRET", "super_secret_relay_key_32_bytes_hex")

def parse_args():
    parser = argparse.ArgumentParser(description="Notify transient relay backend")
    parser.add_argument("--session", "--job", dest="job", required=True, help="Unique Job / Session ID")
    parser.add_argument("--user", required=True, help="Diverted user phone number (E.164)")
    parser.add_argument("--caller", required=True, help="Caller phone number (E.164)")
    parser.add_argument("--filepath", required=True, help="Absolute path to recorded .wav in RAM")
    parser.add_argument("--duration", type=int, default=0, help="Duration in seconds")
    parser.add_argument("--reason", default="unknown", help="Forwarding reason")
    return parser.parse_args()

def generate_hmac_signature(secret: str, payload_bytes: bytes) -> str:
    return hmac.new(secret.encode("utf-8"), payload_bytes, hashlib.sha256).hexdigest()

def dispatch(args):
    if not os.path.exists(args.filepath) or os.path.getsize(args.filepath) < 1024:
        sys.stderr.write(f"[WARN] Audio file {args.filepath} missing or empty. Discarding.\n")
        sys.exit(0)

    payload = {
        "jobId": args.job,
        "divertedUser": args.user,
        "callerNumber": args.caller,
        "ramFilePath": args.filepath,
        "fileSizeBytes": os.path.getsize(args.filepath),
        "durationSeconds": args.duration,
        "forwardReason": args.reason or "unknown",
        "createdAt": int(time.time())
    }

    payload_json = json.dumps(payload, separators=(',', ':'))
    payload_bytes = payload_json.encode('utf-8')
    signature = generate_hmac_signature(RELAY_HMAC_SECRET, payload_bytes)

    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Asterisk-Transient-Relay/1.0",
        "X-Relay-Signature": signature
    }

    req = urllib.request.Request(RELAY_WEBHOOK_URL, data=payload_bytes, headers=headers, method="POST")

    for attempt in range(1, 4):
        try:
            with urllib.request.urlopen(req, timeout=5) as resp:
                if 200 <= resp.status < 300:
                    sys.stdout.write(f"[INFO] Dispatched job {args.job} to relay backend successfully.\n")
                    return
        except urllib.error.HTTPError as e:
            sys.stderr.write(f"[ERROR] Relay HTTP error {e.code}: {e.read().decode('utf-8')}\n")
            if e.code < 500:
                break
        except Exception as e:
            sys.stderr.write(f"[WARN] Attempt {attempt} failed: {str(e)}\n")
        
        time.sleep(1)

    sys.stderr.write(f"[FATAL] Failed to notify relay backend for job {args.job}\n")

if __name__ == "__main__":
    args = parse_args()
    dispatch(args)

