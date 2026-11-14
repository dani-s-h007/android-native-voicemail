# Production Release Configuration Checklist

> **Application**: Call Assistant & Visual Voicemail  
> **Target OS**: Android  
> **Creator & Developer**: Danish K ([https://danishk.web.app](https://danishk.web.app))

This document details every configuration placeholder that must be updated before generating a production release build (`prod` flavor).

The build-time validator (`ConfigValidator` in `lib/app/config/config_validator.dart`) will automatically halt any release build in the `prod` flavor if any of these values remain unconfigured.

---

## 1. App Identity & Branding

| Field Name in `AppConfig` | Description | Active Configuration | Production Action |
|---------------------------|-------------|----------------------|-------------------|
| `appName` | Public application name displayed in launcher and UI | `'Call Assistant'` | Set to your official application title |
| `appTagline` | App subtitle / marketing tagline | `'Smart On-Device Voicemail & Call Assistant'` | Set to your official tagline |
| `packageIdProd` | Android Application ID / Package Name | `'com.example.voicemail'` | **TODO_UPDATE**: Replace with your registered Google Play package ID (e.g. `com.danishk.voicemail`) |
| `brandSeedColor` | Fallback primary seed color for Material 3 palettes | `Color(0xFF1A73E8)` | Brand primary color |
| `logoAssetPath` | Path to square app icon | `'assets/icon.jpg'` | Verified asset icon |

---

## 2. Developer & Support Contacts

| Field Name in `AppConfig` | Description | Active Configuration | Status |
|---------------------------|-------------|----------------------|--------|
| `developerName` | Developer / Publisher public display name | `'Danish K'` | **CONFIGURED** |
| `developerWebsiteUrl` | Developer portfolio or marketing site | `'https://danishk.web.app'` | **CONFIGURED** |
| `supportEmail` | Primary email address for user support inquiries | `'support@danishk.web.app'` | **CONFIGURED** |
| `supportPhone` | (Optional) Telephone support contact number | `''` | Optional (leave blank or add phone) |

---

## 3. Legal & Compliance Web URLs

The app includes built-in generic Markdown drafts for all 7 legal documents in `assets/legal/`. When publishing, host the finalized lawyer-approved documents on your web domain and update these URLs:

| Field Name in `AppConfig` | Description | Default Placeholder | Production Value |
|---------------------------|-------------|---------------------|------------------|
| `privacyPolicyUrl` | Public web-hosted URL for Privacy Policy | `'https://example.com/privacy'` | **TODO_UPDATE**: Real HTTPS URL (e.g. `https://danishk.web.app/privacy`) |
| `termsUrl` | Public web-hosted URL for Terms of Service | `'https://example.com/terms'` | **TODO_UPDATE**: Real HTTPS URL (e.g. `https://danishk.web.app/terms`) |
| `dataSafetyUrl` | Public web-hosted URL for Google Play Data Safety | `'https://example.com/data-safety'` | **TODO_UPDATE**: Real HTTPS URL |
| `recordingNoticeUrl` | Public web-hosted URL for Call Recording Policy | `'https://example.com/recording-notice'` | **TODO_UPDATE**: Real HTTPS URL |

---

## 4. Corporate & Regulatory Compliance

| Field Name in `AppConfig` | Description | Default Placeholder | Production Value |
|---------------------------|-------------|---------------------|------------------|
| `companyLegalName` | Official registered entity name | `'TODO_UPDATE_COMPANY_LEGAL_NAME'` | **TODO_UPDATE**: Legal business or developer entity name |
| `companyAddress` | Physical registered corporate address | `'TODO_UPDATE_COMPANY_ADDRESS'` | **TODO_UPDATE**: Physical address or registered jurisdiction |
| `enableGrievanceOfficer` | Enable designated Grievance / DPO Officer screen | `false` | Set to `true` if mandated in your target region |
| `grievanceOfficerName` | Name of designated compliance officer | `'TODO_UPDATE_OFFICER_NAME'` | Required if `enableGrievanceOfficer = true` |
| `grievanceOfficerContact` | Contact details of compliance officer | `'TODO_UPDATE_OFFICER_CONTACT'` | Required if `enableGrievanceOfficer = true` |

---

## 5. Regional Defaults & Carrier Profiles

| Field Name in `AppConfig` | Description | Active Configuration | Notes |
|---------------------------|-------------|----------------------|-------|
| `defaultRegion` | Default ISO country code for new installs | `'US'` | End-users can also change this in Settings |
| `supportedRegions` | Regional rules with emergency numbers and consent laws | US, GB, IN, DE, CA, AU | Fully extensible via `RegionRulesService` |
| `defaultCarrierProfiles` | MMI Forwarding codes (*67*, *61*, ##002#) | Example profiles (AT&T, Verizon, T-Mobile, Jio, Airtel, Vodafone) | Marked unverified; test on physical SIM before validating |

---

## 6. Backend & Service Flags

| Field Name in `AppConfig` | Description | Default Setting | Notes |
|---------------------------|-------------|-----------------|-------|
| `backendBaseUrl` | Production telephony / relay server endpoint | `'https://api.example.com'` | Unused in offline / mock mode |
| `mockServicesByDefault` | Run offline with mock implementations | `true` | Set to `false` when connecting to live telephony backend |
| `storeListingShortDescription` | Google Play Store short summary (max 80 chars) | Configured | Used for store metadata verification |
| `changelogUrl` | Feed URL for in-app changelog updates | `'https://example.com/changelog.json'` | Optional dynamic feed |
| `updateCheckUrl` | Version checker endpoint | `'https://example.com/version.json'` | Optional update manifest |

---

## 7. Build-Time Validation CLI

To check whether your project is ready for a production release build, run the validation tool:

```bash
# Validating for dev flavor (will display warnings without halting):
flutter test test/core/config_validator_test.dart

# Running validation for production:
dart run lib/app/config/config_validator.dart prod
```

If any `TODO_UPDATE` placeholder markers or `example.com` dummy domains remain in production configuration, the validator will output an error list and fail the build.
