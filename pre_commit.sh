#!/usr/bin/env bash

mix format &&
mix credo --strict &&
mix test &&
(cd assets && npx cypress run) &&
cat << EOF
 ___ _   _  ___ ___ ___  ___ ___
/ __| | | |/ __/ __/ _ \/ __/ __|
\__ \ |_| | (_| (_|  __/\__ \__ \\
|___/\__,_|\___\___\___||___/___/
EOF