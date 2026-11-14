# Google Play Data Safety Disclosure

> **LEGAL NOTICE & DRAFT TEMPLATE**: This disclosure document outlines data safety practices for {{APP_NAME}} in accordance with Google Play Developer policies.

**Product:** {{APP_NAME}}  
**Company:** {{COMPANY_NAME}}  
**Developer:** {{DEVELOPER_NAME}}  
**Contact:** {{SUPPORT_EMAIL}}  

---

## Overview
{{APP_NAME}} is architected to minimize data collection and maintain complete local user privacy. All core voicemail functions operate entirely on-device.

## Data Collection & Sharing Matrix

| Data Type | Collected? | Shared with Third Parties? | Storage Location | Retention Policy |
| :--- | :--- | :--- | :--- | :--- |
| **Voice Recordings** | Yes (on missed/screened call) | **NO** | Sandboxed Local Storage | User configurable (30/60/90 days / Forever) |
| **Speech Transcripts** | Yes (generated on-device) | **NO** | Sandboxed Local SQLite | User configurable (30/60/90 days / Forever) |
| **Phone Numbers** | Yes (incoming caller ID) | **NO** | Sandboxed Local SQLite | Local only |
| **Contacts** | Read-only (display name matching) | **NO** | Never leaves device contacts | Read on demand |
| **Location Data** | **NO** | **NO** | Not collected | N/A |
| **Financial / Payment Info** | **NO** | **NO** | Not collected | N/A |
| **Diagnostics & Error Logs** | Optional (user consent only) | **NO** (User-initiated export only) | Memory / Sandboxed SQLite | Redacted & cleared on demand |

## Security Architecture
- **Encryption in Transit:** All network requests use TLS 1.3 encryption.
- **Local Isolation:** SQLite database and audio files reside in private Android application sandboxed directory.
- **User Deletion Rights:** 1-tap complete local database wipe is accessible in Settings at any time.
