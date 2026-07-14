#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="ShortcutBar"
VERSION="1.0"
OUTPUT_DIR="$ROOT_DIR/outputs"
APP_PATH="$OUTPUT_DIR/$APP_NAME.app"
STAGE_DIR="$OUTPUT_DIR/release-stage"
DMG_PATH="$OUTPUT_DIR/$APP_NAME-$VERSION.dmg"
ZIP_PATH="$OUTPUT_DIR/$APP_NAME-$VERSION.zip"

"$ROOT_DIR/scripts/build-mac-app.sh"

rm -rf "$STAGE_DIR"
rm -f "$DMG_PATH"
rm -f "$ZIP_PATH"

mkdir -p "$STAGE_DIR"
cp -R "$APP_PATH" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

rm -rf "$STAGE_DIR"

echo "$DMG_PATH"
echo "$ZIP_PATH"
