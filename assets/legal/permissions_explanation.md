# Android Permissions Explanation

> **DOCUMENT PURPOSE**: Transparent disclosure of all runtime and special permissions requested by {{APP_NAME}} on Android.

**Application:** {{APP_NAME}}  
**Company:** {{COMPANY_NAME}}  

---

### 1. `android.permission.READ_PHONE_STATE`
- **Purpose:** Identifies incoming call events (incoming ringing, off-hook, call ended) so the assistant can trigger greetings or update the inbox.
- **Privacy Safeguard:** Device serial numbers, IMEI, and SIM hardware identifiers are never accessed or stored.

### 2. `android.app.role.CallScreeningService`
- **Purpose:** Enables system call screening to deflect spam or incoming calls to voicemail without audio latency.
- **Privacy Safeguard:** Only screened numbers are processed; contacts on your whitelist ring through directly.

### 3. `android.permission.READ_CONTACTS` (Optional)
- **Purpose:** Displays caller names from your local address book instead of raw phone numbers.
- **Privacy Safeguard:** Contacts are queried on-demand in-memory and are never uploaded, synced, or shared externally.

### 4. `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- **Purpose:** Prevents OEM aggressive task managers from terminating background call listeners during device sleep.
- **Privacy Safeguard:** Battery usage is strictly event-driven and occurs only during active call events.

### 5. `android.permission.POST_NOTIFICATIONS`
- **Purpose:** Delivers instant heads-up alerts when new voicemails or call screening events occur.
