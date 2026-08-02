# ContextForge — Architecture

## Overview

ContextForge is a local-first, layered desktop application built on Flutter Desktop for macOS. The application follows a clear separation of concerns: presentation (widgets), application logic (services), data access (repositories), and domain data (models). The core user workflow is: select a prompt template → paste up to three YouTube URLs → fetch publication dates and transcripts → clean transcripts → generate a single copy-ready text block.

## Folder Structure

```
lib/
├── main.dart
├── app/
│   └── (application entry, root widget, theme)
├── models/
│   ├── prompt.dart
│   ├── video.dart
│   ├── transcript.dart
│   ├── output_document.dart
│   ├── application_settings.dart
│   └── video_history_entry.dart
├── providers/
│   ├── youtube_provider.dart
│   ├── youtube_video_metadata.dart
│   ├── youtube_transcript_info.dart
│   └── youtube_transcript.dart
├── repositories/
│   ├── prompt_repository.dart
│   ├── video_history_repository.dart
│   ├── transcript_cache_repository.dart
│   └── settings_repository.dart
├── services/
│   ├── prompt_service.dart
│   ├── youtube_service.dart
│   ├── transcript_service.dart
│   ├── output_builder.dart
│   ├── storage_service.dart
│   ├── settings_service.dart
│   └── history_service.dart
└── widgets/
    ├── prompt_selector.dart
    ├── prompt_editor.dart
    ├── video_input_card.dart
    ├── transcript_status_indicator.dart
    ├── output_preview.dart
    └── generate_button.dart
```

## Layers & Responsibilities

### Presentation Layer (widgets)

- Renders the user interface.
- Composes reusable UI widgets from domain models.
- Dispatches user actions to services.
- Contains no business logic.

### Application Layer (services)

- Implements application workflows and use cases.
- Orchestrates repositories and models.
- Manages application state transitions.
- Kept free of framework-specific UI concerns.

### Data Access Layer (repositories)

- Abstract the persistence mechanism.
- Handle local storage read/write operations.
- Isolate storage engines (e.g., files, database) behind interfaces.
- Support the local-first guarantee by keeping data on-device.

### Domain Layer (models)

- Represent core business concepts.
- Contain no UI or persistence logic.
- Remain plain, serializable data structures.

### Provider Layer (providers)

- Encapsulate external integrations (YouTube metadata, transcripts).
- Define abstract contracts for external communication.
- Provider-specific DTOs stay separate from domain models.
- Repositories never communicate directly with external services (ADR-008).

---

## Providers

### YoutubeProvider — IMPLEMENTED (Phase 008, abstraction only)

- Abstract contract for communication with YouTube.
- Methods: `getVideoMetadata()`, `getAvailableTranscripts()`, `downloadTranscript()`.
- No implementation, no networking.
- Future concrete providers will implement this interface.

### YoutubeVideoMetadata — IMPLEMENTED (Phase 008, DTO)

- Provider-specific metadata DTO: videoId, title, channelName, publishedAt, duration, description.
- Immutable; JSON serialization/deserialization, `copyWith()`, equality, readable `toString()`.

### YoutubeTranscriptInfo — IMPLEMENTED (Phase 008, DTO)

- Provider-specific transcript track DTO: language, isManual, languageName.
- Reuses the domain `TranscriptLanguage` enum.
- Immutable; JSON serialization/deserialization, `copyWith()`, equality, readable `toString()`.

### YoutubeTranscript — IMPLEMENTED (Phase 008, DTO)

- Provider-specific transcript DTO: videoId, info, timestamped segments.
- Nested `YoutubeTranscriptSegment` DTO with offset, duration, text.
- Immutable; JSON serialization/deserialization, `copyWith()`, equality, readable `toString()`.

---

## Services

### PromptService — IMPLEMENTED (Phase 005)

- Full prompt business logic implementation.
- Public API: `getAllPrompts()`, `getPrompt(id)`, `createPrompt()`, `updatePrompt()`, `deletePrompt()`.
- Business rules:
  - Trims title and content.
  - Rejects empty / whitespace-only title or content (`PromptValidationException`).
  - Generates UUID v4 ids inside the service (repository never generates ids).
  - Sets `createdAt`/`updatedAt` automatically; refreshes `updatedAt` on update.
  - Throws `PromptNotFoundException` for missing ids.
  - Keeps storage exceptions hidden behind domain exceptions.
- The UI must never communicate directly with repositories — always via this service.

### YouTubeUrlParser — IMPLEMENTED (Phase 007)

- Validates supported YouTube URL formats.
- Extracts canonical video IDs (11-char `[A-Za-z0-9_-]`).
- Normalizes URLs to `https://www.youtube.com/watch?v=VIDEO_ID` (ADR-007).
- Supports `www.youtube.com/watch`, `youtube.com/watch`, `m.youtube.com/watch`, `youtu.be/...`, and URLs with extra query parameters.
- Rejects unsupported/malformed URLs with `InvalidYouTubeUrlException`.
- Independent from Flutter UI and networking.

### YouTubeService — PLANNED

- Validates YouTube URLs (up to three per run) using `YouTubeUrlParser`.
- Fetches video metadata, including publication date (Phase 007+).
- Resolves the video identifier used for history tracking.

