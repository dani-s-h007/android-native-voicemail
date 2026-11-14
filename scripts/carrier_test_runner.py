#!/usr/bin/env python3
"""
File: scripts/carrier_test_runner.py
Description: End-to-end integration and simulation harness for Indian Carrier headers.
"""

import hmac
import hashlib
import json
import time
import urllib.request
import urllib.error

BACKEND_WEBHOOK_URL = "http://localhost:8000/api/v1/internal/telephony/webhook"
WEBHOOK_SECRET = "change_me_to_a_secure_random_key_hex_32"

TEST_CASES = [
    {
        "name": "Airtel 4G/VoLTE - Call Forward No Reply (*61*)",
        "payload": {
            "callSessionId": f"test_airtel_cfnry_{int(time.time())}",
            "divertedUser": "+919811122233",
            "callerNumber": "+919820011222",
            "audioLocalPath": "/tmp/test_sample_hi.wav",
            "durationSeconds": 18,
            "forwardReason": "no-answer",
            "timestamp": int(time.time())
        }
    },
    {
        "name": "Jio VoLTE - Call Forward Busy (*403* or *67*)",
        "payload": {
            "callSessionId": f"test_jio_cfb_{int(time.time())}",
            "divertedUser": "+919899001122",
            "callerNumber": "+919876543210",
            "audioLocalPath": "/tmp/test_sample_en.wav",
            "durationSeconds": 24,
            "forwardReason": "busy",
            "timestamp": int(time.time())
        }
    },
    {
        "name": "Vi - Call Forward Not Reachable (*62*) [Phone Switched Off]",
        "payload": {
            "callSessionId": f"test_vi_cfnrc_{int(time.time())}",
            "divertedUser": "+919845012345",
            "callerNumber": "+919812345678",
            "audioLocalPath": "/tmp/test_sample_ta.wav",
            "durationSeconds": 12,
            "forwardReason": "unreachable",
            "timestamp": int(time.time())
        }
    }
]

def run_tests():
    print("================ RUNNING CARRIER WEBHOOK SIMULATION ================")
    for tc in TEST_CASES:
        payload = tc["payload"]
        raw_bytes = json.dumps(payload, separators=(',', ':')).encode('utf-8')
        signature = hmac.new(WEBHOOK_SECRET.encode('utf-8'), raw_bytes, hashlib.sha256).hexdigest()

        headers = {
            "Content-Type": "application/json",
            "X-Asterisk-Signature": signature
        }

        req = urllib.request.Request(BACKEND_WEBHOOK_URL, data=raw_bytes, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req) as resp:
                status = resp.status
                body = resp.read().decode('utf-8')
                print(f"[PASS] {tc['name']} -> HTTP {status}: {body}")
        except urllib.error.HTTPError as e:
            print(f"[FAIL] {tc['name']} -> HTTP {e.code}: {e.read().decode('utf-8')}")
        except Exception as e:
            print(f"[ERROR] {tc['name']} -> {str(e)}")

if __name__ == "__main__":
    run_tests()

