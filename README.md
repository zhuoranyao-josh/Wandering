# Wandering App

## 1. Project Title & Description

### Project Title

### Description

---

## 2. Installation & Usage

### Installation

- Step 1:
- Step 2:
- Step 3:
- Step 4:

### Usage

- Feature 1:
- Feature 2:
- User flow:

---

## 3. Help & Support

- Contact:

---

## 4. Project Structure

```text
lib/
├── main.dart
├── firebase_options.dart
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── language_controller.dart
│
├── core/
│   ├── di/
│   │   └── service_locator.dart
│   ├── error/
│   │   └── app_exception.dart
│   └── widgets/
│       ├── app_text_field.dart
│       ├── app_button.dart
│       ├── social_login_button.dart
│       └── app_divider_with_text.dart
│
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── auth_user.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_data_source.dart
│   │   │   │   └── firebase_auth_remote_data_source.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── auth_controller.dart
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   └── register_page.dart
│   │       └── widgets/
│   │           └── forgot_password_dialog.dart
│   │
│   ├── welcome/
│   │   └── presentation/
│   │       └── pages/
│   │           └── welcome_page.dart
│   │
│   ├── navigation/
│   │   └── presentation/
│   │       └── pages/
│   │           └── auth_gate.dart
│   │
│   └── home/
│       └── presentation/
│           └── pages/
│               └── home_page.dart
│
└── l10n/
    ├── app_en.arb
    ├── app_zh.arb
    └── l10n.dart
```

---

## 5. Contact Information