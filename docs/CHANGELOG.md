# Changelog

All notable changes to ContextForge will be documented in this file.

## [0.1.17] — 2026-08-04 (030)

### Added

- Localization: English (default), Polish, Spanish.
- App follows macOS system language automatically.
- Starter prompts: Instagram Post, X/Twitter Thread, Facebook Post, LinkedIn Article, Executive Summary, Study Notes, Podcast Notes, Meeting Brief, Key Takeaways.
- AI quick links: ChatGPT, Gemini, Claude, DeepSeek — opens official web apps via default browser.
- URL canonicalization: playback parameters (t, si, feature, pp) stripped.

### Notes

- No API integration.

## [0.1.17] — 2026-08-04 (029E)

### Added

- Informational footer:
  - ⓘ About — version, description, Flutter, SODA methodology.
  - ⌨ Shortcuts — documents ⌘V, ⌘R, ⌘C.
  - ❓ Help — step-by-step workflow guide + Quick Access explanation.
- URL normalization:
  - Pasted YouTube URLs are normalized to canonical form, removing playback-only parameters (e.g. `https://www.youtube.com/watch?v=ID&t=4841s` → `https://www.youtube.com/watch?v=ID`).
- First-time user discoverability.

### Notes

- No new product features.

## [0.1.17] — 2026-08-04 (029D Final)

### Verified

- **Keyboard consistency:**
  - ⌘V Smart Paste — inserts clipboard YouTube URL into first empty slot.
  - ⌘C — native copy when text selected; full-output copy when no selection.
  - ⌘R — runs Generate, reusing the exact same action as the Generate button.
- **Button state consistency:**
  - Clipboard buttons enabled only when clipboard contains a valid YouTube URL.
  - Generate enabled only when generation is possible.
  - Copy enabled only when generated output exists.
  - ⚡ remains disabled until Quick Workflow is implemented.
- **Prompt Library consistency:**
  - Create, edit, delete, favorite, default, and Quick Access assignment all refresh immediately.
- **Command Bar consistency:**
  - Equal spacing, visually centered ⚡, identical button sizing, native hover feedback.
- **Complete workflow validation:** Clipboard → Paste → Prompt selection → Generate → Copy behaves naturally.

### Notes

- No new functionality — workflow finalization only.

## [0.1.17] — 2026-08-04 (029D)

### Added

- Prompt Library Completion:
  - ➕ New Prompt button with explicit Save / Cancel workflow.
  - Edit dialog for changing title and content.
  - Delete with confirmation dialog that explains any assigned role (Default, ⚡, ①, ②, ③).
  - Friendly empty state with "Create your first prompt" button.
  - All modifications refresh immediately.
- `PromptManager` widget handles the complete user-managed Prompt Library.
- `PromptSelector` items now include edit (✏) and delete (🗑) icons.

### Notes

- No special "built-in" prompts.
- Users own the library.

## [0.1.17] — 2026-08-04 (029C)

### Added

- **⌘R Generate shortcut** — equivalent to pressing Generate; reuses the existing Generate action with the same enable/disable logic.
- Prompt Library refresh:
  - Favorite, Default, ⚡, ①, ②, ③ assignments now refresh the expanded Prompt Library immediately.
  - No collapsing/reopening required.
- Clipboard button refresh:
  - Revalidates clipboard contents whenever ContextForge becomes the active application.
  - Enables/disables clipboard buttons immediately.
  - Uses native window activation notifications (WidgetsBindingObserver) — no polling.
- Command Bar polish:
  - Clear hover feedback via tooltips.
  - Improved spacing and alignment.
  - Every icon clearly looks clickable.

### Notes

- Workflow friction removal only.
- No new product features.

## [0.1.17] — 2026-08-04 (029B)

### Added

- Immediate UI refresh:
  - Quick Access assignment and Favorite/Default changes now refresh the Prompt Library immediately.
  - No need to collapse and reopen the prompt selector to see updated icons.
- Generate availability:
  - Generate is now disabled when there are no valid YouTube URLs or nothing to generate.
  - Enables automatically once at least one valid video exists in a slot.
- Clipboard refresh on window activation:
  - Uses `WidgetsBindingObserver.didChangeAppLifecycleState` to refresh clipboard availability when the application window becomes active.
  - No continuous polling.
- Command Bar polish:
  - ⚡ centered.
  - Improved spacing and alignment.
  - Every command button now visually indicates clickability with surface background and border.
  - Native macOS appearance preserved.

### Notes

- Workflow friction removal only.
- Existing controls unchanged.

