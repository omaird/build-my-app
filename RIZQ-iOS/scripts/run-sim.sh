#!/usr/bin/env bash
# Boot a simulator, build RIZQ for it, install, and launch.
# Usage: ./scripts/run-sim.sh ["iPhone 17 Pro"]   (default: "iPhone 17")

set -euo pipefail

SIM_NAME="${1:-iPhone 17}"
SCHEME="RIZQ"
BUNDLE_ID="com.rizq.app"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED="$PROJECT_DIR/build/sim"

cd "$PROJECT_DIR"

echo "▸ Booting simulator: $SIM_NAME"
xcrun simctl boot "$SIM_NAME" 2>/dev/null || true
open -a Simulator

echo "▸ Building $SCHEME for $SIM_NAME (Debug)"
xcodebuild \
  -project RIZQ.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=$SIM_NAME" \
  -derivedDataPath "$DERIVED" \
  -skipMacroValidation \
  build

APP_PATH="$DERIVED/Build/Products/Debug-iphonesimulator/$SCHEME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "✗ App not found at $APP_PATH" >&2
  exit 1
fi

echo "▸ Installing $APP_PATH"
xcrun simctl install "$SIM_NAME" "$APP_PATH"

echo "▸ Launching $BUNDLE_ID"
xcrun simctl terminate "$SIM_NAME" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$SIM_NAME" "$BUNDLE_ID"

echo "✓ RIZQ is running on $SIM_NAME"
