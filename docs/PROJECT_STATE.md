# Project State — ContextForge

| Field               | Value                                 |
| ------------------- | ------------------------------------- |
| **Current Version** | 0.1.14                                |
| **Current Phase**   | 026                                  |
| **Status**          | Markdown export implemented          |
| **Current Milestone** | Daily Workflow Improvements          |

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
| 015   | Transcript Cleanup                        | Completed |
| 016   | Output Builder                            | Completed |
| 017   | End-to-End Generate Workflow              | Completed |
| 018   | YouTube Connectivity Diagnostics          | Completed |
| 019   | Runtime Execution Trace                   | Completed |
| 020   | Root Cause Analysis                       | Completed |
| 021   | YouTube Provider Review                   | Completed |
| 022A  | Collect macOS Network Configuration Evidence | Completed |
| 022B  | Enable macOS Outbound Network Access      | Completed |
| 023   | Output Actions                           | Completed |
| 024   | URL History & Visual Status              | Completed |
| 025   | Prompt Favorites & Default Prompt        | Completed |
| 026   | Export as Markdown                       | Completed |

## Notes

- Phase 018 added diagnostics; Phase 019 added runtime trace; Phase 020 identified the root cause: missing `com.apple.security.network.client` entitlement.
- Phase 021 verified `youtube_explode_dart` is **KEEP** — not a provider issue.
- Phase 022A collected entitlement configuration evidence (CF-001 confirmed).
- Phase 022B fixed CF-001:
  - Added `com.apple.security.network.client` to `macos/Runner/DebugProfile.entitlements`.
  - Added `com.apple.security.network.client` to `macos/Runner/Release.entitlements`.
  - Verified: `flutter build macos` succeeds (44.4MB Release build).
  - Verified: `codesign -d --entitlements` shows `com.apple.security.network.client` embedded in the built app.
- User-facing "Could not reach YouTube" error is resolved.
- Phase 023 added the Output action bar (Copy, Clear, keyboard shortcut).
- Phase 024 added persistent video processing history:
  - `video_history.json` in the application support directory.
  - Records every successful transcript generation (videoId, originalUrl, title, channelName, processedAt).
  - Updates `processedAt` on reprocessing — no duplicates.
  - Green/neutral dot indicator inside each URL field.
  - Tooltip shows the last processed date/time.
  - History survives application restarts and the Clear button.
- Phase 025 added Prompt Favorites and Default Prompt:
  - Star icon toggles Favorites; Favorites sort to the top with manual order preserved.
  - Bookmark control toggles the single Default; a "Default" badge is shown.
  - Default Prompt auto-selects on launch.
  - `isFavorite` / `isDefault` persisted in `prompts.json` (no new storage).
  - Removing Default restores previous behaviour (first prompt selected).
- Phase 026 added Markdown export:
  - `Export Markdown` button next to Copy and Clear in the Output section.
  - Native macOS Save dialog via `file_selector`.
  - Default filename: `ContextForge-YYYY-MM-DD-HHMM.md`.
  - UTF-8 output written byte-for-byte exactly as displayed.
  - `Markdown exported.` confirmation snackbar on success.
  - Added `com.apple.security.files.user-selected.read-write` entitlement for the sandboxed app.

## Next Phase

Phase 027.