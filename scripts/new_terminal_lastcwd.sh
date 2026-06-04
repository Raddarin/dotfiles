#!/usr/bin/env bash
set -euo pipefail

FILE="/tmp/lastcwd-$USER"
CWD="$HOME"

if [[ -f "$FILE" ]]; then
  read -r CWD <"$FILE" || true
fi

# fallback om katalogen inte finns
if [[ ! -d "$CWD" ]]; then
  CWD="$HOME"
fi

exec kitty --directory "$CWD"
