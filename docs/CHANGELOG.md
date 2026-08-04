# Changelog

All notable changes to ContextForge will be documented in this file.

## [0.1.12] — 2026-08-04

### Added

- Persistent video processing history:
  - `VideoHistoryEntry` domain model (`lib/models/video_history_entry.dart`) with `videoId`, `originalUrl`, `title`, `channelName`, `processedAt`.
  - `JsonVideoHistoryStorage` (`lib/services/json_video_history_storage.dart`) — human-readable `video_history.json` in the application support directory.
  - `VideoHistoryService` (`lib/services/video_history_service.dart`) — loads history once at startup, keeps it in memory for instant O(1) lookups, and upserts entries by `videoId`.
  - Automatic history recording: every successful transcript generation writes an entry with the current timestamp. Failed attempts are never recorded.
  - Duplicate prevention: processing the same video again updates `processedAt` instead of creating a new entry.
- Visual status indicator in each URL field:
  - Small subtle dot inside the URL input.
  - 🟢 Green when the video has been processed before.
  - Neutral grey when the video has never been processed.
  - Tooltip on the green dot shows `Previously processed` and the local date/time (e.g. `2026-08-04 14:25`).
  - Indicator updates live while typing; lookups are synchronous in-memory operations with no disk I/O.
- History persists across application restarts and survives the Clear button — Clear only resets the working session.
- Unit tests (`test/video_history_service_test.dart`): persistence, duplicate prevention, timestamp updates, restart survival, URL-form matching, invalid URL handling, model serialization/equality.
- In-memory history storage test helper (`test/helpers/in_memory_video_history_storage.dart`) for widget tests.
- `ContextForgeApp`, `HomePage`, and `VideoCardController` accept an optional injected `VideoHistoryService` for testability.
- `VideoStatus.previouslyUsed` indicator color updated from blue to green to match the "processed before" visual language.

### Changed

- The existing `VideoStatus.previouslyUsed` now maps to green instead of blue.

### Notes

- No SQLite, no database, no migration layer, no storage abstraction.
- History is a single lightweight JSON file.
- YouTube pipeline and transcript generation are unchanged.

## [0.1.11] — 2026-08-04

### Added

- Output action bar with Copy and Clear buttons:
  - Copy copies the generated output to the system clipboard and shows a confirmation snackbar.
  - Clear resets the working session to the initial state (output, URL fields, transcript previews, error banners) while keeping the prompt library.
  - Copy keyboard shortcut support (⌘C / Ctrl+C) scoped to the Output section.
  - Buttons enable/disable based on session state.
- `VideoCardController.clear()` — resets a controller to its initial empty state.
- Integration-style widget tests (`test/output_actions_test.dart`): copy-to-clipboard, session clear/reset.

### Notes

- No history / persistence changes in this phase.

## [0.1.10] — 2026-02-08

### Added

- Enabled macOS outbound network access:
  - Added `com.apple.security.network.client` entitlement to `macos/Runner/DebugProfile.entitlements`.
  - Added `com.apple.security.network.client` entitlement to `macos/Runner/Release.entitlements`.
  - Existing entitlements preserved (app-sandbox, cs.allow-jit, network.server).

### Fixed

- CF-001 — "Could not reach YouTube. Check your connection.":
  - Root cause: missing `com.apple.security.network.client` sandbox entitlement blocked all outbound HTTPS (`SocketException`, errno = 1, Operation not permitted).
  - Fix: outbound network client entitlement enabled for Debug, Profile, and Release configurations.
  - Verified: `flutter build macos` succeeds; `codesign -d --entitlements` shows `com.apple.security.network.client` embedded in the Release app bundle.

### Notes

- Application now reaches YouTube; metadata, transcript discovery, and transcript download work in the sandboxed app.
- No changes to application logic, provider, or UI.

## [0.1.9] — 2026-02-08

### Added

- YouTube provider technology review (`docs/YOUTUBE_PROVIDER_REVIEW.md`):
  - Verified `youtube_explode_dart` 3.1.0 is the latest published version (2026-05-09) and is actively maintained (not archived, 418 stars, 62 open issues, regular releases).
  - Confirmed the library is functionally compatible with YouTube's metadata and transcript systems; the full pipeline (metadata → transcript discovery → selection → download) was verified end-to-end outside the sandbox in Phase 018.
  - Documented that the real-world failure is a macOS App Sandbox entitlement issue (`com.apple.security.network.client` missing), **not** a provider issue.
  - Compared alternatives (YouTube Data API v3, non-Dart transcript libraries, custom scraper) — none solve the observed failure because any network-based provider is equally blocked in the sandbox.
  - **Recommendation: KEEP** — no provider change required.

