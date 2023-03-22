#!/usr/bin/env bash

source .env &&
mix format &&
mix credo --strict &&
mix test &&
#(cd ui_tests && npx cypress run) &&
cat << EOF
 ___ _   _  ___ ___ ___  ___ ___
/ __| | | |/ __/ __/ _ \/ __/ __|
\__ \ |_| | (_| (_|  __/\__ \__ \\
|___/\__,_|\___\___\___||___/___/
EOF