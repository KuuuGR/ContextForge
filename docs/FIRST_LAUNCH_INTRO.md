# First Launch Intro

## Philosophy

The First Launch Intro is a calm, premium editorial introduction shown only once after installation. It is **not** a splash screen and **not** a loading animation. The goal is to make opening ContextForge feel like opening a carefully crafted tool — not watching an advertisement.

## Animation Sequence

The intro uses **opacity-only fades**. No slide, scale, rotation, blur, particle effects, or cinematic transitions.

| Step | Element | Timing |
|------|---------|--------|
| 1 | Etaosin logo | 0.0s – 2.0s |
| 2 | "presents" | 2.0s – 3.5s |
| 3 | ContextForge | 3.5s – 5.5s |
| 4 | Build AI-ready context from YouTube transcripts | 5.5s – 7.0s |
| 5 | Editorial divider | 7.0s – 8.0s |
| 6 | Random Context Reflection | 8.0s – 10.5s |
| 7 | Fade out / onComplete | 10.5s – 12.0s |

Total duration: **12 seconds**.

## Lifecycle

- The Intro is displayed **only once** after a fresh installation.
- Completion is persisted in `intro_state.json` in the application support directory.
- After completion, the Intro is **never shown again**.
- `FirstLaunchIntroStore.reset()` allows developers to show it again during development.

## Branding Rules

- Application name: **ContextForge**
- Subtitle: **Build AI-ready context from YouTube transcripts**
- Editorial divider: subtle horizontal line
- Reflections: Context Reflections (random, one per launch)

## Context Reflections

Stored as reusable resources in `lib/resources/context_reflections.dart`. The initial set:

- Great prompts begin with great context.
- AI is only as good as the context you provide.
- Context is remembered. Prompts are forgotten.
- Every great answer starts before the first prompt.
- Don't ask AI for magic. Give it context.

Prepared for future localization.

## Persistence

- File: `intro_state.json`
- Format: `{"introCompleted": true}`
- Location: `${HOME}/Library/Application Support/context_forge/` (macOS)
- No database, no migration layer.