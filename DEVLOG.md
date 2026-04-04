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

