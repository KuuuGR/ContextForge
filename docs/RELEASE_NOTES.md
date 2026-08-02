# Release Notes — ContextForge

## Version 0.0.4

**Release Date:** 2026-02-08

### What's New

- Local JSON storage for prompt templates (`prompts.json` in the application support directory).
- `JsonPromptStorage` service — human-readable, indented JSON; auto-creates missing files.
- `JsonPromptRepository` — concrete implementation of the `PromptRepository` contract.
- Graceful handling of missing, empty, and invalid JSON files.
- Unit tests covering storage edge cases.

### Notes

- No third-party storage packages — uses Dart built-in `dart:io` and `dart:convert`.
- Storage remains replaceable through the `PromptRepository` abstraction.

---

## Version 0.0.3

**Release Date:** 2026-02-08

### What's New

- Immutable `Prompt` domain model with JSON serialization/deserialization, `copyWith()`, equality, and readable `toString()`.
- Abstract `PromptRepository` contract (getAll, getById, save, delete).
- `PromptService` skeleton depending on the repository abstraction.

### Notes

- No persistence, storage, or CRUD logic yet — domain foundation only.

---

## Version 0.0.2

**Release Date:** 2026-02-08

### What's New

- Main application window and application shell:
  - Header (title + subtitle).
  - Prompt section (dropdown selector, custom prompt option, disabled-unless-custom editor).
  - Videos section (three video input cards with green/blue/gray status indicators).
  - Output section (read-only preview).
  - Bottom toolbar (disabled Generate, Copy, Clear buttons).
- `docs/DEPENDENCIES.md` created.

### Notes

- No business logic, networking, or storage implemented yet.
- Static UI only; all buttons disabled by design.

---

## Version 0.0.1

**Release Date:** 2026-02-08

### What's New

- Project bootstrap and documentation structure.
- Flutter Desktop project scaffolded for macOS.
- Documentation alignment with the ContextForge vision (Phase 001A).

### Notes

- No application features are available yet.
- This is an internal bootstrap release, not a public release.

---

_Release notes will be maintained from this point forward._