# Repository Guidelines

## Project Structure & Module Organization
- Source lives under `src/` (services, models, utils). Tests in `tests/`. Scripts in `scripts/`. Project docs in `docs/`. Planning notes in `Planning/`.
- Keep modules small and cohesive. One responsibility per module; co-locate tests next to code when helpful (`src/foo/`, `src/foo/tests/`).

## Build, Test, and Development Commands
- Install deps (choose what matches the stack):
  - .NET: `dotnet restore`
  - Python: `python -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt`
  - Node: `npm ci`
- Build: `.NET: dotnet build`, Python: n/a, Node: `npm run build` (if present).
- Test: `.NET: dotnet test`, Python: `pytest -q`, Node: `npm test`.
- Run locally: `.NET: dotnet run -p src/<Project>.csproj`, Python: `python -m <package>`, Node: `npm run dev`.

## Coding Style & Naming Conventions
- Indentation: 4 spaces; UTF‑8; LF line endings.
- Naming: PascalCase for classes/types; camelCase for variables/params; SNAKE_CASE for constants; Python modules use `snake_case.py`.
- Keep functions ≤ 50 lines when practical; prefer pure functions; avoid side effects in utils.
- Apply formatters/linters if present (e.g., `dotnet format`, `ruff format && ruff check`, `eslint --fix`).

## Testing Guidelines
- Frameworks: `.NET xUnit/NUnit`, `pytest` for Python, or Jest/Vitest for Node.
- Place tests under `tests/` mirroring package paths. Names: Python `tests/test_<unit>.py`; .NET `<Unit>Tests.cs`.
- Aim for ≥ 80% line coverage on changed code; include edge cases and failure paths.

## Commit & Pull Request Guidelines
- Use Conventional Commits where possible: `feat:`, `fix:`, `docs:`, `chore:`.
- Commits: small, focused, with imperative subject (≤ 72 chars) and context in body.
- PRs: include purpose, linked issues (`Closes #123`), testing notes, and screenshots/logs when relevant. Request review early for large changes.

## Security & Configuration Tips
- Never commit secrets. Use environment variables or `.env` (not tracked). Example: `AZURE_TENANT_ID`, `DB_CONNECTION_STRING`.
- Store local config in `config/` or stack‑specific files (e.g., `appsettings.Development.json`). Document any required keys in `README.md`.

## Agent-Specific Instructions
- Prefer `rg` for search, read files in ≤ 250‑line chunks, and keep patches minimal and scoped. Respect existing structure and naming.

## Parallel Agent Workflow (Git Worktrees)
- Keep `master` pristine: sync with `git fetch origin` and `git pull --ff-only origin master` before creating new worktrees.
- Create isolated sandboxes per agent/task: `git worktree add worktrees/<agent>/<topic> -b agent/<agent>/<topic> master`.
- Work, stage, and commit inside that worktree directory; push with `git push -u origin agent/<agent>/<topic>`.
- When merged, clean up via `git worktree remove worktrees/<agent>/<topic>` followed by `git branch -d agent/<agent>/<topic>`; prune stale with `git worktree prune` weekly.
- Store worktrees under `worktrees/` (ignored) to avoid polluting repo root and to run multiple agents in parallel without checkout conflicts.
- Shortcut: `pwsh scripts/new-worktree.ps1 -Agent <name> -Topic <slug>` performs the fetch/pull, adds the worktree and opens a new terminal; pass `-SkipPull` for advanced scenarios.