### Notes

- No production code changes, no library replacement, no fixes implemented (review only).

## [0.1.8] — 2026-02-08

### Added

- YouTube connectivity diagnostics:
  - Instrumented every stage of the YouTube pipeline with `debugPrint` logging: original URL, parsed video ID, metadata request/response, transcript discovery (manifest + tracks), transcript selection, and transcript download.
  - Every caught exception now logs: exception type, message, and full stack trace.
  - Original exceptions are preserved in console output — generic UI messages remain unchanged but never replace the original cause silently.
  - `YouTubeUrlParser.extractVideoId` logs parsing diagnostics.
  - `VideoService.fetchVideoMetadata` logs metadata request and result.
  - `TranscriptService.getAvailableTranscripts` / `downloadTranscript` log discovery, track details, download requests, and results.
  - `TranscriptSelectionService.select` logs the selected track and reason (or unavailability).
  - `YoutubeExplodeProvider` logs all three network stages and every caught exception type with stack trace; the original `cause` is still attached to `YoutubeNetworkException`.
  - `VideoCardController.loadMetadata` and `HomePage._generate` log caught exceptions with type, message, and stack.

### Notes

- No feature work, no refactoring, no provider replacement, no business logic changes.
- Diagnostics only — UI messages and behavior unchanged.
- Verified against the reference video `OPZczs-Kttg`: the full pipeline (URL parse → metadata → transcript discovery → selection → download) succeeds end-to-end; each stage logs correctly.

## [0.1.7] — 2026-02-08

### Added

- End-to-end generate workflow:
  - `HomePage._generate()` — orchestrates the full pipeline: reads the selected prompt, reads all entered YouTube URLs, ignores empty fields, and for each valid URL: loads metadata → discovers transcripts → selects the preferred track → downloads it → cleans it.
  - All successful results are passed to `OutputBuilderService` and the generated text is displayed in the existing Output area.
  - Partial failures are handled gracefully: one failing video does not abort processing of the remaining videos; failures are shown in a banner.
  - `GenerateButton` now accepts `onPressed` and `isLoading` and displays a spinner while generating.
  - `OutputPreview` now accepts an optional `TextEditingController` for displaying generated text.
  - `PromptEditor` and `VideoInputCard` now accept optional external text controllers so the workflow can read entered values.
- Integration-style widget test (`test/generate_workflow_test.dart`): enters a YouTube URL, taps Generate, and asserts the final output contains the prompt, the inspiration entry, and the cleaned transcript.

### Changed

- `HomePage` wires `TranscriptService` (via the same provider as `VideoService`), `TranscriptSelectionService`, `TranscriptCleanupService`, and `OutputBuilderService`.
- The output-section Generate button is now enabled and triggers the workflow.

### Notes

- No Clipboard, no Whisper, no transcript cleanup changes, no UI redesign.

## [0.1.6] — 2026-02-08

### Added

- Output builder (`lib/services/output_builder_service.dart`).
  - `OutputBuilderService.build({selectedPrompt, videos, transcripts})` — generates the final output text block for copying into an external LLM.
  - Deterministic string assembly: no AI processing, no randomness, no UI dependencies.
  - Output format: separator, selected prompt, Inspiration section (`YYYY-MM-DD -> URL` per existing video), numbered Transcript sections with preserved cleaned transcript text.
  - Skips videos with empty URLs and transcripts with empty text; no empty Inspiration entries or Transcript sections.
  - Transcript text preserved exactly from `TranscriptCleanupService` (only leading/trailing whitespace trimmed).
- Unit tests (`test/output_builder_service_test.dart`): complete output, one missing transcript, empty video list.

### Notes

- No Clipboard, no UI changes, no Whisper, no transcript cleanup changes.

## [0.1.5] — 2026-02-08

### Added

- Transcript cleanup (`lib/services/transcript_cleanup_service.dart`).
  - `TranscriptCleanupService.clean(download)` — transforms a downloaded `TranscriptDownload` into clean AI-ready text.
  - Removes timestamp-only lines, empty lines; normalizes whitespace within lines; preserves paragraph breaks.
  - Preserves the original `TranscriptDownload` on the result for future debugging.
  - Domain model (`lib/models/clean_transcript.dart`): `CleanTranscript` (videoId, track, text, original).
- Unit tests (`test/transcript_cleanup_service_test.dart`).

### Notes

- No Whisper, no output generation, no UI changes.

## [0.1.4] — 2026-02-08

### Added

