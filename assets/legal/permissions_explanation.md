# Comprehensive Android Permissions Explanation

**Application:** Vani Voicemail  
**Target Platform:** Android 14+ (API 34)

Below is an itemized breakdown of why each permission is requested:

### 1. `android.permission.READ_PHONE_STATE`
- **Why it is needed:** Allows the assistant service to know when an incoming call starts and ends so it can prompt greetings or update the inbox.
- **Privacy safeguard:** We do not read device serial numbers, IMSI, or hardware identifiers.

### 2. `android.app.role.CallScreeningService`
- **Why it is needed:** Enables the system to screen incoming calls and invoke the assistant before the user's phone rings, bypassing ring latency.
- **Privacy safeguard:** Only screened numbers are inspected; contacts on your VIP whitelist bypass screening automatically.

### 3. `android.permission.READ_CONTACTS` (Optional)
- **Why it is needed:** Displays caller names (e.g. "Ramesh Nair") rather than raw phone numbers in the inbox.
- **Privacy safeguard:** Contacts are queried strictly on-demand in-memory and are never uploaded or shared.

### 4. `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- **Why it is needed:** Chinese OEM interfaces (Realme UI, ColorOS, MIUI, OxygenOS) aggressively terminate background listeners after 10 minutes of screen-off time. This exemption allows the assistant to remain responsive throughout the day.

### 5. `android.permission.POST_NOTIFICATIONS`
- **Why it is needed:** Displays instant heads-up banners when a new voicemail recording and transcript are available.

