# Dependencies — ContextForge

This document lists every dependency currently used by the project and explains why each dependency exists.

## Runtime Dependencies

### Flutter SDK

- **Purpose:** UI framework for building the macOS desktop application.
- **Why it exists:** Core application framework — ContextForge is built on Flutter Desktop per ADR-001.

### cupertino_icons

- **Version:** ^1.0.8
- **Purpose:** iOS-style icons.
- **Why it exists:** Included by the default Flutter scaffold. Used as a general icon asset source alongside Material Icons.

## Dev Dependencies

### flutter_test

- **Purpose:** Unit and widget testing framework.
- **Why it exists:** Required for running the widget test suite (`flutter test`).

### flutter_lints

- **Version:** ^6.0.0
- **Purpose:** Recommended lint rules for Flutter code.
- **Why it exists:** Enforces code quality and consistent style during development.

---

## Notes

- No additional runtime packages have been added beyond the default Flutter scaffold.
- New dependencies will be added to this document as they are introduced in future phases.