# ContextForge — Roadmap

## Phase 001 — Project Bootstrap & Documentation

**Status: Completed**

- Project documentation created (specification, roadmap, architecture, decisions, and process docs).
- Flutter Desktop project scaffolded for macOS.
- Initial version `0.0.1` tagged in changelog.
- One commit created for the phase.

---

## Phase 001A — Documentation Alignment

**Status: Completed**

- Specification rewritten to describe the real ContextForge workflow (prompt + YouTube transcripts → copy-ready output).
- Roadmap corrected to match the actual planned implementation phases.
- Architecture expanded with planned services, repositories, models, and widgets.
- New documentation created: TECH_DEBT.md, RELEASE_NOTES.md, TESTING.md.
- Session report and project state updated.
- One commit created for the phase.

---

## Phase 002 — Main Window

**Status: Completed**

- Application shell with the full static UI implemented.
- Root widget hierarchy and theming foundation (Material 3, light/dark mode via OS).
- Widget test covering section rendering and disabled buttons.
- `docs/DEPENDENCIES.md` created.
- One commit created for the phase.

---

## Phase 003 — Prompt Domain Foundation

**Status: Completed**

- Immutable `Prompt` model with id, title, content, rating, createdAt, updatedAt.
- JSON serialization/deserialization, `copyWith()`, equality, and readable `toString()`.
- Abstract `PromptRepository` contract (getAll, getById, save, delete).
- `PromptService` skeleton depending on the repository abstraction.
- No persistence, no storage implementation, no CRUD logic.

---

## Phase 004 — Prompt Local Storage

**Status: Completed**

- Local JSON-based storage for prompt templates in the platform application support directory.
- Human-readable `prompts.json` (indented JSON, editable by hand).
- `JsonPromptStorage` service owning filesystem paths.
- `JsonPromptRepository` concrete implementation (getAll, getById, save, delete).
- Graceful handling of missing files, empty files, and invalid JSON.
- Unit tests covering missing file, empty file, invalid JSON, save, load, update, and delete.
- No third-party storage packages — `dart:io` + `dart:convert` only.

---

## Phase 005 — Prompt Service Implementation

**Status: Completed**

- `PromptService` fully implemented as the application's prompt API.
- Business rules: title/content trimming, empty-value rejection, automatic `updatedAt`, in-service UUID generation.
- Domain exceptions: `PromptValidationException`, `PromptNotFoundException`.
- Unit tests: creation, update, delete, validation, trimming, UUID v4, updatedAt changes.
- UI must never talk to repositories directly — services are the public API.

---

## Phase 006 — Video Domain Foundation

**Status: Completed**

- Immutable `Video` model with id, url, videoId, title, channelName, publishedAt, transcriptLanguage, transcriptAvailable, createdAt, updatedAt.
- All timestamps are `DateTime` (UTC).
- `TranscriptLanguage` enum (polish, polishAuto, english, englishAuto, other, none) — no strings in the domain.
- Abstract `VideoRepository` contract (getAll, getByVideoId, save, delete).
- `VideoService` skeleton with public API established.
- Unit tests: JSON serialization, equality, copyWith, transcript language labels.

---

## Phase 007 — YouTube URL Parser

**Status: Completed**

- `YouTubeUrlParser` implemented with `isValidUrl()`, `extractVideoId()`, `normalizeUrl()`.
- Supports watch, short (youtu.be), mobile, and extra-query-parameter URLs.
- Canonical normalization to `https://www.youtube.com/watch?v=VIDEO_ID` (ADR-007).
- `InvalidYouTubeUrlException` domain exception.
- 36 comprehensive unit tests covering valid, invalid, malformed, empty, and whitespace URLs.
- No networking, no metadata fetching, no UI integration.

---

## Phase 008 — YouTube Provider Abstraction

**Status: Completed**

- Abstract `YoutubeProvider` interface in `lib/providers/`.
- Provider DTOs: `YoutubeVideoMetadata`, `YoutubeTranscriptInfo`, `YoutubeTranscript` (+ segments).
- Immutable DTOs with JSON serialization, copyWith, equality, readable toString.
- ADR-008: external integrations isolated behind provider abstractions.
- No networking, no API integration, no transcript fetching.
- Unit tests for DTO serialization and equality.

---

## Phase 009 — YouTube Metadata Provider

**Status: Completed**

- `YoutubeExplodeProvider` — concrete provider backed by `youtube_explode_dart` (3.1.0).
- `getVideoMetadata()` fetches title, channel, publication date, video id, canonical URL, duration, description.
- External package types never leak; mapped to provider DTOs (ADR-009).
- Domain exception mapping: `InvalidYouTubeUrlException`, `YoutubeVideoUnavailableException`, `YoutubeNetworkException`.
- No API key required; package selected and documented in DEPENDENCIES.md.
- Unit tests: successful retrieval, invalid URL, unavailable video, network failure, mapping.
- No transcripts, no UI integration.

---

## Phase 010 — Output Builder

**Status: Next**

- Assemble copy-ready text block:
  - selected prompt
  - inspiration section
  - transcript section

---

## Phase 011 — Clipboard Support

**Status: Planned**

- Copy generated output to clipboard.
- Copy interaction in the output preview.

---

## Phase 012 — UI Polish

**Status: Planned**

- Visual polish of the main window and workflow.
- Empty states, loading states, and error states.

---

## Phase 013 — Prompt Ratings

**Status: Planned**

- Rate and rank saved prompt templates.
- Feedback loop for prompt quality.

---

## Phase 014 — Transcript Cache

**Status: Planned**

- Cache downloaded transcripts locally.
- Avoid redundant transcript downloads.

---

## Phase 015 — Milestone 1 Audit

**Status: Planned**

- Full audit of MVP milestone 1.
- Update AUDIT_REPORT.md and close out remaining issues.

---

## Future Phases (Placeholders)

- Phase 016 — Vimeo support.
- Phase 017 — PDF sources.
- Phase 018 — RSS feed sources.
- Phase 019 — Website sources.
- Phase 020 — Local file support.
- Phase 021 — Audio file support.
- Phase 022 — Optional cloud sync.
- Phase 023 — Plugin system / integrations.
- Phase 024 — Collaboration features.
- Phase 025 — Cross-platform desktop support.