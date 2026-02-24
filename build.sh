#!/bin/bash
set -e

BUILD_DIR=/tmp/todo-build
OUT=~/Desktop/Todo.zip
APP_SRC="$BUILD_DIR/Build/Products/Release/Todo.app"
APP_DEST=/Applications/Todo.app

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project Todo/Todo.xcodeproj \
  -scheme Todo \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  build

# Quit the running app if it's open
osascript -e 'tell application "Todo" to quit' 2>/dev/null || true
sleep 1

# Install to /Applications
rm -rf "$APP_DEST"
cp -r "$APP_SRC" "$APP_DEST"

# Relaunch
open "$APP_DEST"

# Also produce a ZIP for sharing
rm -f "$OUT"
ditto -c -k --keepParent "$APP_SRC" "$OUT"

echo "Done: installed and relaunched. ZIP at $OUT"
