#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$PROJECT_ROOT/build/release}"
DIST_DIR="${DIST_DIR:-$PROJECT_ROOT/dist}"
GODOT_BIN="${GODOT_BIN:-godot}"
APP_NAME="${APP_NAME:-TestCard}"

mkdir -p "$BUILD_DIR/windows" "$BUILD_DIR/macos" "$DIST_DIR"
mkdir -p "$BUILD_DIR/linux"

echo "Exporting Windows build..."
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --export-release "Windows Desktop" "$BUILD_DIR/windows/${APP_NAME}.exe"

if [[ -f "$BUILD_DIR/windows/${APP_NAME}.pck" ]]; then
  :
elif [[ -f "$BUILD_DIR/windows/${APP_NAME}.exe" ]]; then
  :
else
  echo "Windows export did not produce expected files." >&2
  exit 1
fi

echo "Exporting macOS build..."
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --export-release "macOS" "$BUILD_DIR/macos/${APP_NAME}.app"

echo "Exporting Linux build..."
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --export-release "Linux/X11" "$BUILD_DIR/linux/${APP_NAME}.x86_64"

rm -f "$DIST_DIR/${APP_NAME}-windows-x86_64.zip" "$DIST_DIR/${APP_NAME}-macos-universal.zip" "$DIST_DIR/${APP_NAME}-linux-x86_64.zip"

echo "Packaging Windows artifact..."
(
  cd "$BUILD_DIR/windows"
  zip -q -r "$DIST_DIR/${APP_NAME}-windows-x86_64.zip" "${APP_NAME}.exe" "${APP_NAME}.pck"
)

echo "Packaging macOS artifact..."
ditto -c -k --keepParent "$BUILD_DIR/macos/${APP_NAME}.app" "$DIST_DIR/${APP_NAME}-macos-universal.zip"

echo "Packaging Linux artifact..."
(
  cd "$BUILD_DIR/linux"
  zip -q -r "$DIST_DIR/${APP_NAME}-linux-x86_64.zip" "${APP_NAME}.x86_64" "${APP_NAME}.pck"
)

echo "Artifacts written to $DIST_DIR"
