#!/bin/bash

set -eu -o pipefail

PATH=/sbin:/bin:/usr/sbin:/usr/bin

echo "=== $(date) ==="
for i in {1..60}; do
diskutil apfs list -plist \
	| xsltproc --novalid "${0%/*}/diskutil.xsl" - \
	| grep -E ':true:true$' \
	| cut -f1-3 -d':' \
	| tee /dev/stderr \
	| while IFS=: read NAME UUID DEVICE ; do
		printf 'Trying to unlock volume "%s" with UUID %s ...\n' "$NAME" "$UUID"
		if ! PASSPHRASE=$(${0%/*}/BootUnlock find-generic-password \
			-D 'Encrypted Volume Password' \
			-a "$UUID" -s "$UUID" -w); then
			echo 'NOTICE: could not find the secret on the System keychain, skipping the volume.' >&2
			continue
		fi
		if ! printf '%s' "$PASSPHRASE" | diskutil apfs unlock "$DEVICE" -stdinpassphrase ; then
			if [ -z "${PASSPHRASE//[[:digit:][a-fA-F]}" ]; then # This may be a hexadecimal string
				echo 'NOTICE: the passphrase looks like a hexdecimal string, re-trying ...' >&2
				if printf '%s' "$PASSPHRASE" | xxd -r -p | diskutil apfs unlock "$DEVICE" -stdinpassphrase; then
					continue
				fi
			fi
			echo "ERROR: could not unlock volume '$NAME', skipping the volume." >&2
			continue
		fi
	done
        sleep 1
done
