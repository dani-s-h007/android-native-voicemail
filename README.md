# Vani Voicemail 📞
> **Enterprise-grade Visual Voicemail & Call Assistant for Android in India**  
> Designed to Google's Material 3 Standards (Google Phone, Google Keep, Google Messages).

[![Flutter CI/CD Pipeline](https://github.com/dalsc2/voicemail/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/dalsc2/voicemail/actions)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-blue.svg)](https://danishk.web.app)
[![Zero Cloud Storage](https://img.shields.io/badge/Privacy-100%25%20On--Device-success.svg)](https://danishk.web.app/privacy)
[![Developer: Danish K](https://img.shields.io/badge/Developer-Danish%20K-orange.svg)](https://danishk.web.app)

---

## 🌟 Overview & Key Principles

**Vani Voicemail** is an on-device intelligent call assistant and visual voicemail platform engineered specifically for Android users in India.

### Core Architecture Highlights:
1. **Zero Permanent Cloud Storage**: All voice recordings, audio files, and transcripts are encrypted and stored exclusively in a sandboxed local SQLite database on your device (`vani_voicemail_local.db`).
2. **Indian Cellular Telephony Integration**: Seamlessly integrates with **Jio, Airtel, Vodafone Idea (Vi), and BSNL** using native VoLTE Supplementary Services (`*403*` / `*67*`).
3. **Optimized Pulse Billing**: Ultra-short automated greetings (under 4 seconds) guarantee minimal 1-pulse carrier charges (~₹0.30/call).
4. **Google Material 3 Design System**: Full Material You dynamic color theming, adaptive navigation (bottom bar on phones, navigation rail on foldables/tablets), high-contrast accessibility, and 48dp minimum touch targets.

---

## 📱 Information Architecture & Tabs

The app features a 4-tab adaptive navigation shell:

| Tab | Icon | Description |
| :--- | :--- | :--- |
| **Voicemail** | `Icons.voicemail_rounded` | Visual inbox grouped by *Today*, *Yesterday*, and *Earlier*. Swipe-to-delete, swipe-to-read, multi-select, and text search across caller name, number, and transcripts. |
| **Modes** | `Icons.tune_rounded` | 4 call-handling modes (*Server Greeting*, *Auto-Decline*, *Auto-Answer*, *Silent DND*), quick silence timer, college routine scheduling, and locked emergency services (112, 100). |
| **Greetings** | `Icons.record_voice_over` | Multilingual greeting studio with dynamic variables (`{name}`, `{caller}`, `{time_back}`), TTS voice preview, and per-contact-group assignment. |
| **Settings** | `Icons.settings_rounded` | Theme customization, 1-tap phone app settings shortcut, data retention auto-purge, screen-capture protection, and local export. |

---

## 🇮🇳 Indian Carrier Telephony Configuration

Vani Voicemail routes declined or unattended calls to your dedicated virtual number:
- **Default Kerala DID:** `+914954268791` (`049-542-68791`)
- **Forwarding Rule:** When Busy / Declined / Unanswered

### Network Activation Matrix:

| Carrier | Dial Code to Activate | Phone App GUI Method |
| :--- | :--- | :--- |
| **Jio** | `*403*+914954268791` | **Phone App ➔ 3 dots ➔ Settings ➔ Calling accounts ➔ Call forwarding ➔ When busy / When unanswered** |
| **Airtel** | `*67*+914954268791#` | **Phone App ➔ 3 dots ➔ Settings ➔ Calling accounts ➔ Call forwarding ➔ When busy / When unanswered** |
| **Vi / BSNL** | `*67*+914954268791#` | **Phone App ➔ 3 dots ➔ Settings ➔ Calling accounts ➔ Call forwarding ➔ When busy / When unanswered** |

> **🛡️ Anti-Deactivation Protection:** In-app deactivation has been completely removed to prevent accidental cancellation of carrier forwarding. Users maintain full control through Android's native Phone Settings.

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: Flutter 3.24+ (Dart 3 with sealed classes & pattern matching)
- **State Management**: `flutter_riverpod: ^2.5.1`
- **Navigation**: `go_router: ^14.2.0` (guarded routes & deep links)
- **Theming**: `dynamic_color: ^1.7.0` (Material You)
- **Audio Engine**: `just_audio: ^0.9.36` & `audio_session: ^0.1.18`
- **Database**: `sqflite: ^2.3.0` & `flutter_secure_storage: ^9.0.0`
- **TTS**: `flutter_tts: ^4.2.2`

---

## 🚀 Getting Started

### Prerequisites:
- Flutter SDK `>=3.0.0 <4.0.0`
- Android Studio / VS Code
- Android 14+ test device (or emulator)

### Installation:
```bash
# Clone the repository
git clone https://github.com/dalsc2/voicemail.git
cd voicemail

# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Execute test suite
flutter test

# Run on connected Android device
flutter run
```

---

## 👨‍💻 Creator & Portfolio

Designed and developed by **Danish K**:
- **Portfolio & Apps**: [https://danishk.web.app](https://danishk.web.app)
- **Support & Inquiries**: `support@danishk.web.app`
- **Location**: Kozhikode, Kerala, India

---

## 📄 License & Compliance

© 2026 Danish K. All rights reserved.  
Complies with the **Indian Information Technology Act (2000)**, **TRAI Telecommunications Directives**, and the **Digital Personal Data Protection Act (2023)**.
