# Pears External Specs

This directory demonstrates the expected structure for an external spec repo
that can be run against a Pears application instance.

## StrongDM Pattern: Holdout Validation

External specs act as "holdout" validation — they live outside the main codebase
so that a coding agent cannot cheat by reading or modifying them. The agent under
test interacts only with the running application through the browser.

## Structure

```
tests/
  auth.spec.ts          # Authentication flow specs
  pairing-board.spec.ts # Pairing board interaction specs
```

## Conventions

1. **Self-contained** — Specs must not import from the Pears codebase. Each spec
   file includes its own helpers (e.g., `registerAndLogin()`).

2. **Use `@playwright/test`** — The only dependency is Playwright itself.
   The runner provides Playwright; specs don't need their own package.json.

3. **Auth via UI** — Register teams through the UI at `/teams/register` with
   a unique team name to avoid conflicts between parallel runs.

4. **Use `data-cy` selectors** — The Pears app exposes `data-cy` attributes
   on key elements. Prefer these for stable selectors.

## Available `data-cy` Selectors

- `available-pears-list` — The unassigned pears section
- `add-pear-input` — Input field for adding a new pear
- `add-track-input` — Input field for adding a new track
- `track {name}` — A track by name
- `available-pear {name}` — An unassigned pear
- `assigned-pear {name}` — An assigned pear
- `toggle-anchor {name}` — Anchor toggle for a pear
- `lock-track {name}` / `unlock-track {name}` — Track lock controls
- `edit-track-name {name}` — Edit track name button
- `remove-track {name}` — Remove track button

## Running

From the Pears project root:

```bash
# Using the runner script with a local spec directory
PEARS_SPEC_DIR=./e2e/sample-external-specs/tests ./bin/run_e2e.sh

# Or pointing at a git repo
PEARS_SPEC_REPO_URL=https://github.com/yourorg/pears-specs.git ./bin/run_e2e.sh
```
