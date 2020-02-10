#!/bin/bash

# Name of the package.
NAME="BootUnlock"

# Once installed the identifier is used as the filename for a receipt files in /var/db/receipts/.
IDENTIFIER="au.com.openwall.$NAME"

# Package version number.
VERSION="1.2.0"

# The location to copy the contents of files.
INSTALL_LOCATION="/Library/PrivilegedHelperTools/$IDENTIFIER"

set -eu -o pipefail

WORK_DIR="${0%/*}"
[ -z "$WORK_DIR" -o "$WORK_DIR" == "$0" ] && WORK_DIR="$(pwd)" ||:

mkdir -p "$WORK_DIR/../out" ||:

# pkgbuild need proper permissions on the source files
chmod 0755 "$WORK_DIR/../files/"*.sh
chmod 0644 "$WORK_DIR/../files/"*.xsl

# Build package.
/usr/bin/pkgbuild \
	--identifier "$IDENTIFIER" \
	--version "$VERSION" \
	--install-location "$INSTALL_LOCATION" \
	--root "$WORK_DIR/../files" \
	--scripts "$WORK_DIR/../scripts" \
	"$WORK_DIR/../out/$NAME-$VERSION-dist.pkg"

/usr/bin/productbuild \
	--distribution "$WORK_DIR/Distribution.xml" \
	--package-path "$WORK_DIR/../out" \
        --resources "$WORK_DIR/../resources" \
	"$WORK_DIR/../out/$NAME-$VERSION.pkg"

rm "$WORK_DIR/../out/$NAME-$VERSION-dist.pkg"
