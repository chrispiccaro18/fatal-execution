#!/bin/bash
set -e

echo "📦 [AppImage] Building..."

cd "$(dirname "$0")/.."

VERSION=$(grep 'Version.number' src/version.lua | cut -d'"' -f2)

if [ ! -f build/tmp/fatal-exception.love ]; then
  echo "⚠️ build/tmp/fatal-exception.love not found. Run build_steam.sh first or generate it."
  exit 1
fi

rm -rf build/tmp/appdir
mkdir -p build/tmp/appdir/usr/bin

cp static/love build/tmp/appdir/usr/bin/
cp build/tmp/fatal-exception.love build/tmp/appdir/usr/bin/

# AppRun
cat > build/tmp/appdir/AppRun <<EOF
#!/bin/bash
HERE="\$(dirname "\$(readlink -f "\$0")")"
exec "\$HERE/usr/bin/love" "\$HERE/usr/bin/fatal-exception.love"
EOF

chmod +x build/tmp/appdir/AppRun

# Desktop file
cat > build/tmp/appdir/fatal-exception.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Fatal Exception
Exec=AppRun
Icon=fatal-exception
Categories=Game;
EOF

cp static/fatal-exception.png build/tmp/appdir/ || true

# Build
OUTPUT_NAME="fatal-exception-v$VERSION.AppImage"
appimagetool build/tmp/appdir "build/$OUTPUT_NAME"


echo "✅ [AppImage] Done: build/$OUTPUT_NAME"
