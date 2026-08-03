# Testing — ContextForge

This document defines the testing approach for ContextForge. It will be expanded as phases are implemented.

## Manual Testing

Manual testing covers workflows that require a human reviewer to verify behavior in the running application.

### Scope

- Verify the main window renders and behaves correctly on macOS.
- Verify prompt selection and custom prompt authoring.
- Verify YouTube URL input (up to three URLs) and validation.
- Verify video metadata loading completes for each card:
  - gray = no URL entered
  - green = metadata successfully loaded
  - red = invalid URL or metadata unavailable
  - blue = reserved for future history support
- Verify loading indicator is shown while metadata is being retrieved.
- Verify user-friendly error messages (never raw exceptions).
- Verify video metadata displays Title, Channel, and Publication Date.
- Verify transcript fetching follows the preferred order:
  1. manual Polish
  2. automatic Polish
  3. manual English
  4. automatic English
  5. any available transcript
- Verify Whisper transcription fallback prompt appears when no transcript exists.
- Verify timestamp markers are removed whenever possible.
- Verify output generation includes the selected prompt, inspiration section, and transcript section.

### Procedure

Each manual test should record:

- Test ID
- Description
- Preconditions
- Steps
- Expected result
- Actual result
- Pass/Fail

## Regression Testing

Regression testing ensures that existing functionality continues to work after changes.

### Scope

- Re-run manual tests that cover changed areas.
- Re-run the Flutter test suite (`flutter test`).
- Verify the application still builds (`flutter build macos --debug`).

### Trigger

Run regression tests:

- After every phase completion.
- Before each release.

## Acceptance Checklist

Use this checklist to verify a phase or milestone is complete.

- [ ] Application builds successfully on macOS.
- [ ] Unit/widget tests pass.
- [ ] Manual test cases have been executed and recorded.
- [ ] No known critical issues remain open (see `docs/KNOWN_ISSUES.md`).
- [ ] Documentation is synchronized with the implementation (see `docs/PROMPT_GUIDELINES.md`).
- [ ] Changelog and release notes are updated.
- [ ] Session report is updated for the phase.