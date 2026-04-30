# Development Log

## Project: Wandering App

## 2026-03-28 ~ 2026-04-04 (Initial Commit)

### 🚀 Features
- Implemented a modular Flutter project structure using a feature-based architecture (auth, welcome, home, navigation)
- Integrated Firebase Authentication with support for:
  - Email & password registration and login
  - Google Sign-In authentication
  - Anonymous (guest) login
  - Password reset via email
- Designed and implemented a Welcome Page with:
  - Auto-switching city background images
  - Entry points for login/register and guest access
- Built Login Page and Register Page with:
  - Reusable input fields and buttons
  - Language toggle support (Chinese / English)
  - Forgot password dialog
- Implemented AuthGate to dynamically route users based on authentication state
- Added global multi-language (i18n) support using ARB files
- Created reusable UI components:
  - `AppTextField`
  - `AppButton` (supports multiple styles)
  - `SocialLoginButton` (with icon support)
  - Divider with text ("or")
- Set up asset management system for images and icons

### 🐛 Bugs
- UI inconsistency between AppBar and body background (top and bottom sections appeared visually separated)

### 🔧 Fixes
- Made AppBar transparent and removed elevation to unify page background
- Enabled extendBodyBehindAppBar to ensure a consistent full-screen layout

### ⚡ Improvements
- Refactored project to enforce strict separation of concerns:
  - UI → Controller → Repository → DataSource → Firebase
- Abstracted authentication logic into controller and repository layers to enable future backend migration
- Standardized UI components to improve consistency and reduce duplicated code
- Improved scalability of asset management by organizing assets into categorized folders
- Enhanced user experience with:
  - Animated background transitions on Welcome Page
  - Loading states for all authentication actions

### 📚 Learnings
- Gained a deeper understanding of clean architecture in Flutter, especially how to decouple UI from backend services
- Learned how Firebase Authentication works in practice, including anonymous login and third-party providers
- Improved knowledge of Flutter layout system, especially how `Scaffold`, `AppBar`, and `SafeArea` interact
- Understood the importance of reusable components for maintaining scalable UI design
- Learned how to structure a project for long-term maintainability and future backend migration

---

## 2026-04-06 ~ 2026-04-15
### 🚀 Features
- Persistent Language Support
  - Added local language persistence using SharedPreferences
  - App now remembers user's last selected language (Chinese/English)
- Profile Setup Feature
  - Implemented ProfileSetupPage for first-time authenticated users
- Migrated the app routing system to GoRouter
- Added a centralized router config in lib/app/app_router.dart
- Implemented router-level auth and profile-completion redirects
- Enabled automatic root-path routing from / to /welcome, /profile-setup, or /home
- Added a tabbed main container with custom bottom navigation.
- Added Me page and Profile Edit page.
- Added reusable ProfileForm for profile setup/edit flows.
- Added first version of Mapbox 3D globe home page.
- Added day/night style toggle on the map page.
- Added locale-driven map label language switching (Chinese/English).
- Added map initialization/loading/error fallback UI.
- Added Tokyo test marker with fly-to interaction and a floating place preview card.
- Added extensible local mock place/marker models for future multi-city and  mixed marker support.

### 🐛 Bug Fixes
- Fixed app crash on launch caused by `Null check operator used on a null value` (triggered by invalid route configuration with `initialRoute + routes`)
- Prevented potential exceptions when calling `pop` on an empty navigation stack
- Eliminated UI flicker caused by rendering AuthGate before redirect logic executed
- Migrated all navigation calls from `Navigator.pushNamed`, `pushReplacementNamed`, and `pop` to GoRouter APIs
- Refactored routing structure to avoid "Route not found" issues and improve stability
- Removed legacy `router.dart` usage while keeping a compatibility export
- Updated tests to align with the new GoRouter-based navigation architecture
- Replaced hardcoded user-facing strings in new pages with localization keys
- Ensured profile-related routing can use cached profile completion state
- Fixed issue where Chinese app locale still showed English map labels in China region by syncing basemap language on locale change and re-initializing the map when needed.

### ⚡ Improvements
- Architecture Refactor
  - Refactored to single MaterialApp structure to avoid route errors:  
- Moved auth and profile gating from the page layer to the router layer
- Improved route structure for maintainability and production readiness
- Added redirect loop prevention
- Enabled automatic route reevaluation on auth state changes
- Improved routing architecture with StatefulShellRoute and clearer auth/profile redirect handling.
- Added profile cache warm-up and refresh support to reduce repeated fetches.
- Refactored map logic into a dedicated map_home feature with clearer page/controller separation.
- Refined app-wide system UI behavior for transparent, always-visible status bar support

### 📚 Learnings
- Flutter initialization is asynchronous → always handle null
- Only one MaterialApp should exist in app
- Route guards are a better fit than page-level gates for auth and access rules
- GoRouter.redirect combined with an auth stream provides a cleaner app entry flow
- Navigation refactors need careful handling of empty back stacks, test setup, and redirect loops
- Learned how to import an earth model into an application

---

## 2026-04-15 ~ 2026-04-22
### 🚀 Features
- Added the Activity module with Firestore-backed event loading, bottom-tab entry, search, category filters, date/date-range filters, and a lightweight ActivityDetailPage placeholder.
- Added the foundational structure of the Community module, including Community Page, Create Post Page, Post Detail Page, and User Profile Page.
- Integrated real post list, real post detail, and basic comment flow (top-level comments + one-level replies).
- Added real post like / unlike flow with Firebase-backed like state and count sync
- Added Cloud Functions triggers for post likes and follow count maintenance
- Migrated map home mock data to Firebase.
- Added community image upload, location search, and delete flows.

