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

### youtube_explode_dart

- **Version:** 3.1.0
- **Purpose:** Retrieves YouTube video metadata (title, channel, upload date, duration, description) without requiring an API key.
- **Why it exists:** Selected in Phase 009 as the most suitable package for metadata retrieval:
  - **Actively maintained:** regularly updated by the community; latest release 3.1.0.
  - **Reliable:** well-established pure-Dart implementation used widely in Flutter/Dart projects.
  - **No API key required:** scrapes public watch-page metadata, keeping setup friction-free.
  - **Flutter Desktop compatible:** pure Dart with no platform-specific native code.
- **Isolation:** The `YoutubeExplodeProvider` wraps this package so external package types never leak outside the provider layer (ADR-008, ADR-009).
- **Transitive packages introduced:** `archive`, `crypto`, `csslib`, `ffi`, `freezed_annotation`, `html`, `http`, `http_parser`, `json_annotation`, `logging`, `petitparser`, `posix`, `simple_sparse_list`, `typed_data`, `unicode`, `web`, `xml`.

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

- New dependencies are added deliberately and documented with their rationale.
- All external integrations are isolated behind provider abstractions in `lib/providers/`.