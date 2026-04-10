#!/bin/bash
set -euo pipefail

APP_NAME="Brewbar"
BUILD_DIR="build/Release"
DMG_NAME="${APP_NAME}.dmg"
STAGING_DIR=$(mktemp -d)

echo "Creating DMG..."

# Copy app to staging
cp -R "${BUILD_DIR}/${APP_NAME}.app" "${STAGING_DIR}/"

# Create symlink to Applications
ln -s /Applications "${STAGING_DIR}/Applications"

# Create DMG
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov -format UDZO \
    "${DMG_NAME}"

# Cleanup
rm -rf "${STAGING_DIR}"

echo "Created ${DMG_NAME}"