### 🐛 Bug Fixes
- Fixed activity detail taps being redirected to the globe/map page
- Fixed post detail loading fallback so cached post content can still render when partial loads fail

### ⚡ Improvements
- improved event loading/filtering so activities with nullable `startAt` / `endAt` can still be displayed correctly.
- Introduced a clearer layered architecture (domain / data / presentation) to support future features like likes, follow system, and real user profile data.
- Extended repository and data source contracts to support likes, following, trending posts, and real profile queries
- Extracted map_home mapper and utils files.
- Added route and i18n support for the new community screens.

### 📚 Learnings
- Gained a clearer understanding of the minimal scalable structure for the Community module.
- Confirmed that “top-level comments + one-level replies” is sufficient for current needs, avoiding premature complexity.
- Keeping counter fields like likeCount, followerCount, and followingCount in Cloud Functions makes client rules much simpler
- Hardcoded mock data should be replaced early once the feature becomes real.
- Structured language maps are cleaner than flat localized fields for content that keeps growing.

---

## 2026-04-23~ 2026-04-2
### 🚀 Features
- Added a new PlaceDetailsPage shell with hero, chips, section scaffolding, and a fixed bottom action bar.
- Wired map preview card navigation to the new details page.
- Added admin dashboard, place/activity management, and subcontent management.
- Added image selection and auto-upload for admin forms.
- Added checklist trip flow scaffolding and place-to-checklist navigation.
- Added new localization keys for checklist pages and actions.
- Added journey wizard UI and save flow.
- Added checklist detail unplanned state with planning prompt.
- Added new checklist detail fields and route handling.
- Added OpenWeather API integration for accurate weather info.
- Implemented checklist plan generation with mock output.
- Added timeline-based checklist item presentation and richer item card variants.
- Activity fields now support bilingual display data.
- Admin activity form supports bilingual text inputs.
- Added Gemini-powered checklist plan generation with Google Places enrichment for hotels, restaurants, and activities.
- Added Firestore-backed place detail section loading for experiences, flavors, stays, and gallery.
- Added structured flight and place metadata fields to checklist items for richer detail rendering.

### 🐛 Bug Fixes
- Normalized Firestore language-map keys so zh/en variants resolve more reliably.
- Fixed crashes caused by legacy string values in events.
- Fixed category handling by removing free-text input.
- Fixed checklist plan generation failing when a single Google Places request hit a HandshakeException. Added request retries, timeout control, a shared HTTP client, and per-item fallback handling so one failed enrich request no longer marks the whole plan as failed.
- Fixed My Trips cards showing raw exception text and overflowing the layout. Filtered unsafe status text and constrained the UI to avoid rendering long backend error messages.
- Fixed checklist item cards overflowing on small screens by replacing multi-line mixed metadata blocks with a compact shared layout using fixed image sizing, Flexible/Expanded, and ellipsis.
- Bug: network images on community, activity, place preview, checklist, and profile surfaces could appear stretched, squashed, or overly cropped.
  Fix: replaced scattered image rendering with a shared AppNetworkImage path, blocked BoxFit.fill, kept preview pages on BoxFit.contain, and adjusted card cover ratios/alignment to reduce aggressive cropping without changing aspect ratio.
- Bug: large images uploaded from admin mode were stored as-is, which increased load cost and made image-heavy    screens feel slower.
  Fix: added upload-side compression in the admin Firebase data source, targeting roughly 600 KB - 800 KB while preserving aspect ratio before upload.

### ⚡ Improvements
- Added a pure UI model to prepare the future Firestore -> Repository -> Controller data flow.
- Added empty-state and placeholder handling for sections without data.
- Added a loading state to the Start Journey button for better feedback.
- Removed the forced wizard entry from checklist card taps.
- Prevented empty/missing trip info from blocking checklist viewing.
- Reworked checklist detail header and travel style summary to reduce repeated information.
- Refreshed weather essentials on locale changes.
- Expanded i18n coverage for weather, errors, and estimate labels.
- Improved activity search and display to use localized values.
- Improved admin activity list display for localized titles and cities.
- Tightened the Gemini prompt to require compact JSON, avoid marketing-style flight text, and enforce stricter hotel budget rules.
- Reworked the flight card into a fixed template with a stable EST. price badge and structured route/timeline rendering.
- Simplified hotel, restaurant, and activity cards to focus on title, image, short address, and a single-line price.
- Added detailed debug logging across checklist generation, wizard submission, and My Trips loading for easier tracing.
- Added current location support to the map home flow.
- Introduced a locate-me button, current-location map layers, and localized permission/error feedback.
- Added platform permissions and service locator wiring for device location access.
- Added disk-cached network image loading with size-aware downsampling.
- Added masked [ImageLoad] debug logs for start / loaded / error timing without exposing full URLs.
- Reused a shared icon action button for map controls to keep the map toolbar consistent.

### 📚 Learnings
- Only user-facing text should use language maps; structural fields should stay scalar.
- OpenWeather forecast data needs date-range filtering and fallback handling.
- Normalize IDs before save to avoid unstable document paths.
- Slow image loading was mostly a pipeline issue, not just a file-size issue; cache strategy and decode size mattered a lot.
- Keeping BoxFit.cover is fine for card media, but container ratio and alignment have a big effect on perceived cropping quality.
- Upload-side compression is a practical way to improve downstream image performance without changing Firebase data structures.