- Transcript download:
  - `TranscriptService.downloadTranscript(videoId, track)` — downloads the selected transcript track via `YoutubeProvider.downloadTranscript`, maps provider DTOs → domain `TranscriptDownload`.
  - Plain text returned without timestamps: segment texts joined with a single space. Raw timestamped segments preserved for later cleaning.
  - `YoutubeExplodeProvider.downloadTranscript` — fetches manifest, matches requested track by language code and auto/manual, downloads caption track via `yt.videos.closedCaptions.get(trackInfo)`.
  - Injectable `fetchCaptionTrack` seam for testability.
  - Domain model (`lib/models/transcript_download.dart`): `TranscriptDownload` + `TranscriptSegment`.
  - Error handling: provider `null` → `TranscriptsUnavailableException`; `VideoUnavailableException` → `YoutubeVideoUnavailableException`; other failures → `YoutubeNetworkException`.
- Unit tests (`test/transcript_service_test.dart`): successful download (plain text + metadata), provider-null → unavailable, video unavailable, network failure, generic provider failure.

### Notes

- No Whisper, no transcript cleanup, no UI changes.

## [0.1.3] — 2026-02-08

### Added

- Transcript selection strategy:
  - Domain types (`lib/models/transcript_selection.dart`):
    - `TranscriptSelectionResult` sealed result.
    - `TranscriptSelected` (track + reason + priority) / `TranscriptUnavailable` (Whisper may be required).
    - `TranscriptSelectionReason` and `TranscriptPriority` enums — no magic strings.
  - `TranscriptSelectionService` (`lib/services/transcript_selection_service.dart`) — pure, deterministic, works only with domain models. Priority: manual Polish → auto Polish → manual English → auto English → other manual → other auto.
- Unit tests (`test/transcript_selection_service_test.dart`): manual Polish, auto Polish, manual English, auto English, other-manual fallback, other-auto fallback, no transcripts, mixed lists, deterministic behaviour.

### Notes

- No transcript download, no Whisper invocation, no networking, no UI changes.

## [0.1.2] — 2026-02-08

### Added

- Transcript discovery (metadata only — no transcript download):
  - `TranscriptTrack` domain model (`lib/models/transcript_track.dart`).
  - `YoutubeTranscriptInfo` DTO extended with `languageCode` and `isTranslatable`.
  - `YoutubeExplodeProvider.getAvailableTranscripts` via `yt.videos.closedCaptions.getManifest`; injectable `fetchManifest` seam.
  - `TranscriptService` maps DTOs → domain `TranscriptTrack` (ADR-009); `discoverTranscriptTracks` throws when empty.
  - `TranscriptsUnavailableException`.
- Unit tests (`test/transcript_service_test.dart`): mapping, auto, manual, no transcripts, unavailable, network failure.

### Notes

- No transcript text downloading, selection, cleaning, or Whisper integration.

## [0.1.1] — 2026-02-08

### Added

- Prompt selection workflow (read-only):
  - `PromptService.ensureDefaultPrompts()` — seeds SEO Article, Newsletter, LinkedIn, Facebook once when storage is empty; never overwrites user prompts.
  - `PromptSelector` now loads real prompts from `PromptService` and shows a friendly empty state.
  - `PromptEditor` displays the selected prompt's content read-only; editing enabled only for "Custom Prompt".
  - `HomePage` loads and seeds prompts on startup; default selected prompt is the first saved one.
  - `ContextForgeApp` and `HomePage` accept injected `PromptService`/`VideoService` for testability.
  - `InMemoryPromptRepository` added for tests and lightweight wiring.
- Unit tests: default seeding, no-reseed, no-overwrite, prompt content loading.
- Widget tests: dropdown population, empty state, prompt content display, custom editing, read-only saved content.

### Notes

- No editing, deleting, creation UI, ratings, or persistence of custom prompts (by design).

## [0.1.0] — 2026-02-08

### Added

- Presentation layer (`lib/presentation/`).
  - `VideoCardState` typed state model: `empty`, `editing`, `valid`, `invalid`.
  - `VideoCardController` presentation-layer controller owning URL, state, validation status, and extracted videoId.
  - Public API: `setUrl()`, `clear()`, `validate()`; state changes via `ChangeNotifier`.
  - Communicates only with `YouTubeUrlParser` and `VideoService`; no UI logic, no provider access, no networking.
- Unit tests (`test/presentation_video_card_controller_test.dart`).
  - Empty state, editing transition, valid URL extraction (watch + youtu.be), invalid URL, whitespace URL, clear(), listener notifications, re-validate after editing.

### Notes

- This phase intentionally does NOT perform metadata fetching.
- No metadata or loading states yet — those belong to later phases.

