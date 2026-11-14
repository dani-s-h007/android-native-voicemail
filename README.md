# Call Assistant & Visual Voicemail

> **Enterprise-grade Visual Voicemail & Intelligent Call Assistant for Android**  
> Engineered by **Danish K** ([https://danishk.web.app](https://danishk.web.app))  
> Designed to Google's Material 3 Standards (Google Phone, Google Messages, Google Keep).

[![CI/CD Pipeline](https://github.com/dalsc-dev/android-native-voicemail/actions/workflows/ci.yml/badge.svg)](https://github.com/dalsc-dev/android-native-voicemail/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zero Cloud Storage](https://img.shields.io/badge/Privacy-100%25%20On--Device-success.svg)](docs/ARCHITECTURE.md#5-security-privacy--local-data-sovereignty)
[![Material 3 Design](https://img.shields.io/badge/Design-Material%203%20Dynamic-purple.svg)](lib/design_system/)
[![Developer: Danish K](https://img.shields.io/badge/Developer-Danish%20K-orange.svg)](https://danishk.web.app)

---

## 🌟 Overview & Key Principles

**Call Assistant** is a universal, general-purpose on-device call assistant and visual voicemail platform for Android. It is not locked to any single carrier, country, or brand. Everything is user-configurable: phone numbers, carrier forwarding codes, greeting templates, languages, and emergency response rules.

### Core Architecture Highlights

1. **100% On-Device & Privacy-First**:
   - Zero mandatory cloud dependencies.
   - All voice recordings, metadata, and transcripts are stored exclusively in a sandboxed local SQLite database.
   - Rotating diagnostics log with automatic redaction of caller numbers and names.
   - Optional `FLAG_SECURE` screen protection to prevent unauthorized screenshots.

2. **Carrier-Agnostic Telephony Integration**:
   - Universal MMI Supplementary Service codes (`*67*`, `*61*`, `*62*`, `*004*`, `##002#`).
   - Built-in customizable carrier profiles for global and regional carriers.
   - In-app carrier and custom code editor with direct dialing intents and visual dialer guide.
   - Region-locked emergency numbers (e.g. 911, 999, 112) that can never be blocked or forwarded.

3. **Google Material 3 Enterprise Design**:
   - Full Material You dynamic color extraction (`dynamic_color`) with fallback brand palette.
   - Adaptive responsive shell: bottom `NavigationBar` on phones, side `NavigationRail` on foldables and tablets.
   - High-contrast accessibility compliance, large text scaling, and TalkBack semantic labels.
   - Strict 48dp minimum touch targets across all interactive elements.

4. **Multi-Language Speech & Greetings**:
   - Customizable greeting studio with dynamic variables: `{name}`, `{caller}`, `{time_back}`.
   - Built-in multi-language localization (English, Spanish, French, German, Hindi, Malayalam) and ARB translation catalogs.
   - Audio playback engine with speed control (0.5x – 2.0x), scrub seek, and interactive transcript word tracking.

---

## 📱 Information Architecture & Tabs

The application features an adaptive 4-tab navigation shell:

| Tab | Screen | Key Capabilities |
|:---|:---|:---|
| **Voicemail** | `VoicemailInboxScreen` | Visual inbox grouped by *Today*, *Yesterday*, and *Earlier*. Swipe-to-delete, mark as read, multi-selection batch actions, search filter across names, numbers, and transcripts. |
| **Modes** | `CallModesScreen` | 4 call-handling modes (*Server Assistant*, *Auto-Messaging*, *Auto-Answer*, *Silent DND*), quick silence timer, schedule rules, and emergency bypass protections. |
| **Greetings** | `GreetingsScreen` | Greeting templates (Meeting, Driving, Sleeping, Traveling, Custom) without hardcoded text, dynamic variable insertion, TTS preview, and contact-group assignment. |
| **Settings** | `SettingsScreen` | Account profile, Region & Carrier editor, appearance/theme picker, retention auto-purge rules, and local JSON backup/restore. |

### Additional Screens:
- **Setup Wizard & Onboarding**: 3-page introduction, explicit consent notice, per-permission rationale screens, carrier setup, and simulated test call verification.
- **Voicemail Detail**: Audio scrubber, play/pause, 10s skip, speed adjustment, synchronized transcript, copy/export, call-back, and contact actions.
- **Reliability Check**: Real-time checklist auditing phone permissions, battery optimization, and telephony forwarding states with direct "Fix" actions.
- **Call Diagnostics**: Detailed decision audit trail explaining call-routing outcomes with exportable redacted logs.
- **Legal Hub**: Built-in generic Markdown drafts for 7 compliance documents with dynamic placeholder replacement (`{{APP_NAME}}`, `{{COMPANY_NAME}}`, `{{EFFECTIVE_DATE}}`).
- **About Hub**: Version manifest, developer attribution, website launcher, open-source licenses, and update verification.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: Flutter 3.24+ (Dart 3 with pattern matching and sealed classes)
- **Architecture**: Clean Architecture & Feature-First modularity
- **State Management**: `flutter_riverpod` (v2.6+)
- **Routing**: `go_router` (v14+) with declarative guarded navigation
- **Theming**: `dynamic_color` with Material 3 design tokens
- **Local Storage**: `sqflite` (SQLite) with encrypted preferences (`flutter_secure_storage`)
- **Audio & Media**: `just_audio`, `audio_session`, `record`, and `flutter_tts`
- **Testing**: Unit tests, Widget tests, Component Gallery golden tests, and Integration E2E tests

For an in-depth breakdown of layer separation and design patterns, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.24.0`)
- Android Studio / VS Code with Flutter extension
- Android SDK with platform API 34+

### Installation & Execution

```bash
# 1. Clone the repository
git clone https://github.com/dalsc-dev/android-native-voicemail.git
cd android-native-voicemail

# 2. Fetch dependencies
flutter pub get

# 3. Run static code analysis
flutter analyze

# 4. Run the full test suite
flutter test

# 5. Run the application in development mode (with offline mocks)
flutter run --flavor dev -t lib/main.dart
```

---

## 🧪 Testing Strategy

The project maintains comprehensive test coverage across all features:

```bash
# Run all unit and widget tests
flutter test

# Run configuration validation tests
flutter test test/core/config_validator_test.dart

# Run design system component tests
flutter test test/design_system/components_test.dart

# Run integration test flow
flutter test integration_test/app_flow_test.dart
```

---

## ⚙️ Configuration & Production Checklist

All configuration values and branding reside in a single file: `lib/app/config/app_config.dart` (mirrored in `assets/config/app_config.json`).

Before building a production release (`prod` flavor), ensure all production placeholders are resolved. The build validator will automatically halt compilation if any `TODO_UPDATE` values remain:

```bash
# Run production configuration check
dart run lib/app/config/config_validator.dart prod
```

See [docs/UPDATE_CHECKLIST.md](docs/UPDATE_CHECKLIST.md) for the complete checklist.

---

## 👨‍💻 Author & Creator

Engineered by **Danish K**:
- **Portfolio & Applications**: [https://danishk.web.app](https://danishk.web.app)
- **Support**: `support@danishk.web.app`

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
