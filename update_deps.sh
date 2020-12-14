#!/usr/bin/env bash

source .env &&
(cd assets && npm update) &&
(cd ui_tests && npm update) &&
mix deps.update --all