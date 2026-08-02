# ContextForge — Architecture

## Overview

ContextForge follows a local-first, layered desktop architecture built on Flutter Desktop for macOS. The application is organized around clear separation of concerns: presentation (widgets), application logic (services), data access (repositories), and domain data (models).

## Folder Structure

```
lib/
├── main.dart
├── app/
│   └── (application entry, root widget, theme)
├── models/
│   └── (domain models)
├── repositories/
│   └── (data access layer)
├── services/
│   └── (application/business logic)
└── widgets/
    └── (reusable UI components)
```

## Layers & Responsibilities

### Presentation Layer (widgets)

- Renders the user interface.
- Composes reusable UI widgets from domain models.
- Dispatches user actions to services.
- Contains no business logic.

### Application Layer (services)

- Implements application workflows and use cases.
- Orchestrates repositories and models.
- Manages application state transitions.
- Kept free of framework-specific UI concerns.

### Data Access Layer (repositories)

- Abstract the persistence mechanism.
- Handle local storage read/write operations.
- Isolate storage engines (e.g., files, database) behind interfaces.
- Support the local-first guarantee by keeping data on-device.

### Domain Layer (models)

- Represent core business concepts (workspace, context item, package, tag).
- Contain no UI or persistence logic.
- Remain plain, serializable data structures.

## Architecture Principles (High-Level)

- **Local-first by default:** all data lives on the user's machine.
- **Layered separation:** widgets → services → repositories → models.
- **Dependency direction:** higher layers depend on lower layers; never the reverse.
- **Testability:** services and repositories are designed to be testable in isolation.
- **Documentation-driven:** architecture decisions are recorded in `docs/DECISIONS.md` and evolved phase by phase.

## Platform Support

- Primary target: macOS (desktop).
- The layered architecture keeps the door open for future desktop platforms (Linux, Windows) without restructuring.