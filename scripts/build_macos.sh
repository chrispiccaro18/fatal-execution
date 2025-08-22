#!/bin/bash
set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ macOS build must run on macOS."
  exit 1
fi

cd "$(dirname "$0")/.."

# Colors
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

VERSION=$(grep -E '^local VERSION_TAG' src/version.lua | cut -d'"' -f2)
APP_NAME="Fatal Exception"
BUNDLE_ID="${BUNDLE_ID:-com.bottletrail.fatal-exception}"

APP_DIR="build/macos_v$VERSION"
APP_PATH="$APP_DIR/$APP_NAME.app"
LOVE_APP_SRC="static/Love.app"
LOVE_FILE_TMP="build/tmp/fatal-exception.love"
ICNS_SRC="static/fatal-exception.icns"
PNG_ICON="static/fatal-exception.png"
DMG_PATH="build/fatal-exception-v$VERSION-mac.dmg"

echo -e "📌 Building ${GREEN}$APP_NAME v$VERSION${NC} (macOS)"

# Ensure Love.app exists
if [[ ! -d "$LOVE_APP_SRC" ]]; then
  echo -e "${RED}❌ static/Love.app not found.${NC}"
  echo -e "   Download LÖVE 11.5 for macOS and place the unpacked Love.app at:"
  echo -e "   ${YELLOW}static/Love.app${NC}"
  exit 1
fi

# Create .love if missing
if [[ ! -f "$LOVE_FILE_TMP" ]]; then
  echo "🧩 Creating .love archive..."
  rm -f "$LOVE_FILE_TMP"
  (cd src && zip -9 -r ../build/tmp/fatal-exception.love ./* >/dev/null)
fi

# Fresh app bundle
echo "🧰 Preparing app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
# Use ditto to preserve bundle metadata
ditto "$LOVE_APP_SRC" "$APP_PATH"

# Put game.love inside bundle
cp "$LOVE_FILE_TMP" "$APP_PATH/Contents/Resources/game.love"

# Update Info.plist
PLIST="$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName '$APP_NAME'" "$PLIST" || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleName string '$APP_NAME'" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '$APP_NAME'" "$PLIST" || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '$APP_NAME'" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$PLIST" || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST" || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$PLIST" || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $VERSION" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NSHighResolutionCapable true" "$PLIST" || \
  /usr/libexec/PlistBuddy -c "Add :NSHighResolutionCapable bool true" "$PLIST"

# Icon: prefer .icns; build it from PNG if needed
if [[ -f "$ICNS_SRC" ]]; then
  echo "🎨 Using existing .icns"
  cp "$ICNS_SRC" "$APP_PATH/Contents/Resources/app.icns"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile app" "$PLIST" || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string app" "$PLIST"
elif [[ -f "$PNG_ICON" ]]; then
  echo "🎨 Generating .icns from PNG..."
  ICONSET_DIR="build/tmp/icon.iconset"
  rm -rf "$ICONSET_DIR"; mkdir -p "$ICONSET_DIR"
  # Generate required sizes
  for s in 16 32 64 128 256 512; do
    s2=$((s*2))
    sips -z $s $s   "$PNG_ICON" --out "$ICONSET_DIR/icon_${s}x${s}.png" >/dev/null
    sips -z $s2 $s2 "$PNG_ICON" --out "$ICONSET_DIR/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$ICONSET_DIR" -o "$APP_PATH/Contents/Resources/app.icns"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile app" "$PLIST" || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string app" "$PLIST"
else
  echo -e "${YELLOW}⚠️ No icon found (static/fatal-exception.icns or .png). Using default.${NC}"
fi

# Optional: codesign if identity provided
if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  echo -e "🔏 Codesigning with identity: ${GREEN}$CODESIGN_IDENTITY${NC}"
  # Hardened runtime recommended for notarization
  codesign --deep --force --options runtime --sign "$CODESIGN_IDENTITY" "$APP_PATH"
  codesign --verify --deep --strict "$APP_PATH"
else
  echo -e "${YELLOW}ℹ️ Skipping codesign (set CODESIGN_IDENTITY to sign).${NC}"
fi

# Create DMG
echo "📦 Creating DMG..."
rm -f "$DMG_PATH"
hdiutil create -volname "$APP_NAME" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH" >/dev/null

# Optional: notarize if notarytool profile or creds provided
if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  echo "📮 Submitting for notarization with profile: $NOTARY_PROFILE"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler staple "$APP_PATH"
elif [[ -n "${APPLE_ID:-}" && -n "${TEAM_ID:-}" && -n "${APP_SPECIFIC_PW:-}" ]]; then
  echo "📮 Submitting for notarization with Apple ID creds..."
  xcrun notarytool submit "$DMG_PATH" --apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APP_SPECIFIC_PW" --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler staple "$APP_PATH"
else
  echo -e "${YELLOW}ℹ️ Skipping notarization (set NOTARY_PROFILE or APPLE_ID/TEAM_ID/APP_SPECIFIC_PW).${NC}"
fi

echo -e "✅ Done:\n  - $APP_PATH\n  - $DMG_PATH"
