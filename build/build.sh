#!/bin/bash

# Name of the package.
NAME="BootUnlock"

# Once installed the identifier is used as the filename for a receipt files in /var/db/receipts/.
IDENTIFIER="au.com.openwall.$NAME"

# Package version number.
VERSION="1.3.3"

# The location to copy the contents of files.
INSTALL_LOCATION="/Library/PrivilegedHelperTools/$IDENTIFIER"

set -eu -o pipefail

WORK_DIR="${0%/*}"
[ -z "$WORK_DIR" -o "$WORK_DIR" == "$0" ] && WORK_DIR="$(pwd)" ||:

echo "WORK_DIR=$WORK_DIR"
mkdir -p "$WORK_DIR/../out" ||:

# pkgbuild need proper permissions on the source files
chmod 0755 "$WORK_DIR/../files/"*.sh
chmod 0644 "$WORK_DIR/../files/"*.xsl

# Build the "BootUnlock" keychain helper natively for both Apple Silicon and
# Intel Macs. It replaces lipo-thinning Apple's own /usr/bin/security (which
# only ships x86_64 and arm64e slices -- the arm64e one can't be re-signed by
# a third party and run without Rosetta) with a small program compiled for
# plain arm64/x86_64 that talks to the keychain itself, signed with the same
# custom identifier the System keychain ACL trusts (see files/update.sh).
clang -O2 -Wall \
	-arch x86_64 -arch arm64 \
	-framework Security -framework CoreFoundation \
	-o "$WORK_DIR/../files/$NAME" \
	"$WORK_DIR/BootUnlock.c"
codesign -f -s - "--prefix=${IDENTIFIER%$NAME}" -r="designated => identifier $IDENTIFIER" "$WORK_DIR/../files/$NAME"
chmod 0755 "$WORK_DIR/../files/$NAME"

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
