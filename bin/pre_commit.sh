#!/usr/bin/env bash
set -e

source .env

mix deps.unlock --check-unused
mix compile --warnings-as-errors

mix format
mix credo --strict
TELEMETRY_LOG_LEVEL=debug mix test

mix hex.outdated
# Uncomment to run e2e tests as part of pre-commit:
#./bin/run_e2e.sh

cat <<EOF
 ___ _   _  ___ ___ ___  ___ ___
/ __| | | |/ __/ __/ _ \/ __/ __|
\__ \ |_| | (_| (_|  __/\__ \__ \\
|___/\__,_|\___\___\___||___/___/
EOF
