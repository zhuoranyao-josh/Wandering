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

---

### 🐛 Bugs
- UI inconsistency between AppBar and body background (top and bottom sections appeared visually separated)

---

### 🔧 Fixes
- Made AppBar transparent and removed elevation to unify page background
- Enabled extendBodyBehindAppBar to ensure a consistent full-screen layout

---

### ⚡ Improvements
- Refactored project to enforce strict separation of concerns:
  - UI → Controller → Repository → DataSource → Firebase
- Abstracted authentication logic into controller and repository layers to enable future backend migration
- Standardized UI components to improve consistency and reduce duplicated code
- Improved scalability of asset management by organizing assets into categorized folders
- Enhanced user experience with:
  - Animated background transitions on Welcome Page
  - Loading states for all authentication actions

---

### 📚 Learnings
- Gained a deeper understanding of clean architecture in Flutter, especially how to decouple UI from backend services
- Learned how Firebase Authentication works in practice, including anonymous login and third-party providers
- Improved knowledge of Flutter layout system, especially how `Scaffold`, `AppBar`, and `SafeArea` interact
- Understood the importance of reusable components for maintaining scalable UI design
- Learned how to structure a project for long-term maintainability and future backend migration

## 2026-04-06 ~ 2026-04-07
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

### ⚡ Improvements
- Architecture Refactor
  - Refactored to single MaterialApp structure to avoid route errors:  
- Moved auth and profile gating from the page layer to the router layer
- Improved route structure for maintainability and production readiness
- Added redirect loop prevention
- Enabled automatic route reevaluation on auth state changes
- Improved routing architecture with StatefulShellRoute and clearer auth/profile redirect handling.
- Added profile cache warm-up and refresh support to reduce repeated fetches.

### 📚 Learnings
- Flutter initialization is asynchronous → always handle null
- Only one MaterialApp should exist in app
- Route guards are a better fit than page-level gates for auth and access rules
- GoRouter.redirect combined with an auth stream provides a cleaner app entry flow
- Navigation refactors need careful handling of empty back stacks, test setup, and redirect loops

### Future plans:

