# Reflexa App Store Connect Submission Playbook (as of February 19, 2026)

This is a copy/paste playbook to clear remaining App Store Connect blockers for Reflexa.

## 1) Fastest Unblock Order

1. Accept pending agreements (`#39`).
2. Fill App Information URLs + EULA decision (`#1`, `#3`, `#5`).
3. Complete compliance forms: Age Rating, App Privacy, Export Compliance, DSA (`#13`, `#14`, `#15`, `#43`).
4. Complete version metadata + screenshots + select final build (`#11`, `#12`, `#35`).
5. Fill App Review contact + notes (`#36`, `#37`).

## 2) App Information (copy/paste)

Use in **App Store Connect -> App Information**:

- `Privacy Policy URL`: `https://lauhithn.github.io/reflexa-legal-pages/privacy.html`
- `Support URL`: `https://lauhithn.github.io/reflexa-legal-pages/support.html`
- `Marketing URL` (optional): `https://lauhithn.github.io/reflexa-legal-pages/`
- `License Agreement`: **Apple Standard License Agreement** (recommended unless you explicitly need a custom EULA)

## 3) Version Metadata (copy/paste)

Use in **App Store Connect -> iOS App -> Version Information**.

### Subtitle
`Train Your Reflexes Fast`

### Promotional Text
`Train reaction speed with 8 focused game modes in solo or local multiplayer. No account, no ads, no subscriptions, and no in-app purchases.`

### Keywords (92 bytes)
`reaction time,reflex training,brain games,speed test,quick tap,multiplayer,memory game,focus`

### Description
`Reflexa is a modern reaction-training game built for short, repeatable practice.

Play 8 game modes that challenge timing, speed, memory, and focus:
- Stopwatch
- Color Flash
- Quick Tap
- Sequence Memory
- Color Sort
- Grid Reaction
- Charge & Release
- Color Battle (local multiplayer)

Highlights:
- Solo and local multiplayer experiences
- Fast sessions designed for quick practice
- Clean, distraction-free interface

Privacy and app model:
- No account creation or login
- No ads
- No subscriptions
- No in-app purchases
- No persistent gameplay history or stats tracking`

### Copyright
`2026 Reflexa. All rights reserved.`

### Support URL (version field if shown)
`https://lauhithn.github.io/reflexa-legal-pages/support.html`

## 4) Screenshots (iPhone-only target)

Your project is now iPhone-only, so submit iPhone screenshots for required classes.

Recommended safe set:
- Upload at least one full set for **6.9-inch display**.
- Include 5-8 screenshots showing:
  1. Home (game mode list)
  2. Game setup
  3. Gameplay (timing mode)
  4. Gameplay (tap/speed mode)
  5. Gameplay (multiplayer mode)
  6. Result screen
  7. Settings screen (legal/support links visible)

Quality rules:
- No placeholder or outdated UI text.
- No leaderboard mentions.
- Match current app behavior.

## 5) Age Rating Questionnaire (`#13`)

In **App Store Connect -> Age Rating** use:
- Content Descriptors: set all to **None / Not Present** unless a descriptor truly applies.
- In-App Controls: **None**.
- Capabilities:
  - User-generated content: **No**
  - Social networking/chat/messaging: **No**
  - Advertising: **No**
  - Unrestricted web access: **No**

Expected result should be a low age rating (typically 4+ for this app model).

## 6) App Privacy Questionnaire (`#14`)

In **App Store Connect -> App Privacy** use:
- `Data Used to Track You`: **No**
- `Data Collected`: **No** (for current implementation)

Why this matches current app:
- No third-party analytics/ads SDKs.
- No account backend.
- No persistent gameplay database or history tracking.
- Share action uses iOS share sheet and is user-initiated.

Important: if you later add analytics, remote APIs, ads, login, or tracking, you must update these answers before that build is released.

## 7) Export Compliance (`#15`)

In **App Store Connect -> Export Compliance** for this version:
- Classify Reflexa as using only standard, exempt encryption (no proprietary/custom crypto).
- Confirm no non-exempt encryption features are implemented.

Practical rule for this app:
- No custom cryptography.
- No VPN/secure-messaging/crypto-product functionality.
- Typical iOS platform encryption usage only.

## 8) App Review Information (`#36`, `#37`) copy/paste

### Contact Information
Use a monitored contact. If you want it aligned with support page:
- First name: `Lauhith`
- Last name: `Natarajan`
- Email: `lauhithn@gmail.com`
- Phone: `+1 416-939-5810`

### Review Notes
`Reflexa is a local-first reflex training game.

Reviewer guidance:
1) Launch app and complete onboarding.
2) Select any game mode from Home.
3) Play a round and view results.
4) Optional: tap Share to open the iOS share sheet.

App characteristics:
- No login or account creation.
- No subscriptions or in-app purchases.
- No ads and no third-party analytics SDK.
- No persistent results/stats tracking.
- Settings contains Support, Privacy Policy, and Terms links.`

## 9) Build Selection (`#35`)

In **Version -> Build**:
- Select the archive matching your intended release commit.
- Confirm `Version` and `Build` numbers match this submission.
- If multiple builds exist, remove ambiguity by expiring older unintended builds.

## 10) DSA Trader Status (`#43`)

If you distribute in the EU:
- Complete **Digital Services Act** trader/non-trader declaration.
- If `Trader`: provide and verify legal name, address, phone, and email.
- If `Non-Trader`: complete declaration and verify displayed disclosure text.

## 11) Agreements (`#39`)

Account Holder must verify in **Agreements, Tax, and Banking**:
- Latest Apple Developer Program License Agreement accepted.
- Any pending App Store Connect agreements accepted.

---

## Source Notes (Apple docs used)

- Required app/version metadata fields and URL rules: https://developer.apple.com/help/app-store-connect/reference/platform-version-information/
- Privacy Policy URL field in App Information: https://developer.apple.com/help/app-store-connect/reference/app-information/
- Standard vs custom license agreement: https://developer.apple.com/help/app-store-connect/manage-app-information/provide-a-custom-license-agreement/
- Age rating questionnaire model and deadline: https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/ and https://developer.apple.com/news/upcoming-requirements/?id=01312026a
- App Privacy questionnaire: https://developer.apple.com/help/app-store-connect/manage-app-privacy/manage-app-privacy-details-on-app-store-connect/
- Export compliance workflow: https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/
- App Review contact/notes fields: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/add-app-review-information/
- DSA trader requirements: https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/
- Agreements acceptance: https://developer.apple.com/help/app-store-connect/reference/agreements-tax-and-banking/
