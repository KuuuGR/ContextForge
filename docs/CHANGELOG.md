# Changelog

All notable changes to ContextForge will be documented in this file.

## [0.0.6] — 2026-02-08

### Added

- `TranscriptLanguage` enum (`lib/models/transcript_language.dart`).
  - Values: `polish`, `polishAuto`, `english`, `englishAuto`, `other`, `none`.
  - Human-readable `label` values; no strings used in the domain.
- Immutable `Video` domain model (`lib/models/video.dart`).
  - Fields: id, url, videoId, title, channelName, publishedAt, transcriptLanguage, transcriptAvailable, createdAt, updatedAt.
  - All timestamps are `DateTime` (UTC).
  - JSON serialization/deserialization, `copyWith()`, equality, readable `toString()`.
  - Unknown transcript language values default to `none` on deserialization.
- Abstract `VideoRepository` contract (`lib/repositories/video_repository.dart`).
  - Methods: `getAll()`, `getByVideoId()`, `save()`, `delete()`.
- `VideoService` skeleton (`lib/services/video_service.dart`).
  - Public API: `getAllVideos()`, `getVideoByVideoId()`, `hasBeenUsed()`.
  - No business logic yet; implementations arrive in Phase 007.
- Unit tests (`test/video_model_test.dart`).
  - JSON serialization, round-trip, defaults, copyWith, equality, toString, language labels.

### Changed

- Project version updated to `0.0.6`.
- Architecture documentation marks Video model, TranscriptLanguage, VideoRepository, and VideoService as implemented.

## [0.0.5] — 2026-02-08

### Added

- Domain exceptions (`lib/exceptions/prompt_exceptions.dart`).
  - `PromptException` base class.
  - `PromptValidationException` for invalid prompt input.
  - `PromptNotFoundException` for missing prompts.
- `PromptService` fully implemented (`lib/services/prompt_service.dart`).
  - Public API: `getAllPrompts()`, `getPrompt(id)`, `createPrompt()`, `updatePrompt()`, `deletePrompt()`.
  - Business rules: title/content trimming, empty-value rejection, auto `updatedAt`, in-service UUID v4 generation.
  - Throws meaningful domain exceptions; storage exceptions never leak to callers.
- Unit tests (`test/prompt_service_test.dart`).
  - Creation, update, delete, validation, trimming, UUID v4 format, unique ids, updatedAt changes.

### Changed

- Project version updated to `0.0.5`.
- `PromptService` marked fully implemented in architecture documentation.
- Added ADR-006: never create fake UI models — use production domain models everywhere.

## [0.0.4] — 2026-02-08

### Added

- `JsonPromptStorage` service (`lib/services/json_prompt_storage.dart`).
  - Human-readable, indented JSON file (`prompts.json`) in the platform application support directory (`~/Library/Application Support/context_forge` on macOS).
  - Auto-creates the file with `[]` when missing.
  - Handles missing, empty, and corrupt files gracefully (returns empty list).
  - Optional directory path override for tests.
- `JsonPromptRepository` (`lib/repositories/json_prompt_repository.dart`).
  - Concrete `PromptRepository` implementation backed by JSON storage.
  - Implements `getAll()`, `getById()`, `save()`, and `delete()` asynchronously.
  - Never crashes because of storage problems.
- Unit tests (`test/json_prompt_repository_test.dart`).
  - Missing file, empty file, invalid JSON, save, load, getById, update, delete, and delete-missing.

### Changed

- Project version updated to `0.0.4`.
- Architecture documentation marks `JsonPromptStorage` and `JsonPromptRepository` as implemented.

### Notes

- No new dependencies added — storage uses Dart's built-in `dart:io` and `dart:convert` only.
- Storage remains fully replaceable through the `PromptRepository` abstraction.

## [0.0.3] — 2026-02-08

### Added

- Immutable `Prompt` domain model (`lib/models/prompt.dart`).
  - Fields: `id`, `title`, `content`, `rating`, `createdAt`, `updatedAt`.
  - JSON serialization/deserialization.
  - `copyWith()`, value equality, and readable `toString()`.
- Abstract `PromptRepository` contract (`lib/repositories/prompt_repository.dart`).
  - Methods: `getAll()`, `getById()`, `save()`, `delete()`.
- `PromptService` skeleton (`lib/services/prompt_service.dart`).
  - Depends on the repository abstraction.
  - No implementation logic yet; method bodies arrive in later phases.

### Changed

- Project version updated to `0.0.3`.
- Architecture documentation marks Prompt model, PromptRepository, and PromptService as implemented.

## [0.0.2] — 2026-02-08

### Added

- Main application window with header (title + subtitle).
- Prompt section with dropdown selector, custom prompt option, and disabled-unless-custom editor.
- Videos section with three video input cards (green/blue/gray status indicators).
- Output section with read-only text area.
- Bottom toolbar with disabled Generate, Copy, and Clear buttons.
- Temporary mock prompt options: SEO Article, Newsletter, LinkedIn, Facebook, Custom Prompt.
- Widget test covering main window section rendering and disabled buttons.
- `docs/DEPENDENCIES.md` documenting current dependencies.

### Changed

- Replaced default Flutter counter application with the ContextForge application shell.
- Project version updated to `0.0.2`.

## [0.0.1] — 2026-02-08

### Added

- Project documentation structure (`docs/`).
  - Specification
  - Roadmap
  - Architecture
  - Changelog
  - Session report
  - Known issues
  - Future ideas
  - Decisions
  - Audit report
  - Project state
  - Prompt guidelines
- Flutter Desktop project scaffolded for macOS.
- One commit: `Phase 001 - Project bootstrap and documentation`.