# Pears

## Update JS/CSS dependencies
- Grab the new version of [SortableJS](https://github.com/SortableJS/Sortable/releases) and [topbar](https://www.npmjs.com/package/topbar?activeTab=code) and copy them into `assets/vendor`.
- Update the version numbers of esbuild and tailwind in `config/config.exs` and run `mix esbuild.install` and `mix tailwind.install`

## Update Hex dependencies
- `mix hex.outdated`
- `mix deps.update <dep>` or `mix deps.update --all`

## Pre-commit script
- `make check` or `./bin/pre_commit.sh`

## Slack app info
Public link: https://solid-af.slack.com/apps/A01F4QV5LEQ-pears
Configuration link: https://api.slack.com/apps/A01F4QV5LEQ
