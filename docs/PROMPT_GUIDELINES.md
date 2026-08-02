# Prompt Guidelines — ContextForge

These are the implementation rules that must be followed for every phase of this project.

## Rules

1. **One Phase = One Feature = One Commit**
   - Each phase delivers exactly one feature scope.
   - Each phase is committed as exactly one commit.
   - No stray or extra commits within a phase.

2. **Read Documentation Before Coding**
   - Always read the relevant documentation (`docs/`) before starting implementation.
   - Follow the specification, roadmap, and architecture.

3. **Update Documentation Every Phase**
   - Each phase must update the applicable documentation.
   - Keep the changelog, session report, project state, and decisions synchronized with the code.

4. **Never Modify Unrelated Code**
   - Changes must be limited to the scope of the current phase.
   - Do not refactor or touch functionality unrelated to the task.

5. **Never Redesign Architecture**
   - The architecture is defined in `docs/ARCHITECTURE.md`.
   - Implementation must follow the documented architecture.
   - Architecture changes require a recorded decision (`docs/DECISIONS.md`).

6. **Keep Repository Buildable**
   - The project must always build successfully after each phase.
   - No broken intermediate states allowed.

7. **Keep Documentation Synchronized**
   - Documentation must reflect the actual state of the codebase.
   - Documentation drift is treated as a defect.
   - Update `docs/PROJECT_STATE.md` with current version, phase, status, and milestone after every phase.

## Workflow

1. Read: specification, roadmap, architecture, decisions, and project state.
2. Implement the phase scope only.
3. Update documentation to match implementation.
4. Verify the project builds.
5. Create exactly one commit with a clear phase message.