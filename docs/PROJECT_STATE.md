# Project State — ContextForge

| Field               | Value                                 |
| ------------------- | ------------------------------------- |
| **Current Version** | 0.1.4                                 |
| **Current Phase**   | 014                                   |
| **Status**          | Transcript download implemented       |
| **Current Milestone** | Transcript Download                 |

## Phase Tracking

| Phase | Title                                     | Status    |
| ----- | ----------------------------------------- | --------- |
| 001   | Project Bootstrap & Documentation         | Completed |
| 001A  | Documentation Alignment                   | Completed |
| 002   | Main Window                               | Completed |
| 003   | Prompt Domain Foundation                  | Completed |
| 004   | Prompt Local Storage                      | Completed |
| 005   | Prompt Service Implementation             | Completed |
| 006   | Video Domain Foundation                   | Completed |
| 007   | YouTube URL Parser                        | Completed |
| 008   | YouTube Provider Abstraction              | Completed |
| 009   | YouTube Metadata Provider                 | Completed |
| 010   | Video Card Controller + Metadata Workflow | Completed |
| 011   | Prompt Selection Workflow                 | Completed |
| 012   | Transcript Discovery                      | Completed |
| 013   | Transcript Selection Strategy             | Completed |
| 014   | Transcript Download                       | Completed |
| 015   | Clipboard Support                        | Next      |

## Notes

- Phase 014 implemented transcript download:
  - `TranscriptService.downloadTranscript(videoId, track)` — downloads the selected transcript track via `YoutubeProvider.downloadTranscript`, maps provider DTOs → domain `TranscriptDownload` (videoId, track, plain text, raw segments).
  - Plain text returned without timestamps: segment texts joined with a single space. Raw timestamped segments preserved for later cleaning.
  - `YoutubeExplodeProvider.downloadTranscript` — fetches manifest, matches the requested track by language code and auto/manual, downloads caption track, maps to `YoutubeTranscript` DTO.
  - Error handling: provider returns `null` → `TranscriptsUnavailableException`; `VideoUnavailableException` → `YoutubeVideoUnavailableException`; other failures → `YoutubeNetworkException`.
  - Domain model (`lib/models/transcript_download.dart`): `TranscriptDownload` (videoId, track, text, segments) + `TranscriptSegment` (offset, duration, text).
  - Unit tests (5 new): successful download (plain text + metadata), provider-null → unavailable, video unavailable, network failure, generic provider failure.
- No Whisper, no transcript cleanup, no UI changes.
- 159 tests pass; flutter analyze clean; macOS debug build succeeds.

## Next Phase

Phase 015 — Clipboard Support.