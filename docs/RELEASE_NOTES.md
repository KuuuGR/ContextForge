# Release Notes — ContextForge

## Version 0.1.0

**Release Date:** 2026-02-08

### What's New

- First complete vertical slice: paste a YouTube URL → validate → fetch metadata → display Title, Channel, Publication Date.
- Three controller-driven video cards with status indicators (gray = empty, green = loaded, red = error, blue reserved for history).
- Loading indicator while metadata is being retrieved.
- Friendly, user-facing error messages (raw exceptions never shown).
- `VideoService.fetchVideoMetadata()` orchestrates URL validation, provider fetch, and DTO→domain mapping.
- `VideoCardController` presentation-layer controller for card state.

### Notes

- No transcript functionality or history support yet.
- Video persistence uses an in-memory repository in this phase (persistence arrives later).

---

## Version 0.0.9

**Release Date:** 2026-02-08

### What's New

- `YoutubeExplodeProvider` — the first concrete metadata provider.
- Fetches title, channel name, publication date, video ID, canonical URL, duration, and description.
- Backed by `youtube_explode_dart` 3.1.0 (no API key required).
- Domain exceptions: `YoutubeVideoUnavailableException`, `YoutubeNetworkException`.
- External package types never leak from the provider layer (ADR-009).

### Notes

- Metadata only — no transcript fetching, no transcript selection, no UI integration.
- Dependency rationale documented in `docs/DEPENDENCIES.md`.

---

## Version 0.0.8

**Release Date:** 2026-02-08

### What's New

- Provider layer (`lib/providers/`).
- Abstract `YoutubeProvider` interface: `getVideoMetadata()`, `getAvailableTranscripts()`, `downloadTranscript()`.
- Immutable provider DTOs: `YoutubeVideoMetadata`, `YoutubeTranscriptInfo`, `YoutubeTranscript`, `YoutubeTranscriptSegment`.
- DTOs support JSON serialization/deserialization, copyWith, equality, readable toString.

### Notes

- No networking or API integration — abstraction layer only.
- ADR-008: external integrations isolated behind provider abstractions.

---

## Version 0.0.7

**Release Date:** 2026-02-08

### What's New

- `YouTubeUrlParser` with `isValidUrl()`, `extractVideoId()`, `normalizeUrl()`.
- Supports watch, youtu.be short, mobile, and extra-query-parameter URLs.
- Canonical normalization to `https://www.youtube.com/watch?v=VIDEO_ID`.
- `InvalidYouTubeUrlException` for unsupported/malformed URLs.
- 36 unit tests covering valid and invalid URL cases.

### Notes

- URLs are normalized before entering the domain layer (ADR-007).
- Independent from Flutter UI and networking.

---

## Version 0.0.6

**Release Date:** 2026-02-08

### What's New

- Immutable `Video` domain model:
  - id, url, videoId, title, channelName, publishedAt, transcriptLanguage, transcriptAvailable, createdAt, updatedAt.
  - All timestamps are `DateTime` (UTC).
- `TranscriptLanguage` enum (polish, polishAuto, english, englishAuto, other, none).
- Abstract `VideoRepository` contract (getAll, getByVideoId, save, delete).
- `VideoService` skeleton (getAllVideos, getVideoByVideoId, hasBeenUsed).
- Unit tests for JSON serialization, equality, copyWith, and language labels.

### Notes

- No networking, storage, history, or metadata fetching — domain foundation only.

---

## Version 0.0.5

**Release Date:** 2026-02-08

### What's New

- `PromptService` fully implemented as the prompt API:
  - `getAllPrompts()`, `getPrompt(id)`, `createPrompt()`, `updatePrompt()`, `deletePrompt()`.
  - Title/content trimming and empty-value validation.
  - Automatic `updatedAt` refresh and in-service UUID v4 generation.
- Domain exceptions: `PromptValidationException`, `PromptNotFoundException`.
- 18 new unit tests covering business rules.

### Notes

- The UI must go through services, never repositories directly.
- Added ADR-006: never create fake UI models.

---

## Version 0.0.4

**Release Date:** 2026-02-08

### What's New

- Local JSON storage for prompt templates (`prompts.json` in the application support directory).
- `JsonPromptStorage` service — human-readable, indented JSON; auto-creates missing files.
- `JsonPromptRepository` — concrete implementation of the `PromptRepository` contract.
- Graceful handling of missing, empty, and invalid JSON files.
- Unit tests covering storage edge cases.

### Notes

- No third-party storage packages — uses Dart built-in `dart:io` and `dart:convert`.
- Storage remains replaceable through the `PromptRepository` abstraction.

---

## Version 0.0.3

**Release Date:** 2026-02-08

### What's New

- Immutable `Prompt` domain model with JSON serialization/deserialization, `copyWith()`, equality, and readable `toString()`.
- Abstract `PromptRepository` contract (getAll, getById, save, delete).
- `PromptService` skeleton depending on the repository abstraction.

### Notes

- No persistence, storage, or CRUD logic yet — domain foundation only.

---

## Version 0.0.2

**Release Date:** 2026-02-08

### What's New

- Main application window and application shell:
  - Header (title + subtitle).
  - Prompt section (dropdown selector, custom prompt option, disabled-unless-custom editor).
  - Videos section (three video input cards with green/blue/gray status indicators).
  - Output section (read-only preview).
  - Bottom toolbar (disabled Generate, Copy, Clear buttons).
- `docs/DEPENDENCIES.md` created.

### Notes

- No business logic, networking, or storage implemented yet.
- Static UI only; all buttons disabled by design.

---

## Version 0.0.1

**Release Date:** 2026-02-08

### What's New

- Project bootstrap and documentation structure.
- Flutter Desktop project scaffolded for macOS.
- Documentation alignment with the ContextForge vision (Phase 001A).

### Notes

- No application features are available yet.
- This is an internal bootstrap release, not a public release.

---

_Release notes will be maintained from this point forward._