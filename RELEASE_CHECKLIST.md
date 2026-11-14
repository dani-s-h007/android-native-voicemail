# Production Release Checklist: Vani Voicemail 🚀
> **Enterprise-Grade Android Release & Compliance Guide**  
> Developer: **Danish K** | [https://danishk.web.app](https://danishk.web.app) | `support@danishk.web.app`

---

## 📋 1. Android Keystore & Gradle Signing Configuration

### 1.1 Generate Production Release Keystore
Run the following command to generate an industry-standard RSA 4096-bit keystore:
```bash
keytool -genkey -v \
  -keystore android/app/vani_release_key.jks \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000 \
  -alias vani_voicemail
```

### 1.2 Secure `key.properties` Setup
Create `android/key.properties` (ensure this file is in `.gitignore`):
```properties
storePassword=<YOUR_STRONG_STORE_PASSWORD>
keyPassword=<YOUR_STRONG_KEY_PASSWORD>
keyAlias=vani_voicemail
storeFile=vani_release_key.jks
```

### 1.3 Gradle Release Signing & R8/ProGuard
Verify `android/app/build.gradle` contains the release signing block and enables R8 shrinking:
```groovy
android {
    ...
    signingConfigs {
        release {
            def keystorePropertiesFile = rootProject.file("key.properties")
            def keystoreProperties = new Properties()
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
                storeFile = file(keystoreProperties['storeFile'])
                storePassword = keystoreProperties['storePassword']
                keyAlias = keystoreProperties['keyAlias']
                keyPassword = keystoreProperties['keyPassword']
            }
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## 🛡️ 2. Google Play Data Safety Compliance

Based strictly on `assets/legal/data_safety.md` and India's DPDP Act:

| Section | Declaration | Justification / Notes |
| :--- | :--- | :--- |
| **Data Collection** | **NO** | No personal data or voicemails are collected or transmitted to external developer servers. |
| **Data Sharing** | **NO** | Zero third-party telemetry, ad trackers, or cloud analytics SDKs. |
| **On-Device Storage** | **YES** | Audio recordings (`.m4a`/`.wav`) and transcripts are stored exclusively in local SQLite (`vani_voicemail_local.db`). |
| **Encryption in Transit** | **N/A** | No data is sent over the internet. |
| **Encryption at Rest** | **YES** | Android File-Based Encryption (FBE) + SQLCipher local payload encryption. |
| **Data Deletion Mechanism** | **YES** | 1-tap "Wipe All Voicemails" and automated audio retention purge (7, 14, 30, 90 days) in Settings. |

---

## 🔒 3. Google Play Permissions Declarations

Google Play requires explicit declarations for sensitive telephony permissions:

### 3.1 `READ_PHONE_STATE` / `ANSWER_PHONE_CALLS`
- **Core Functionality Declaration**: Visual Voicemail and Call Management Assistant.
- **Why Required**: To detect incoming carrier-forwarded calls and display real-time call handling status.
- **In-App Disclosure**: Displayed in `lib/features/onboarding/presentation/screens/permission_rationale_screen.dart` before triggering the system OS prompt.
- **Video Submission**: Submit a 30-second screen recording showing the setup wizard and incoming call detection.

### 3.2 `POST_NOTIFICATIONS` (Android 13+ / Tiramisu)
- **Rationale**: Immediate high-priority notification for urgent voicemails, caller transcripts, and DND schedule expiry.

### 3.3 `CALL_PHONE` / MMI Supplementary Codes
- **Rationale**: Used exclusively with user consent to launch the native dialer with carrier MMI codes (`*403*` or `*67*`) for forwarding setup.

---

## 🇮🇳 4. Indian Carrier MMI Code & Telephony Verification

Verify call forwarding behavior on target Indian networks:

| Test Item | Jio (VoLTE) | Airtel (VoLTE) | Vi / BSNL |
| :--- | :--- | :--- | :--- |
| **Forward When Busy/Declined** | `*403*+914954268791` | `*67*+914954268791#` | `*67*+914954268791#` |
| **Forward When Unanswered** | `*409*+914954268791` | `*61*+914954268791#` | `*61*+914954268791#` |
| **Phone App GUI Method** | Phone App ➔ Settings ➔ Calling accounts ➔ Call forwarding | Same | Same |
| **Anti-Deactivation Protection** | In-app 1-tap deactivation removed to prevent accidental cancellations. Shortcut opens Phone App Settings directly. | Checked ✅ | Checked ✅ |
| **Pulse Billing Check** | Default greeting <4 seconds (*"Hi, Danish here..."*) guarantees 1 single pulse (~₹0.30/call). | Verified ✅ | Verified ✅ |

---

## 🔋 5. OEM Battery & Background Autostart (Realme / Xiaomi / OnePlus)

Aggressive OEM power management can terminate background sync and notifications.

### User Guidance in App:
1. **Realme UI / ColorOS (OPPO/Realme)**:
   - Go to **Settings ➔ Battery ➔ More settings ➔ App battery management ➔ Vani Voicemail**.
   - Enable **Allow background activity** & **Allow auto-launch**.
2. **MIUI / HyperOS (Xiaomi)**:
   - Go to **Settings ➔ Apps ➔ Manage Apps ➔ Vani Voicemail**.
   - Enable **Autostart** and set **Battery saver** to *No restrictions*.
3. **OnePlus (OxygenOS)**:
   - Go to **Battery ➔ Advanced settings ➔ Optimize battery use ➔ Vani Voicemail ➔ Don't optimize**.

---

## ♿ 6. Accessibility, Localization & UX Audit

- [x] **Touch Targets**: Minimum 48x48 dp across all buttons, chips, and list tiles (`AppListTile`, `AppFilterChip`).
- [x] **TalkBack Accessibility**: All icon-only buttons include descriptive `tooltip` and `Semantics(label: ...)` tags.
- [x] **Material 3 Dynamic Color**: Supports dynamic pastel palettes extracted from user wallpaper via `dynamic_color`.
- [x] **High-Contrast Dark Mode**: Surface tonal containers adhere to WCAG AAA contrast ratios.
- [x] **Multilingual Support**: Six languages verified (`en`, `hi`, `ml`, `ta`, `te`, `kn`).
- [x] **Screen Capture Protection**: Optional `FLAG_SECURE` toggle prevents screenshots of sensitive voicemail transcripts.

---

## 🧪 7. Automated Test & CI Verification Checklist

Execute the complete verification pipeline locally prior to release tag creation:

```bash
# 1. Clean workspace
flutter clean && flutter pub get

# 2. Strict static analysis (zero warnings allowed)
flutter analyze

# 3. Unit, widget, and golden tests
flutter test

# 4. Integration test suite
flutter test integration_test/app_flow_test.dart

# 5. Build release APKs (split per ABI for optimal download size)
flutter build apk --release --split-per-abi

# 6. Build Google Play App Bundle (.aab)
flutter build appbundle --release
```

---

## 📦 8. Final Release Artifacts Check

- [x] Release App Bundle generated: `build/app/outputs/bundle/release/app-release.aab`
- [x] Release APKs generated:
  - `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (~14 MB)
  - `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (~13 MB)
- [x] Legal hub links verified on [https://danishk.web.app](https://danishk.web.app):
  - Privacy Policy: `https://danishk.web.app/privacy`
  - Terms of Service: `https://danishk.web.app/terms`
  - Data Safety: `https://danishk.web.app/datasafety`
- [x] Support email active: `support@danishk.web.app`
- [x] Grievance Officer designated per India IT Rules 2021: **Danish K** (`grievance@danishk.web.app`)