## [0.1.17] — 2026-08-04 (029A)

### Added

- Smart Paste fixed:
  - Field clipboard icon now replaces the URL in THAT field only.
  - Global ⌘V Smart Paste inserts into the first empty slot only.
  - Duplicate detection rejects same video ID with "Already added".
- Quick Access prompt roles:
  - Bookmark icon repurposed to open a Quick Access menu (None, ⚡ Quick Workflow, ① Slot One, ② Slot Two, ③ Slot Three).
  - A prompt may be assigned to exactly one role.
  - Command bar slots now use quick access roles instead of first-N prompts.
- Favorites state machine:
  - ☆ Normal → ★ Favorite → 🌟 Favorite + Default → ☆ Normal.
  - Default always implies Favorite; Default without Favorite never exists.
  - Un-favoriting a Default removes the Default too.
- Generate reuses cached metadata/transcripts when available.
- ⌘C behavior: copies entire output when no text selection, native behavior when selection exists.
- Keyboard shortcuts verified: ⌘↩ Generate, ⌘⌫ Clear, ⌘⇧S Export, ⌘C Copy, ⌘V Smart Paste, Escape unfocus.

### Notes

- Workflow friction removal only — no feature expansion.
- Existing controls unchanged.
- Prompt roles persisted via `prompts.json` (new `quickAccess` field).

## [0.1.17] — 2026-08-04

### Added

- Command Bar:
  - Compact three-row command bar in the top-right corner of the header.
  - Designed as the primary control surface for power users — reduces mouse movement during repetitive daily work.
- Row 1 — Quick Workflow (⚡):
  - Reserved for future automation.
  - Button displayed but disabled this phase.
  - Tooltip: "Quick Workflow (coming soon)".
- Row 2 — Quick Prompt Selection (① ② ③):
  - Segmented-control behavior — selecting one slot immediately changes the currently selected prompt.
  - Only one button is active at a time.
  - Slots are populated from the first three saved prompts (after favorites sorting).
  - If no prompt is assigned to a slot, that button is disabled.
- Row 3 — Actions:
  - 📋 Paste — uses Smart Paste (inserts clipboard YouTube URL into the first empty slot).
  - 🔄 Generate — starts generation immediately, replacing existing output without confirmation.
  - 📄 Copy — copies the generated output; disabled when output is empty.
- `CommandBar` widget (`lib/widgets/command_bar.dart`) — modular, designed for future extension.
- Tests (`test/command_bar_test.dart`): all three rows render, quick prompt selection changes the selected prompt, Generate works from the command bar, Copy disables correctly, Paste performs Smart Paste.

### Notes

- Existing controls (Prompt selector, URL fields, Output section buttons, keyboard shortcuts) are unchanged.
- The command bar is an additional workflow, not a replacement.

## [0.1.16] — 2026-08-04

### Added

- Smart Clipboard Workflow:
  - **⌘V Smart Paste** — when the clipboard contains a valid YouTube URL, automatically inserts it into the first empty URL field, does not overwrite existing URLs, and immediately validates the URL.
  - **Duplicate detection** — if the same video ID already exists in any slot, the Smart Paste is rejected and a lightweight `Already added` notification appears (auto-dismisses after 2 seconds).
  - **Clipboard button** — each URL field now includes a small clipboard icon (`Icons.content_paste`) that performs the same Smart Paste action. The button is enabled only when the clipboard currently contains a valid YouTube URL; disabled otherwise. The clipboard state is refreshed on startup and after Clear.
- Compact URL presentation:
  - After successful validation, the URL field displays a compact representation: `▶ VIDEO_ID` (e.g. `▶ BLsQ1RhVRAQ`) in monospace bold.
  - The complete original URL is kept internally via `VideoCardController.fullUrl` and is used for all pipeline operations (Generate, Enter navigation, duplicate checks).
  - Hovering over the field shows the complete original URL via a Tooltip.
- Existing behaviour unchanged:
  - Manual typing and pasting into URL fields still works normally.
  - Manual URL entry still validates through `loadMetadata`.
- `VideoCardController.refreshHistoryStatus` now keys on the canonical `videoId` when a video is loaded, so the green/neutral history dot survives the compact display.

### Notes

- No background clipboard monitoring — the clipboard is only read on user-initiated actions (Smart Paste, startup, Clear).
- No automatic notifications without user action.

## [0.1.15] — 2026-08-04

### Added

