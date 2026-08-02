# ContextForge — Specification

## Project Purpose

ContextForge is a local-first macOS desktop application, built with Flutter Desktop, that helps content creators generate ready-to-copy prompt blocks for video-based content. The user selects a prompt template, pastes YouTube video URLs, and ContextForge combines the prompt, an inspiration summary, and cleaned transcripts into a single copy-ready text block.

## Primary Goals

- Provide a fast, native macOS desktop experience built on Flutter Desktop.
- Keep all user data and history local by default (local-first architecture).
- Combine user-selected prompt templates with YouTube video transcript data into one copy-ready output.
- Save time by automating transcript fetching, cleanup, and timestamp removal.
- Maintain a clean, maintainable codebase supported by documentation-driven development.

## Initial MVP Scope

The MVP implements the following end-to-end workflow:

1. **Prompt selection**
   - User selects one of the saved prompt templates or creates a custom prompt.

2. **Video input**
   - User pastes up to three YouTube URLs.

3. **Usage check**
   - Application checks whether each video has already been used before.

4. **Status indication**
   - Application displays:
     - green indicator = new video
     - blue indicator = previously used video

5. **Metadata & transcript download**
   - Application downloads:
     - publication date
     - transcript

6. **Preferred transcript order**
   - The application selects the best available transcript in this order:
     1. manual Polish
     2. automatic Polish
     3. manual English
     4. automatic English
     5. any available transcript

7. **Missing transcript handling**
   - If no transcript exists, the application asks whether Whisper transcription should be attempted.

8. **Timestamp cleanup**
   - Timestamp markers should be removed whenever possible.

9. **Output generation**
   - The application generates one copy-ready text block containing:
     - selected prompt
     - inspiration section
     - transcript section

10. **Copy**
    - User copies the generated result.

## High-Level User Workflow

1. User launches ContextForge on macOS.
2. User chooses a saved prompt template or writes a custom prompt.
3. User pastes up to three YouTube URLs.
4. ContextForge checks usage history and shows green (new) or blue (previously used) indicators.
5. ContextForge downloads publication dates and transcripts using the preferred transcript order.
6. If no transcript is available, ContextForge offers optional Whisper transcription.
7. ContextForge removes timestamp markers wherever possible.
8. ContextForge assembles a single copy-ready block: prompt + inspiration section + transcript section.
9. User copies the generated result.

## Non-Goals

- No cloud synchronization in the MVP.
- No multi-user collaboration in the MVP.
- No mobile or web platform support in the MVP.
- No plugin/extension marketplace in the MVP.
- No support for non-YouTube sources in the MVP.
- No application features in Phase 001/001A (bootstrap and documentation only).

## Future Extensibility

Potential future source support:

- Vimeo
- PDFs
- RSS feeds
- Websites
- Local files
- Audio files

Other extensibility areas:

- Cloud sync and backup (optional, opt-in).
- Plugin architecture for custom context providers.
- Import/export integrations with developer tools (IDEs, CLIs).
- Cross-platform desktop support (Linux, Windows).