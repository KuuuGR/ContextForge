# Decisions — ContextForge

## ADR-001 — Flutter Desktop

**Status:** Accepted

**Context:** ContextForge needs a cross-platform-capable UI framework with strong desktop support and a productive development experience.

**Decision:** Build ContextForge with Flutter Desktop, targeting macOS as the primary platform.

**Consequences:** Native desktop performance on macOS, a single codebase shared across future desktop platforms, and access to Flutter's rich widget ecosystem.

---

## ADR-002 — Local-First Architecture

**Status:** Accepted

**Context:** Users need immediate, reliable access to their context data without depending on a network connection or cloud service.

**Decision:** Adopt a local-first architecture: all data lives on the user's machine by default. Any cloud features in the future must be opt-in.

**Consequences:** Data remains private and available offline; future sync features will require explicit user consent and careful design.

---

## ADR-003 — Documentation-Driven Development

**Status:** Accepted

**Context:** The project spans many phases and requires consistent, maintainable progress across sessions.

**Decision:** Follow a documentation-driven development workflow. All phases, decisions, known issues, and session reports are recorded under `docs/` and kept synchronized with the codebase.

**Consequences:** Every phase produces documentation alongside code; documentation drift is treated as a defect.

---

## ADR-004 — English Technical Documentation

**Status:** Accepted

**Context:** The project is open to a broad developer audience and must remain accessible and consistent across sessions.

**Decision:** All technical documentation and commit messages are written in English.

**Consequences:** Consistent terminology, easier collaboration, and unambiguous machine-readability of documentation.

---

## ADR-005 — One Phase = One Feature = One Commit

**Status:** Accepted

**Context:** The project needs clean, reviewable history and a clear mapping between work performed and repository state.

**Decision:** Each phase corresponds to a single feature scope and is delivered as exactly one commit.

**Consequences:** History stays linear and auditable; phases are independently revertible; the repository is always buildable at each commit.

---

## ADR-006 — Never Create Fake UI Models

**Status:** Accepted

**Context:** The project architecture separates presentation (widgets), application logic (services), data access (repositories), and domain data (models). There is a risk that UI layers could introduce parallel, "fake" view-model classes that drift from the production domain models.

**Decision:** Never create fake UI models. Use production domain models everywhere, including in tests and UI state. The `Prompt` model is the single source of truth for prompt data throughout the application.

**Consequences:** No duplication of domain state; the UI can never drift from the domain contract; tests exercise the real model behavior.