- Keyboard workflow:
  - **⌘↩ Generate** — triggers output generation from anywhere in the app.
  - **⌘⌫ Clear** — resets the current session.
  - **⌘⇧S Export Markdown** — opens the native Save dialog.
  - **⌘C Copy** — verified consistent when the Output section has focus (existing behaviour).
  - **Escape** — removes keyboard focus.
- Enter-in-URL-field navigation:
  - Enter in URL field 1 moves focus to URL field 2.
  - Enter in URL field 2 moves focus to URL field 3.
  - Enter in the last URL field triggers Generate.
- Focus navigation:
  - `VideoInputCard` now accepts external `focusNode`, `onSubmitted`, and `textInputAction` for keyboard-driven tab ordering (Prompt → URL 1 → URL 2 → URL 3 → Generate → Output → Copy → Export).
- `HomePage` uses global `Shortcuts`/`Actions` for app-level keyboard shortcuts and wraps buttons in `Focus` nodes for natural tab order.

### Changed

- `VideoInputCard.onSubmitted` now delegates to an external handler when provided (previously always called `loadMetadata` directly), enabling Enter-to-next-field navigation.

### Notes

- No business features or architecture changes — keyboard shortcut support only.
- Existing mouse/touch workflows are unchanged.

## [0.1.14] — 2026-08-04

### Added

- Export as Markdown:
  - New `Export Markdown` action next to Copy and Clear in the Output section.
  - Opens the native macOS Save dialog via `file_selector` (`getSaveLocation`).
  - Default filename: `ContextForge-YYYY-MM-DD-HHMM.md`.
  - Writes the generated output exactly as displayed — headings, spacing, blank lines, and formatting are preserved byte-for-byte.
  - UTF-8 encoding.
  - Shows a lightweight `Markdown exported.` snackbar confirmation after a successful save.
- `MarkdownExportService` (`lib/services/markdown_export_service.dart`):
  - `defaultFileName()` — builds the `ContextForge-YYYY-MM-DD-HHMM.md` filename.
  - `exportMarkdown(content)` — opens the native Save dialog and writes UTF-8 Markdown; returns `true` on success, `false` when the user cancels.
- macOS entitlements:
  - Added `com.apple.security.files.user-selected.read-write` to `DebugProfile.entitlements` and `Release.entitlements` so the sandboxed app can write to user-selected locations.
- Dependency: `file_selector` added for native Save dialog support.
- Unit tests (`test/markdown_export_service_test.dart`): filename pattern, zero-padding of single-digit values, default local-time filename.

### Notes

- Transcript generation and the UI design are unchanged.
- Export writes the output text verbatim — no Markdown conversion or transformation is applied.

## [0.1.13] — 2026-08-04

### Added

- Prompt Favorites:
  - Each prompt can be marked as a Favorite via a subtle star icon in the prompt dropdown.
  - Filled star = Favorite; outlined star = not a favorite.
  - Favorites always appear at the top of the prompt list.
  - Within Favorites, the manual (stored) ordering is preserved.
- Default Prompt:
  - Exactly one prompt can be marked as the Default via the bookmark control in the prompt dropdown.
  - The Default Prompt is automatically selected when the application starts.
  - When no Default exists, the current behaviour is kept (first saved prompt is selected).
  - Removing the Default restores the previous behaviour.
  - The Default Prompt displays a small "Default" badge.
- Persistence:
  - `isFavorite` and `isDefault` fields added to the `Prompt` model (`lib/models/prompt.dart`).
  - Existing JSON storage formats remain readable — missing `isFavorite` / `isDefault` keys default to `false`.
  - No new storage layer, no database; reuses the existing `prompts.json` storage.
- Service APIs:
  - `PromptService.getAllPrompts()` now returns prompts with Favorites first (manual order preserved within groups).
  - `PromptService.setFavorite(id, bool)` — toggles favorite state.
  - `PromptService.setDefault(id)` — marks a prompt as the single Default (clearing any previous one).
  - `PromptService.clearDefault(id)` — removes the Default designation.
  - `PromptService.getDefaultPrompt()` — returns the current Default, or `null`.
- `PromptSelector` accepts optional `onToggleFavorite` and `onToggleDefault` callbacks for interactive star and default controls.
- `HomePage` auto-selects the Default Prompt on launch and wires the favorite/default toggle callbacks.
- Tests: model serialization for new fields, favorites-first ordering, favorite/default persistence across restart, single-default enforcement, default clearing, widget tests for star icons and the Default badge.

### Notes

- No dialogs, no extra configuration screens, no UI redesign.
- The prompt editor and transcript generation are unchanged.

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