#!/bin/bash
# Build script for Ultimate-Debian-Updater .deb package

set -e

# Extrahiere Version aus der Hauptdatei
VERSION=$(grep '^VERSION=' update.sh | cut -d'"' -f2)
APP_NAME="ultimate-debian-updater"
MAINTAINER="Daniel Frey <https://github.com/DerLinke>"
DESCRIPTION="Automated, intelligent update system for Debian-based systems"

ARCH=$(dpkg --print-architecture)
DEB_NAME="${APP_NAME}_${VERSION}_${ARCH}"
BUILD_DIR="dist/build_deb_temp"

echo "󰚌 Building $DEB_NAME..."

mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/doc/$APP_NAME"

# Create control file
cat <<EOF > "$BUILD_DIR/DEBIAN/control"
Package: $APP_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: $MAINTAINER
Depends: bash, apt, curl, wget, git
Conflicts: update
Description: $DESCRIPTION
EOF

# Install files
cp update.sh "$BUILD_DIR/usr/bin/ultimate-debian-updater"
chmod 755 "$BUILD_DIR/usr/bin/ultimate-debian-updater"
cp README.md LICENSE "$BUILD_DIR/usr/share/doc/$APP_NAME/"

# Build package
dpkg-deb --root-owner-group --build "$BUILD_DIR" "${DEB_NAME}.deb"
rm -rf "$BUILD_DIR"

echo "✅ Package created: ${DEB_NAME}.deb"
