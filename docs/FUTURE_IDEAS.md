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

## Etaosin Mode

- **Status:** Planned
- **Description:** A planned developer-only mode to be enabled through the temporary About
  dialog Easter Egg (the clickable `𝐞𝐭✰𝐨𝐬𝐢𝐧` marker). Future versions may use this toggle
  to enable advanced developer-only features, for example:
  - batch processing of YouTube channel URLs
  - experimental workflows
  - diagnostic tools
  - other advanced capabilities

  **Important:** This functionality is **planned only** and is **not implemented** in the
  current phase. The About toggle currently only switches the marker between `✰` and `✪`
  and does not enable any hidden behavior.

## Official Feedback Portal

- **Status:** Under consideration
- **Description:** Future versions may replace the email feedback actions (currently
  `mailto:` links to etaosin@gmail.com in the About dialog) with an official ContextForge
  feedback portal. The UI (the Feedback section with its three actions) is designed to stay
  the same — only the underlying action implementation would change.

---

_This file will be updated as ideas are collected during development._
