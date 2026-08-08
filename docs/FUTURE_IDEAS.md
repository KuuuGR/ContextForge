# Future Ideas

An idea backlog collected during recent development. This document is intentionally
kept separate from the Roadmap — it is only a place to park ideas for later
consideration.

## Custom Vector Icon for the Default Prompt

- **Status:** Planned
- **Description:** Replace the current Unicode star symbol used for the Default Prompt
  with a dedicated custom vector icon (e.g. a brand-consistent "super star"), improving
  rendering consistency across platforms and localization.

## Transcript Blocks Named Using the Retrieved Video Title

- **Status:** Under consideration
- **Description:** Use the successfully retrieved YouTube video title as the transcript
  block name in generated output, with the numbered fallback retained when the title is
  unavailable.

## Quick Workflow Completion

- **Status:** Under consideration
- **Description:** Complete the ⚡ Quick Workflow so it runs the full pipeline automatically
  from a clipboard URL: paste, select the assigned prompt, generate, and copy the result —
  with clear feedback for invalid or missing clipboard content.

## Automatic Recognition of Pasted YouTube Content

- **Status:** Under consideration
- **Description:** Detect YouTube URLs (and possibly shared text containing them) when pasted
  anywhere appropriate, and offer or perform the canonical workflow without an explicit
  paste action.

## Markdown Export as an LLM Interoperability Feature

- **Status:** Planned
- **Description:** Position Markdown export as a first-class interoperability feature for LLM
  workflows, enabling clean, portable context exchange between ContextForge and external
  AI tools.

## Continued Desktop UX Polish

- **Status:** Under consideration
- **Description:** Continue refining desktop interactions (dropdown behavior, grab handles,
  selection and focus handling) so the macOS experience feels like a native application.

## Official Feedback Portal

- **Status:** Under consideration
- **Description:** Future versions may replace the email feedback actions (currently
  `mailto:` links to etaosin@gmail.com in the About dialog) with an official ContextForge
  feedback portal. The UI (the Feedback section with its three actions) is designed to stay
  the same — only the underlying action implementation would change.

## Prompt Library Expansion

- **Status:** Planned
- **Description:** Expand the built-in prompt library with:
  - more built-in prompt templates
  - community-requested prompt templates

## Destination Improvements

- **Status:** Planned
- **Description:** Improve the Destination selector by:
  - allowing users to configure Favorite Destinations
  - shipping several popular destinations marked as favorites by default

## Localization

- **Status:** Planned
- **Description:** Localize the application into additional languages, including:
  - the built-in prompt library
  - Help and onboarding content

## Prompt Output Language

- **Status:** Planned
- **Description:** Allow the user to select the desired output language directly from the
  Prompt UI (e.g. English, Polish, German, French, Spanish, Italian, Japanese, …). The
  selected language should automatically append the appropriate instruction to the
  generated prompt instead of requiring users to edit prompts manually.

  **Note:** This is documentation only — the feature is **not implemented** yet.

## Etaosin Mode

- **Status:** Planned
- **Description:** A planned hidden developer mode (toggled via the About dialog Easter Egg,
  the clickable `𝐞𝐭✰𝐨𝐬𝐢𝐧` marker). Future ideas may include:
  - batch processing of YouTube channel URLs
  - experimental workflows
  - advanced developer diagnostics
  - other hidden power-user features

  **Important:** This mode is **not implemented yet**. The About toggle currently only
  switches the marker between `✰` and `✪` and does not enable any hidden behavior.

---

_This file will be updated as ideas are collected during development._
