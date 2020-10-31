#!/bin/bash

set -eu -o pipefail

PATH=/sbin:/bin:/usr/sbin:/usr/bin

report() {
	RC=$?
	echo "RC($1) = $RC (call stack: ${BASH_LINENO[@]})"
	echo "Mount points at this moment:"
	mount
	trap - EXIT; exit $RC
}

for signal in EXIT ERR HUP INT QUIT ILL TRAP ABRT EMT FPE KILL BUS SEGV SYS PIPE ALRM TERM URG STOP TSTP CONT CHLD TTIN TTOU IO XCPU XFSZ VTALRM PROF WINCH INFO USR1 USR2
do
	trap "report $signal" $signal
done

echo "=== $(date) ==="
uptime

if ! OUTPUT=$(diskutil apfs list -plist); then
	RC=$?
	echo "ERROR: diskutil failed with code $RC and produced the following output:"
	printf '>>>\n%s\n<<<\n' "$OUTPUT"
	trap - EXIT; exit 1
fi

printf '%s' "$OUTPUT" \
	| xsltproc --novalid "${0%/*}/diskutil.xsl" - \
	| sed -n '/:true:true$/{ s/:true:true$//;p; }' \
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

trap - EXIT
echo "Success"
mount
