#!/bin/bash
set -e

echo "🔨 [Steam] Building Linux folder..."

cd "$(dirname "$0")/.."

mkdir -p build/tmp
mkdir -p build/steam_linux
cp static/love build/steam_linux/
cp static/fatal-exception.png build/steam_linux/ || true

# Create .love file in build/tmp/
cd src
zip -9 -r ../build/tmp/fatal-exception.love ./*
cd ..

cp build/tmp/fatal-exception.love build/steam_linux/

# Create run.sh
cat > build/steam_linux/run.sh <<EOF
#!/bin/bash
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
exec "\$DIR/love" "\$DIR/fatal-exception.love"
EOF

chmod +x build/steam_linux/run.sh
chmod +x build/steam_linux/love

echo "✅ [Steam] Done: build/steam_linux/"
