#!/bin/zsh

set -e

PROJECT_DIR="/Users/box/Work/test-card"
GODOT_APP="/Users/box/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app"
DEFAULT_NAMES=("Box" "Fox" "Wox" "Dox" "Eox")

if [ "$#" -gt 0 ]; then
	NAMES=("$@")
else
	NAMES=("${DEFAULT_NAMES[@]}")
fi

for name in "${NAMES[@]}"; do
	open -n "$GODOT_APP" --args --path "$PROJECT_DIR" -- --dev-player-name "$name"
	sleep 0.4
done
