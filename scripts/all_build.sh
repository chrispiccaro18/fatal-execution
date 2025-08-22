#!/bin/bash
set -e

# Go to project root no matter where this is run from
cd "$(dirname "$0")/.."

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Extract version string
VERSION=$(grep -E '^local VERSION_TAG' src/version.lua | cut -d'"' -f2)
echo -e "📌 Building version: ${GREEN}${VERSION}${NC}"

LAST_FILE=".last_build_version"
if [[ -f "$LAST_FILE" ]]; then
    LAST_VERSION=$(cat "$LAST_FILE")
    if [[ "$LAST_VERSION" == "$VERSION" ]]; then
        echo -e "${YELLOW}⚠️  WARNING:${NC} VERSION_TAG (${VERSION}) is the same as the last build."
        read -p "Continue anyway? (y/N): " OVERRIDE
        if [[ ! "$OVERRIDE" =~ ^[Yy]$ ]]; then
            echo -e "${RED}❌ Build aborted.${NC}"
            exit 1
        fi
    fi
fi

# Show the checklist: print initial comment block from src/version.lua
echo -e "📝 ${GREEN}Update checklist from src/version.lua:${NC}"
echo "------------------------------------------------------------"
awk '
  # Print only the initial consecutive comment lines at the top
  /^[[:space:]]*--/ { 
    # strip leading comment markers for readability
    sub(/^[[:space:]]*--[[:space:]]?/, "", $0); 
    print; 
    next 
  }
  { exit }  # stop at the first non-comment line
' src/version.lua
echo "------------------------------------------------------------"

# Prompt for confirmation
read -p "❓ Did you bump the version and go through the checklist above? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo -e "${RED}❌ Build aborted. Please bump version & review checklist before building.${NC}"
  exit 1
fi

echo -e "🚀 ${GREEN}Building all targets...${NC}"
./scripts/build_steam.sh
# ./scripts/build_appimage.sh

if [[ "$(uname)" == "Darwin" ]]; then
  echo -e "🍎 ${GREEN}Building macOS...${NC}"
  ./scripts/build_macos.sh
else
  echo -e "🍎 ${YELLOW}Skipping macOS build (not on macOS).${NC}"
fi

echo "$VERSION" > "$LAST_FILE"

echo -e "🎉 ${GREEN}All builds complete.${NC}"
