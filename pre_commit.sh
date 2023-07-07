#!/usr/bin/env bash
set -e

source .env

mix deps.unlock --unused
mix deps.clean --unused
mix compile --warnings-as-errors

mix format
mix credo --strict
mix hex.outdated

TELEMETRY_LOG_LEVEL=debug mix test
#(cd ui_tests && npx cypress run)

cat <<EOF
 ___ _   _  ___ ___ ___  ___ ___
/ __| | | |/ __/ __/ _ \/ __/ __|
\__ \ |_| | (_| (_|  __/\__ \__ \\
|___/\__,_|\___\___\___||___/___/
EOF
