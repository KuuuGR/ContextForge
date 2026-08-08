# Project State — ContextForge

| Field               | Value                                 |
| ------------------- | ------------------------------------- |
| **Current Version** | 0.1.17                                |
| **Current Phase**   | 034                                   |
| **Status**          | Release Preparation                   |
| **Current Milestone** | App Store Preparation                |

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
| 024   | URL History & Visual Status              | Completed |
| 025   | Prompt Favorites & Default Prompt        | Completed |
| 026   | Export as Markdown                       | Completed |
| 027   | Keyboard Workflow                        | Completed |
| 028   | Smart Clipboard Workflow                 | Completed |
| 029   | Command Bar                              | Completed |
| 029A  | Power User Workflow                      | Completed |
| 029B  | Workflow Polish II                       | Completed |
| 029C  | Workflow Polish III                      | Completed |
| 029D  | Prompt Library Completion                | Completed |
| 029E  | Usability Finalization                   | Completed |
| 030   | App Store Readiness I                    | Completed |
| 031   | First Launch Intro                        | Completed |
| 032B  | Prompt List Live Refresh                 | Completed |
| 033B  | Unify Default Prompt Icon                | Completed |
| 033C  | Centralize Default Prompt Icon           | Completed |
| 033D  | Etaosin Easter Egg                       | Completed |
| 033E  | User Feedback                            | Completed |
| 033F  | Feedback Polish & Roadmap Update         | Completed |
| 034   | Release Preparation                      | Completed |

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
- Phase 029C added Workflow Polish III:
  - ⌘R Generate shortcut (reuses existing Generate action).
  - Prompt Library refresh confirms immediate updates.
  - Clipboard revalidation on window activation confirmed.
  - Command Bar hover feedback and clickable affordances improved.
- Phase 029D completed the Prompt Library:
  - ➕ New Prompt button with Save/Cancel dialog.
  - Edit dialog for title + content.
  - Delete with role-assignment confirmation.
  - Empty state with "Create your first prompt".
  - All modifications refresh immediately.
- Phase 029D Final verified Power User Workflow consistency:
  - All keyboard shortcuts (⌘V, ⌘C, ⌘R, ⌘↩, ⌘⌫, ⌘⇧S, Escape) verified consistent.
  - Button states always reflect real application state.
  - Prompt Library refreshes immediately on every action.
  - Command Bar spacing/alignment/button sizing consistent.
  - Complete daily workflow (Clipboard → Paste → Prompt → Generate → Copy) validated.
- Phase 029E added Usability Finalization:
  - Informational footer (ⓘ About, ⌨ Shortcuts, ❓ Help).
  - URL normalization strips playback-only parameters.
  - First-time user discoverability without external docs.

- Phase 030 added App Store readiness:
  - Localization (en/pl/es), starter prompt library, AI quick links, URL canonicalization.
- Phase 031 added the First Launch Intro:
  - One-time editorial introduction, opacity-only choreography, 12s duration.
  - Context Reflections (random), persisted completion, dedicated feature architecture.
  - Documented in `docs/FIRST_LAUNCH_INTRO.md`.
- Phase 032B added live refresh of the expanded prompt selector (Favorite / Default /
  Quick Access updates without closing the dropdown).
- Phase 033B unified the Default Prompt icon across the collapsed and expanded selectors.
- Phase 033C centralized the Default Prompt icon into a single reusable `DefaultPromptIcon`
  component used everywhere.
- Phase 033D added the Etaosin Easter Egg (clickable `𝐞𝐭✰𝐨𝐬𝐢𝐧` toggle in the About dialog).
- Phase 033E added the Feedback section (💡 Suggest an Idea, 🐞 Report a Bug,
  ✉️ General Feedback) via `mailto:` links to etaosin@gmail.com.
- Phase 033F polished the Feedback section (subtle footer) and expanded the roadmap.
- Phase 034 entered Release Preparation:
  - Reviewed macOS + iOS platform readiness (entitlements, app icons, Info.plist).
  - Fixed the version mismatch: `pubspec.yaml` now reports `0.1.17+1`, matching the
    About dialog and this document.
  - Updated the backlog with planned features (URL Normalization, Prompt Library,
    Destination, Localization, Prompt Output Language, Etaosin Mode, Community Feedback).
  - The project is entering App Store preparation.

## Next Phase

Post-release development cycle.
