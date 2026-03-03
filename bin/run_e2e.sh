#!/usr/bin/env bash
set -euo pipefail

# StrongDM-style Playwright runner for Pears
# Starts Phoenix, runs internal + optional external specs via Playwright.
#
# Environment variables:
#   PEARS_BASE_URL       - App URL (default: http://localhost:4002)
#   PEARS_SPEC_REPO_URL  - Git URL of external spec repo to clone and run
#   PEARS_SPEC_REPO_REF  - Branch/tag to checkout (default: main)
#   PEARS_SPEC_DIR       - Local path to external specs (overrides clone)
#   SKIP_INTERNAL        - Set to skip internal smoke tests

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
E2E_DIR="$PROJECT_DIR/e2e"

PEARS_BASE_URL="${PEARS_BASE_URL:-http://localhost:4002}"
PEARS_SPEC_REPO_REF="${PEARS_SPEC_REPO_REF:-main}"

PHOENIX_PID=""
TEMP_SPEC_DIR=""
EXIT_CODE=0

cleanup() {
  echo ""
  echo "==> Cleaning up..."
  if [ -n "$PHOENIX_PID" ] && kill -0 "$PHOENIX_PID" 2>/dev/null; then
    echo "    Stopping Phoenix (PID $PHOENIX_PID)..."
    kill "$PHOENIX_PID" 2>/dev/null || true
    wait "$PHOENIX_PID" 2>/dev/null || true
  fi
  if [ -n "$TEMP_SPEC_DIR" ] && [ -d "$TEMP_SPEC_DIR" ]; then
    echo "    Removing temp spec dir..."
    rm -rf "$TEMP_SPEC_DIR"
  fi
}
trap cleanup EXIT

# ── Step 1: Install Playwright dependencies ─────────────────────────────
echo "==> Installing Playwright dependencies..."
cd "$E2E_DIR"
if [ ! -d "node_modules" ]; then
  npm install
fi
npx playwright install --with-deps chromium 2>/dev/null || npx playwright install chromium

# ── Step 2: Set up environment for Phoenix ──────────────────────────────
cd "$PROJECT_DIR"

# Source .env if available (provides SLACK_* vars etc.)
if [ -f ".env" ]; then
  echo "==> Sourcing .env..."
  # shellcheck disable=SC1091
  source .env 2>/dev/null || true
fi

# Provide fallback values for required env vars if not already set.
# These are needed for runtime.exs to boot Phoenix, even in test mode.
export SLACK_CLIENT_ID="${SLACK_CLIENT_ID:-dummy-e2e-client-id}"
export SLACK_CLIENT_SECRET="${SLACK_CLIENT_SECRET:-dummy-e2e-client-secret}"
export SLACK_SIGNING_SECRET="${SLACK_SIGNING_SECRET:-dummy-e2e-signing-secret}"

# ── Step 3: Prepare test database ───────────────────────────────────────
echo "==> Preparing test database..."
MIX_ENV=test mix ecto.reset

# ── Step 4: Start Phoenix ───────────────────────────────────────────────
echo "==> Starting Phoenix on port 4002..."
PHX_SERVER=true MIX_ENV=test mix phx.server &
PHOENIX_PID=$!

# Wait for server to be ready
echo "    Waiting for server..."
for i in $(seq 1 30); do
  if curl -sf "$PEARS_BASE_URL/teams/log_in" > /dev/null 2>&1; then
    echo "    Server ready after ${i}s"
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "    ERROR: Server did not start within 30 seconds"
    exit 1
  fi
  sleep 1
done

# ── Step 5: Run internal Playwright specs ───────────────────────────────
cd "$E2E_DIR"
export PEARS_BASE_URL

if [ -z "${SKIP_INTERNAL:-}" ]; then
  echo ""
  echo "==> Running internal e2e specs..."
  if npx playwright test; then
    echo "    ✓ Internal specs passed"
  else
    echo "    ✗ Internal specs failed"
    EXIT_CODE=1
  fi
else
  echo "==> Skipping internal specs (SKIP_INTERNAL set)"
fi

# ── Step 6: Clone external spec repo if configured ──────────────────────
if [ -n "${PEARS_SPEC_REPO_URL:-}" ] && [ -z "${PEARS_SPEC_DIR:-}" ]; then
  echo ""
  echo "==> Cloning external specs from $PEARS_SPEC_REPO_URL (ref: $PEARS_SPEC_REPO_REF)..."
  TEMP_SPEC_DIR="$(mktemp -d)"
  git clone --depth 1 --branch "$PEARS_SPEC_REPO_REF" "$PEARS_SPEC_REPO_URL" "$TEMP_SPEC_DIR"
  PEARS_SPEC_DIR="$TEMP_SPEC_DIR/tests"
fi

# ── Step 7: Run external specs if available ─────────────────────────────
if [ -n "${PEARS_SPEC_DIR:-}" ]; then
  echo ""
  echo "==> Running external specs from $PEARS_SPEC_DIR..."
  export PEARS_SPEC_DIR
  if npx playwright test --config=playwright.external.config.ts; then
    echo "    ✓ External specs passed"
  else
    echo "    ✗ External specs failed"
    EXIT_CODE=1
  fi
fi

# ── Done ────────────────────────────────────────────────────────────────
echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "==> All e2e specs passed!"
else
  echo "==> Some e2e specs failed. Check output above for details."
  echo "    HTML report: $E2E_DIR/playwright-report/index.html"
fi

exit $EXIT_CODE
