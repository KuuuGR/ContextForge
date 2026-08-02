# Release Notes — ContextForge

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