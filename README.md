# Jordan Neves — Client App (White-Label)

iOS app (SwiftUI, iOS 17+, Xcode 16+) that lets law-firm clients follow their legal cases. Built as a white-label base: all branding is isolated so new firms can be added as new Xcode targets without touching feature code.

## Run it

1. Open `JordanNeves.xcodeproj` in Xcode 16 or newer.
2. Select the **JordanNeves** scheme and an iPhone simulator, then Run.
3. Demo login: any CPF/email + password `123456` (mock auth).

## Screens

| Screen | File | Notes |
|---|---|---|
| Login | `App/Features/Login/LoginView.swift` | CPF/email + password, mock auth |
| Home | `App/Features/Home/HomeView.swift` | All client cases, open/closed sections, pull-to-refresh |
| Case detail | `App/Features/Home/CaseDetailView.swift` | Court info + timeline of updates (andamentos) |
| Profile | `App/Features/Profile/ProfileView.swift` | Personal data, language switch (PT/EN), logout |
| Contact | `App/Features/Contact/ContactView.swift` | Call, WhatsApp, email, website, maps, social |

## Languages

Portuguese (pt-BR, source) and English via a String Catalog (`App/Resources/Localizable.xcstrings`). The app follows the device language and also offers an in-app switch on the Profile screen.

## Architecture

- `App/Branding/` — everything brand-specific: `Brand.json` (names, contacts, API base URL), `Theme.swift` (colors/typography tokens), asset catalog colors (`BrandPrimary`, `BrandSecondary`, `BrandMuted`, `BrandBackground`), logos and AppIcon.
- `App/Core/` — models plus `CaseRepository` and `AuthService` protocols. The UI only depends on the protocols; `MockCaseRepository`/`MockAuthService` are the current implementations. To connect a real backend, add API-backed implementations and swap them in `AppState`.
- `App/Features/` — one folder per screen.

## Fonts

The brand font is **Montserrat** (Google Fonts). It is not bundled yet: download the `.ttf` files and drop them into `App/Resources/Fonts/`. They are registered automatically at launch (no Info.plist changes needed). Until then the app falls back to the system font.

## Adding a new white-label brand (new target)

1. In Xcode, duplicate the **JordanNeves** target and rename it (e.g. `AcmeAdv`).
2. In the new target's build settings, change `PRODUCT_BUNDLE_IDENTIFIER` and `INFOPLIST_KEY_CFBundleDisplayName`.
3. Create a brand folder with its own `Brand.json`, `Assets.xcassets` (same color/image names: `BrandPrimary`, `LogoHorizontal`, `LogoVertical`, `AppIcon`, …) and fonts; set target membership so the new target bundles the new brand files instead of the Jordan Neves ones.
4. Add a scheme for the new target. No feature code changes required.

## Backend integration (later)

Implement `CaseRepository` and `AuthService` against the real API (base URL comes from `Brand.json` → `api.baseURL`) and replace the mock instances in `AppState.swift`.
