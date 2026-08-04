# Project State — ContextForge

| Field               | Value                                 |
| ------------------- | ------------------------------------- |
| **Current Version** | 0.1.17                                |
| **Current Phase**   | 029B                                  |
| **Status**          | Workflow Polish II                    |
| **Current Milestone** | Power User Workflow                  |

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
| 027   | Keyboard Workflow                        | Completed |
| 028   | Smart Clipboard Workflow                 | Completed |
| 029   | Command Bar                              | Completed |
| 029A  | Power User Workflow                      | Completed |
| 029B  | Workflow Polish II                       | Completed |

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
- Phase 024 added persistent video processing history.
- Phase 025 added Prompt Favorites and Default Prompt.
- Phase 026 added Markdown export.
- Phase 027 added the keyboard workflow.
- Phase 028 added the Smart Clipboard Workflow.
- Phase 029 added the Command Bar.
- Phase 029A added the Power User Workflow:
  - Field clipboard icon replaces only ITS field; global ⌘V inserts into first empty slot.
  - Quick Access prompt roles (⚡, ①, ②, ③) via the bookmark menu.
  - Favorites state machine: ☆→★→🌟→☆; Default always implies Favorite.
  - Generate reuses cached metadata/transcripts when possible.
  - ⌘C behavior verified (full-output copy when no selection).
  - Prompt roles persisted via `prompts.json` `quickAccess` field.
- Phase 029B added Workflow Polish:
  - Immediate UI refresh after Quick Access/Favorite/Default changes.
  - Generate availability (disabled when nothing to process).
  - Clipboard refresh on window activation via WidgetsBindingObserver.
  - Command Bar visual polish (centered ⚡, improved spacing, clickable look).

## Next Phase

Phase 030.