### VideoService — IMPLEMENTED (Phase 006, skeleton only)

- Public API established: `getAllVideos()`, `getVideoByVideoId()`, `hasBeenUsed()`.
- Depends on `VideoRepository` abstraction.
- No business logic yet — implementations arrive in Phase 007.

### TranscriptService

- Downloads transcripts for given YouTube videos.
- Selects the best available transcript in this order:
  1. manual Polish
  2. automatic Polish
  3. manual English
  4. automatic English
  5. any available transcript
- Determines when no transcript exists and signals the need for optional Whisper transcription.

### OutputBuilder

- Assembles the final copy-ready text block.
- Combines the selected prompt, an inspiration section, and the transcript section.
- Applies transcript cleanup rules (timestamp removal) before assembling output.

### StorageService

- Abstracts local persistence primitives (file system, database).
- Provides storage access to repositories.
- Guarantees the local-first data model.

### JsonPromptStorage — IMPLEMENTED (Phase 004)

- Owns the `prompts.json` file path and platform application support directory.
- macOS default: `~/Library/Application Support/context_forge/prompts.json`.
- Reads and writes human-readable, indented JSON.
- Auto-creates the file with an empty list (`[]`) when missing.
- Returns empty defaults on empty or corrupt files.
- Optional `directoryPath` override (used by tests).
- No third-party storage packages used (dart:io + dart:convert only).

### SettingsService

- Manages application-level settings.
- Persists user preferences through the SettingsRepository.
- Exposes settings state to the UI.

### HistoryService

- Tracks which videos have already been used.
- Determines new vs. previously used status.
- Persists history through the VideoHistoryRepository.

---

## Repositories

### VideoRepository — IMPLEMENTED (Phase 006, contract only)

- Abstract contract: `getAll()`, `getByVideoId()`, `save()`, `delete()`.
- No storage implementation; storage for videos arrives in later phases.

### PromptRepository — IMPLEMENTED (Phase 003, contract only)

- Persists saved prompt templates locally.
- Provides CRUD operations for prompts.
- Defined as an abstract contract; no storage implementation yet.

### JsonPromptRepository — IMPLEMENTED (Phase 004)

- Concrete [`PromptRepository`] implementation backed by human-readable JSON.
- Delegates all filesystem details to [JsonPromptStorage].
- Handles missing, empty, and invalid JSON files gracefully (returns safe defaults).

### VideoHistoryRepository

- Persists video usage history locally.
- Answers whether a given video has been used before.

### TranscriptCacheRepository

- Caches downloaded transcripts locally.
- Avoids redundant transcript downloads.

### SettingsRepository

- Persists application settings locally.
- Loads saved settings on startup.

---

## Models

### Prompt — IMPLEMENTED (Phase 003)

- A saved or custom prompt template.
- Contains the prompt text and metadata (title, rating in later phases).
- Immutable; supports JSON serialization/deserialization, `copyWith()`, equality, and readable `toString()`.

### Video — IMPLEMENTED (Phase 006)

- Represents a YouTube video referenced in the workflow.
- Contains: id, url, videoId, title, channelName, publishedAt, transcriptLanguage, transcriptAvailable, createdAt, updatedAt.
- Immutable; all timestamps are `DateTime` (UTC).
- JSON serialization/deserialization, `copyWith()`, equality, readable `toString()`.
- Independent of any external API.

### TranscriptLanguage — IMPLEMENTED (Phase 006)

- Enum: `polish`, `polishAuto`, `english`, `englishAuto`, `other`, `none`.
- Used instead of strings throughout the application.
- Provides human-readable `label` values.

### Transcript

- Represents a downloaded transcript.
- Records the transcript text, language, manual/automatic origin, and source video.

### OutputDocument

- The generated copy-ready text block.
- Contains the selected prompt, inspiration section, and transcript section.

### ApplicationSettings

- User-configurable application preferences.
- Persisted locally via SettingsRepository.

### VideoHistoryEntry

- Records that a specific video was used on a given date.
- Backs the green/new vs. blue/previously-used indicator.

---

## Planned Widgets

### PromptSelector

- Lists saved prompt templates for selection.
- Dispatches selection to PromptService.

### PromptEditor

- Edits the current prompt text.
- Supports custom prompt authoring.

### VideoInputCard

- Collects YouTube URLs (up to three).
- Dispatches URL validation to YouTubeService.

### TranscriptStatusIndicator

- Displays green = new video or blue = previously used video.
- Reflects HistoryService state per video.

### OutputPreview

- Shows the generated copy-ready text block.
- Preview of the selected prompt, inspiration section, and transcript section.

### GenerateButton

- Triggers the generate workflow.
- Coordinates services to produce the OutputDocument.

---

## Architecture Principles (High-Level)

- **Local-first by default:** all data lives on the user's machine.
- **Layered separation:** widgets → services → repositories → models.
- **Dependency direction:** higher layers depend on lower layers; never the reverse.
- **Testability:** services and repositories are designed to be testable in isolation.
- **Documentation-driven:** architecture decisions are recorded in `docs/DECISIONS.md` and evolved phase by phase.

## Platform Support

- Primary target: macOS (desktop).
- The layered architecture keeps the door open for future desktop platforms (Linux, Windows) without restructuring.