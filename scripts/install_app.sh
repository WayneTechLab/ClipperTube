#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="Cliper Tube.app"
APP_BUNDLE="$DIST_DIR/$APP_NAME"
EXECUTABLE_NAME="CliperTube"
EXECUTABLE_PATH="$BUILD_DIR/$EXECUTABLE_NAME"
SDK_PATH="$(xcrun --show-sdk-path)"
APP_VERSION="1.1.0"
BUILD_NUMBER="2"

mkdir -p "$BUILD_DIR" "$DIST_DIR"

echo "[1/5] Building Cliper Tube binary..."
swiftc \
  -target arm64-apple-macos13.0 \
  -sdk "$SDK_PATH" \
  -parse-as-library \
  -O \
  -framework SwiftUI \
  -framework AVKit \
  -framework AVFoundation \
  -framework AppKit \
  -framework Security \
  -framework UniformTypeIdentifiers \
  -framework WebKit \
  "$ROOT_DIR"/Sources/CliperTube/*.swift \
  -o "$EXECUTABLE_PATH"

echo "[2/5] Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$EXECUTABLE_PATH" "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$EXECUTABLE_NAME</string>
    <key>CFBundleIconFile</key>
    <string></string>
    <key>CFBundleIdentifier</key>
    <string>com.waynetechlab.clipertube</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Cliper Tube</string>
    <key>CFBundleDisplayName</key>
    <string>Cliper Tube</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.video</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright Wayne Tech Lab LLC. All rights reserved.</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
PLIST

echo "[3/5] Writing entitlements..."
cat > "$BUILD_DIR/entitlements.plist" <<ENTITLEMENTS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
</dict>
</plist>
ENTITLEMENTS

echo "[4/5] Signing bundle (ad-hoc with entitlements)..."
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - \
    --entitlements "$BUILD_DIR/entitlements.plist" \
    "$APP_BUNDLE" >/dev/null 2>&1 || true
fi

INSTALL_TARGET="/Applications/$APP_NAME"
if [[ ! -w "/Applications" ]]; then
  mkdir -p "$HOME/Applications"
  INSTALL_TARGET="$HOME/Applications/$APP_NAME"
fi

echo "[5/5] Installing to $INSTALL_TARGET"
rm -rf "$INSTALL_TARGET"
cp -R "$APP_BUNDLE" "$INSTALL_TARGET"

echo
echo "Installed: $INSTALL_TARGET"
echo "Version: $APP_VERSION ($BUILD_NUMBER)"
echo "Launch with: open \"$INSTALL_TARGET\""
