---
title: Voicemail Transient Relay Backend
emoji: 🎙️
colorFrom: purple
colorTo: indigo
sdk: gradio
sdk_version: 4.44.0
app_file: app.py
pinned: false
---

# Indian Visual Voicemail — Transient Relay Backend

Zero-Cloud-Storage Ephemeral Telephony Relay Backend for Indian Telecom Networks, running on Hugging Face Spaces via Gradio + FastAPI.

## Endpoints
- **Swagger Documentation:** `/docs`
- **Health Check:** `/health` or `/api/v1/health`
- **Audio Relay Webhook:** `/api/v1/relay/incoming`
- **DND Custom Greetings:** `/api/v1/dnd/custom-greeting`
