# Google Play Data Safety Declaration

**Product:** Vani Voicemail  
**Developer:** Danish K ([https://danishk.web.app](https://danishk.web.app))

## Overview
Vani Voicemail is engineered to exceed Google Play's strictest privacy and data safety standards. We believe in minimal data footprint and zero unnecessary access.

## Data Collected & Shared Table

| Data Type | Collected? | Shared with 3rd Parties? | Storage Location | Retention |
| :--- | :--- | :--- | :--- | :--- |
| **Voice Recordings** | Yes (on user decline/miss) | **NO** | Local Mobile Storage | User-chosen (30-90 days / Forever) |
| **Audio Transcripts** | Yes (generated on-device) | **NO** | Local SQLite Database | User-chosen (30-90 days / Forever) |
| **Phone Numbers** | Yes (caller ID) | **NO** | Local SQLite Database | Local only |
| **Contacts** | Read-only (name matching) | **NO** | Never leaves Android Contacts | N/A |
| **Location** | **NO** | **NO** | Not accessed | N/A |
| **Financial Info** | **NO** | **NO** | Not accessed | N/A |
| **Crash & Diagnostic Logs** | Locally buffered | **NO** (User-consented export only) | In-Memory (Max 500 entries) | Redacted & cleared on user tap |

## Security Practices
- **Data in Transit:** TLS 1.3 encryption is enforced during temporary gateway fetch.
- **Data in Rest:** Local app-sandboxed storage (`/data/data/com.dalsc.voicemail_assistant/`).
- **Data Deletion:** 1-tap complete local database wipe available in Settings.

