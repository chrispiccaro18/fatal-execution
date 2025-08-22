#!/bin/bash
set -e

echo "🔨 [Steam] Building Linux and macOS folders..."

cd "$(dirname "$0")/.."

VERSION=$(grep -E '^local VERSION_TAG' src/version.lua | cut -d'"' -f2)
APP_NAME="Fatal Exception"

# ---------- common: make .love ----------
mkdir -p build/tmp
echo "🧩 Creating .love archive..."
(
  cd src
  # Rebuild every time for safety; comment the next line if you want to skip when unchanged
  rm -f ../build/tmp/fatal-exception.love
  zip -9 -r ../build/tmp/fatal-exception.love ./*
)

# ---------- LINUX (unchanged) ----------
echo "🐧 [Steam] Linux content..."
mkdir -p build/steam_linux_v$VERSION
cp static/love build/steam_linux_v$VERSION/
cp static/fatal-exception.png build/steam_linux_v$VERSION/ || true
cp build/tmp/fatal-exception.love build/steam_linux_v$VERSION/

cat > build/steam_linux_v$VERSION/run.sh <<'EOF'
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/love" "$DIR/fatal-exception.love"
EOF

chmod +x build/steam_linux_v$VERSION/run.sh
chmod +x build/steam_linux_v$VERSION/love
echo "✅ [Steam] Done: build/steam_linux_v$VERSION/"

# ---------- MACOS (Steam depot folder with .app bundle) ----------
LOVE_APP_SRC="static/Love.app"                                    # put LÖVE 11.5 mac app bundle here
MAC_OUT="build/steam_macos_v$VERSION"
APP_PATH="$MAC_OUT/$APP_NAME.app"

if [[ -d "$LOVE_APP_SRC" ]]; then
  echo "🍎 [Steam] macOS content..."
  rm -rf "$MAC_OUT"
  mkdir -p "$MAC_OUT"

  # Copy the app bundle; use ditto on mac to preserve bundle bits
  if [[ "$(uname)" == "Darwin" ]]; then
    ditto "$LOVE_APP_SRC" "$APP_PATH"
  else
    cp -a "$LOVE_APP_SRC" "$APP_PATH"
  fi

  # Drop your game into the bundle
  cp build/tmp/fatal-exception.love "$APP_PATH/Contents/Resources/game.love"

  # mac niceties only when running on mac (safe to skip on Linux)
  if [[ "$(uname)" == "Darwin" ]]; then
    PLIST="$APP_PATH/Contents/Info.plist"
    # Set name/display/version; identifier optional for Steam
    /usr/libexec/PlistBuddy -c "Set :CFBundleName '$APP_NAME'" "$PLIST" || /usr/libexec/PlistBuddy -c "Add :CFBundleName string '$APP_NAME'" "$PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '$APP_NAME'" "$PLIST" || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '$APP_NAME'" "$PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST" || /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$PLIST" || /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $VERSION" "$PLIST"

    # Optional: codesign (not required for Steam)
    if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
      echo "🔏 Codesigning mac app..."
      codesign --deep --force --options runtime --sign "$CODESIGN_IDENTITY" "$APP_PATH"
      codesign --verify --deep --strict "$APP_PATH" || true
    fi
  else
    echo "ℹ️ Built mac bundle on Linux (skipping plist tweaks/signing)."
  fi

  # Clean up cruft
  find "$MAC_OUT" -name ".DS_Store" -delete || true

  echo "✅ [Steam] Done: $MAC_OUT/"
else
  echo "⚠️ [Steam] Skipping macOS build: static/Love.app not found."
  echo "   Download LÖVE 11.5 for macOS and place the unzipped bundle at static/Love.app"
fi

echo "🎉 All Steam platform folders built."

#!/bin/bash
# old linux only
# set -e

# echo "🔨 [Steam] Building Linux folder..."

# cd "$(dirname "$0")/.."

# VERSION=$(grep -E '^local VERSION_TAG' src/version.lua | cut -d'"' -f2)

# mkdir -p build/tmp
# mkdir -p build/steam_linux_v$VERSION
# cp static/love build/steam_linux_v$VERSION/
# cp static/fatal-exception.png build/steam_linux_v$VERSION/ || true

# # Create .love file in build/tmp/
# cd src
# zip -9 -r ../build/tmp/fatal-exception.love ./*
# cd ..

# cp build/tmp/fatal-exception.love build/steam_linux_v$VERSION/

# # Create run.sh
# cat > build/steam_linux_v$VERSION/run.sh <<EOF
# #!/bin/bash
# DIR="\$(cd "\$(dirname "\$0")" && pwd)"
# exec "\$DIR/love" "\$DIR/fatal-exception.love"
# EOF

# chmod +x build/steam_linux_v$VERSION/run.sh
# chmod +x build/steam_linux_v$VERSION/love

# echo "✅ [Steam] Done: build/steam_linux_v$VERSION/"
