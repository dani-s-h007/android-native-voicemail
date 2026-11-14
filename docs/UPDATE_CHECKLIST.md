# Production Release Configuration Checklist

This document details every `TODO_UPDATE` configuration placeholder that must be updated before generating a production release build.

The build-time validator (`ConfigValidator` in `lib/app/config/config_validator.dart`) will automatically halt any release build in the `prod` flavor if any of these values remain unconfigured.

---

## 1. App Identity & Branding

| Field Name in `AppConfig` | Description | Default Placeholder | Production Value |
|---------------------------|-------------|---------------------|------------------|
| `appName` | Public application name displayed in launcher and UI | `'Call Assistant'` | Your app name |
| `appTagline` | App subtitle / marketing tagline | `'Smart On-Device Voicemail & Call Assistant'` | Your tagline |
| `packageIdProd` | Android Application ID / Package Name | `'com.example.voicemail'` | Your registered package ID |
| `brandSeedColor` | Fallback primary seed color for Material 3 palettes | `Color(0xFF1A73E8)` | Your brand HEX color |
| `logoAssetPath` | Path to square app icon | `'assets/icon.jpg'` | App icon path |

---

## 2. Developer & Support Contacts

| Field Name in `AppConfig` | Description | Default Placeholder | Production Value |
|---------------------------|-------------|---------------------|------------------|
| `developerName` | Developer / Studio / Company display name | `'TODO_UPDATE_DEVELOPER_NAME'` | Your name or company name |
| `developerWebsiteUrl` | Developer portfolio or marketing site | `'https://example.com'` | Real developer website URL |
| `supportEmail` | Primary email address for user support inquiries | `'support@example.com'` | Active support email inbox |
| `supportPhone` | (Optional) Telephone support contact number | `''` | Support phone (or leave blank) |

---

## 3. Legal & Compliance URLs

| Field Name in `AppConfig` | Description | Default Placeholder | Production Value |
|---------------------------|-------------|---------------------|------------------|
| `privacyPolicyUrl` | Public web-hosted URL for Privacy Policy | `'https://example.com/privacy'` | Active public HTTPS URL |
| `termsUrl` | Public web-hosted URL for Terms of Service | `'https://example.com/terms'` | Active public HTTPS URL |
| `dataSafetyUrl` | Public web-hosted URL for Google Play Data Safety | `'https://example.com/data-safety'` | Active public HTTPS URL |
| `recordingNoticeUrl` | Public web-hosted URL for Call Recording Policy | `'https://example.com/recording-notice'` | Active public HTTPS URL |

---

## 4. Corporate & Regulatory Compliance

| Field Name in `AppConfig` | Description | Default Placeholder | Production Value |
|---------------------------|-------------|---------------------|------------------|
| `companyLegalName` | Official registered entity name | `'TODO_UPDATE_COMPANY_LEGAL_NAME'` | Your registered business name |
| `companyAddress` | Physical registered corporate address | `'TODO_UPDATE_COMPANY_ADDRESS'` | Your corporate address |
| `enableGrievanceOfficer` | Enable designated Grievance / DPO Officer screen | `false` | `true` if mandated in your region |
| `grievanceOfficerName` | Name of designated compliance officer | `'TODO_UPDATE_OFFICER_NAME'` | Officer name |
| `grievanceOfficerContact` | Contact details of compliance officer | `'TODO_UPDATE_OFFICER_CONTACT'` | Officer email or phone |

---

## 5. Regional Defaults & Carrier Profiles

| Field Name in `AppConfig` | Description | Default Placeholder | Production Value |
|---------------------------|-------------|---------------------|------------------|
| `defaultRegion` | Default ISO country code for new installs | `'US'` | Your primary target market (e.g. `US`, `GB`, `IN`) |
| `supportedRegions` | Regional rules with emergency numbers and consent laws | US, GB, IN, DE, CA, AU | Add any custom countries required |
| `defaultCarrierProfiles` | MMI Forwarding codes (*67*, *61*, ##002#) | Example profiles (unverified) | Test on actual SIM before verifying |

---

## 6. Backend & Service Flags

| Field Name in `AppConfig` | Description | Default Placeholder | Production Value |
|---------------------------|-------------|---------------------|------------------|
| `backendBaseUrl` | Production telephony / relay server endpoint | `'https://api.example.com'` | Real server endpoint (or leave mock) |
| `mockServicesByDefault` | Run offline with mock implementations | `true` | `false` when connecting to live server |
| `storeListingShortDescription` | Google Play Store short summary (max 80 chars) | Placeholder summary | Your Play Store short description |
| `changelogUrl` | Feed URL for in-app changelog updates | `'https://example.com/changelog.json'` | Your changelog URL |
| `updateCheckUrl` | Version checker endpoint | `'https://example.com/version.json'` | Your version manifest URL |

---

## 7. How to Validate Before Building

Run the validation CLI tool:

```bash
dart run lib/app/config/config_validator.dart prod
```

If any `TODO_UPDATE` or `example.com` placeholders remain, the tool will exit with an error code and list the offending keys.
