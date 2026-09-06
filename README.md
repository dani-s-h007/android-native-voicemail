# Android Native Voicemail

An automated on-device Voicemail and Call Screener application built with Flutter and native Kotlin. This app leverages Android's native `CallScreeningService` to intercept incoming calls when you are busy, automatically handle them without interrupting you, and dispatch a custom SMS auto-reply.

## Features

- **Method 1: Silent Reject & SMS**
  Silently intercepts and rejects incoming calls before your phone even rings, instantly dispatching an automated SMS reply to the caller.
  
- **Method 2: Auto-Answer & TTS**
  Automatically answers the call, turns on the speakerphone, reads your custom away message out loud using Text-to-Speech (TTS), and hangs up.

- **Important Contacts Bypass**
  Add specific contacts (like parents or emergencies) to a whitelist. These calls will bypass Class Mode entirely and ring your phone normally.

- **Auto-Scheduling**
  Set automatic on/off schedules (e.g., during your actual class hours) so you never forget to turn it on or off.

- **Premium Widget**
  Features a beautiful "glassmorphism" home screen widget to quickly toggle Class Mode on and off without opening the app.

- **100% Free & Native**
  Powered entirely by native on-device Android APIs (`CallScreeningService`, `TelecomManager`, `SmsManager`). No cloud subscriptions, no Twilio fees, and no third-party APIs required.

## Technologies Used

- **Frontend:** Flutter & Dart
- **Backend Services:** Native Kotlin (Android)
- **Call Interception:** Android `CallScreeningService` API
- **SMS Dispatching:** Android `SmsManager`
- **Voice (TTS):** Google Text-to-Speech Engine via Foreground Service
- **Storage:** SharedPreferences

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/android-native-voicemail.git
   ```
2. Navigate into the project directory:
   ```bash
   cd android-native-voicemail
   ```
3. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```
4. Build and run on an Android device:
   ```bash
   flutter run
   ```

> **Note:** Because this app relies on the `CallScreeningService` and `SmsManager`, it must be tested on a physical Android device (API 29+) with a working SIM card. Simulators cannot fully replicate incoming phone calls and SMS capabilities.

## Privacy & Permissions

This app requires the following Android permissions to function properly:
- `ROLE_CALL_SCREENING`: To natively intercept and reject/answer incoming calls.
- `ANSWER_PHONE_CALLS`: To auto-answer the phone (Method 2).
- `SEND_SMS`: To send automated text replies.
- `READ_CONTACTS`: To check if an incoming caller is in your "Important Contacts" list.

All data, schedules, and custom messages are stored locally on your device.

## Developed By

Developed by **Danish K**  
[danishk.web.app](https://danishk.web.app)
