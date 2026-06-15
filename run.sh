#!/bin/bash
set -e

cd "$(dirname "$0")"

SCHEME="HelpYourParent"
SDK="iphonesimulator"
DEST="platform=iOS Simulator,name=iPhone 17 Pro"

echo "==> Building HelpYourParent with custom Info.plist..."

# Build with the correct settings
xcodebuild \
  -scheme "$SCHEME" \
  -sdk "$SDK" \
  -destination "$DEST" \
  INFOPLIST_FILE="App/Info.plist" \
  PRODUCT_BUNDLE_IDENTIFIER="com.hyp.helpyourparent" \
  build 2>&1 | grep -E "error:|warning:|BUILD|Build succeeded"

if [ $? -eq 0 ]; then
    echo ""
    echo "==> ✅ Build succeeded. Opening Simulator..."

    # Find the built .app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/HelpYourParent-*/Build/Products/Debug-iphonesimulator \
        -name "HelpYourParent.app" -maxdepth 3 2>/dev/null | head -1)

    if [ -n "$APP_PATH" ]; then
        # Boot simulator and install
        UDID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | head -1 | grep -o -E '[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}')
        xcrun simctl boot "$UDID" 2>/dev/null || true
        open -a Simulator
        xcrun simctl install booted "$APP_PATH"
        xcrun simctl launch booted com.hyp.helpyourparent
    else
        echo "App built. Run it from Xcode (⌘R) with the correct scheme selected."
    fi
fi