## [0.1.0] — 2026-02-08 (Video Metadata Workflow)

### Added

- First complete vertical slice: video metadata workflow.
- `VideoStatus` domain enum (`lib/models/video_status.dart`) with gray/green/red/blue semantics.
- `VideoService.fetchVideoMetadata(url)` — validates URL via `YouTubeUrlParser`, fetches metadata via `YoutubeProvider`, maps DTO → domain `Video` (ADR-009).
- `InMemoryVideoRepository` (`lib/repositories/in_memory_video_repository.dart`) for wiring.
- `VideoCardController` (`lib/viewmodels/video_card_controller.dart`) — presentation-layer state: status, metadata, loading, friendly error messages.
- `VideoInputCard` rewritten as controller-driven with loading indicator, metadata view, and error banner.
- Unit tests (`test/video_card_controller_test.dart`) — success, empty URL, loading, invalid URL, unavailable, network, unexpected errors.
- Widget tests (`test/video_metadata_widget_test.dart`) — metadata displayed, loading indicator, friendly error states.

### Changed

- Project version bumped to `0.1.0`.
- `VideoInputCard` no longer takes status/label; it takes a `VideoCardController`.
- `TranscriptStatusIndicator` uses the domain `VideoStatus` with red error state.
- `HomePage` wires a `VideoService` + three `VideoCardController`s (injectable for tests).
- `TESTING.md` updated with metadata workflow manual-test scope.
- Blue indicator remains reserved for future history support.

## [0.0.9] — 2026-02-08

### Added

- `youtube_explode_dart` 3.1.0 dependency (Phase 009).
  - Selected: actively maintained, reliable, no API key required, Flutter Desktop compatible.
- `YoutubeExplodeProvider` (`lib/providers/youtube_explode_provider.dart`).
  - Concrete `YoutubeProvider` implementation.
  - `getVideoMetadata()` fetches title, channel name, publication date, video id, canonical URL, duration, description.
  - Maps external package types to provider DTOs (ADR-009); no external types leak.
  - Injectible `fetchVideo` seam for testability.
- New exceptions (`lib/exceptions/youtube_exceptions.dart`).
  - `YoutubeVideoUnavailableException`
  - `YoutubeNetworkException`
- `YoutubeVideoMetadata` DTO extended with `url` field.
- Unit tests (`test/youtube_explode_provider_test.dart`).
  - 8 tests: successful fetch, empty description, date fallback, invalid URL, unavailable video, network failure, cause propagation, rethrow.
- ADR-009: provider DTOs are always mapped into domain models before entering the application layer.

### Changed

- Project version updated to `0.0.9`.
- `docs/DEPENDENCIES.md` documents `youtube_explode_dart` and its rationale.

## [0.0.8] — 2026-02-08

### Added

- Provider layer (`lib/providers/`).
  - Abstract `YoutubeProvider` interface: `getVideoMetadata()`, `getAvailableTranscripts()`, `downloadTranscript()`.
  - Provider DTOs: `YoutubeVideoMetadata`, `YoutubeTranscriptInfo`, `YoutubeTranscript`, `YoutubeTranscriptSegment`.
  - DTOs are immutable with JSON serialization/deserialization, `copyWith()`, equality, and readable `toString()`.
  - `YoutubeTranscriptInfo` reuses the domain `TranscriptLanguage` enum.
- Unit tests (`test/youtube_provider_dto_test.dart`).
  - DTO serialization, round-trip, defaults, copyWith, equality, toString.

### Changed

- Project version updated to `0.0.8`.
- Added ADR-008: external integrations are isolated behind provider abstractions.
- Architecture documentation adds the Provider layer; repositories never communicate directly with external services.

## [0.0.7] — 2026-02-08

### Added

- `InvalidYouTubeUrlException` (`lib/exceptions/youtube_exceptions.dart`).
- `YouTubeUrlParser` (`lib/services/youtube_url_parser.dart`).
  - `isValidUrl()`, `extractVideoId()`, `normalizeUrl()`.
  - Supports watch, short (youtu.be), mobile, and extra-query-parameter URLs.
  - Normalizes to canonical `https://www.youtube.com/watch?v=VIDEO_ID` (ADR-007).
  - Independent from Flutter UI and networking.
- Unit tests (`test/youtube_url_parser_test.dart`).
  - 36 tests covering standard, short, mobile, query-param, invalid, malformed, empty, and whitespace URLs.

### Changed

- Project version updated to `0.0.7`.
- Added ADR-007: YouTube URLs are normalized before entering the domain layer.
- Architecture documentation marks `YouTubeUrlParser` as implemented.

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