#!/bin/bash
set -e

# Go to project root no matter where this is run from
cd "$(dirname "$0")/.."

VERSION=$(grep 'Version.number' src/version.lua | cut -d'"' -f2)
echo "📌 Building version: $VERSION"

echo "🚀 Building all targets..."
./scripts/build_steam.sh
./scripts/build_appimage.sh
echo "🎉 All builds complete."
