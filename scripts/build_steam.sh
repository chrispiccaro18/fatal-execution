#!/bin/bash
set -e

echo "🔨 [Steam] Building Linux folder..."

cd "$(dirname "$0")/.."

VERSION=$(grep 'Version.number' src/version.lua | cut -d'"' -f2)

mkdir -p build/tmp
mkdir -p build/steam_linux_v$VERSION
cp static/love build/steam_linux_v$VERSION/
cp static/fatal-exception.png build/steam_linux_v$VERSION/ || true

# Create .love file in build/tmp/
cd src
zip -9 -r ../build/tmp/fatal-exception.love ./*
cd ..

cp build/tmp/fatal-exception.love build/steam_linux_v$VERSION/

# Create run.sh
cat > build/steam_linux_v$VERSION/run.sh <<EOF
#!/bin/bash
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
exec "\$DIR/love" "\$DIR/fatal-exception.love"
EOF

chmod +x build/steam_linux_v$VERSION/run.sh
chmod +x build/steam_linux_v$VERSION/love

echo "✅ [Steam] Done: build/steam_linux_v$VERSION/"
