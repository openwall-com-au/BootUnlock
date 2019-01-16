#!/bin/bash

set -eu -o pipefail

PATH=/sbin:/bin:/usr/sbin:/usr/bin

[ "$(id -un)" = root ] \
	|| exec -a "$0" osascript -e "
		do shell script quoted form of \"$0\" & space & quoted form of \"$*\" with prompt \"BootUnlock Configurator requires administrative privileges to work with volumes and to update the System keychain.\" with administrator privileges" \
	|| exit 1

# Location of the log file
LOG_FILE=/var/log/BootUnlock.log

# Determine the cannonical location of this script
WORK_DIR="${BASH_SOURCE%/*}"
[ "$WORK_DIR" != "$BASH_SOURCE" ] || WORK_DIR=.
pushd "$WORK_DIR" &>/dev/null
WORK_DIR=$(pwd -P)
popd &>/dev/null
SELF="$WORK_DIR/${0##*/}"

printf 'Redirecting standard output and errors to "%s" ...\n' "$LOG_FILE"
exec >>"$LOG_FILE" 2>&1
printf '===[ update.sh: %s ]===\n' "$(date)"

# A quick and dirty way of determining the root device :)
ROOT_DEVICE=$(df -l / | grep -E '^/dev/' | cut -f1 -d' ' | head -1 | cut -f3- -d/)

# Get the list of volumes with the encryption enabled
IFS=$'\n' VOLUME=($(diskutil apfs list -plist \
		| xsltproc --novalid "${0%/*}/diskutil.xsl" - \
		| grep -E ':true:(true)?$' \
		| cut -f1-3 -d':' \
))

# Generate a list of volumes for GUI
VOLUME_LIST=
for V in "${VOLUME[@]}" ; do
	NAME="${V%%:*}";	V="${V#*:}"
	UUID="${V%%:*}";	V="${V#*:}"
	DEVICE="${V%%:*}";	V="${V#*:}"

	# macOS can automatically mount the system volume, so there is no point
	# of presenting that choice to the user
	[ "$DEVICE" != "$ROOT_DEVICE" ] || continue

	VOLUME_LIST="$VOLUME_LIST${VOLUME_LIST:+, }\"$DEVICE > $NAME\""
done

RESPONSE=$(osascript -e "
	set volumeList to { $VOLUME_LIST }
	set unlockList to choose from list volumeList with title \"BootUnlock\" with prompt \"
Please select volume(s) you want to be automatically unlocked during the boot (you can select multiple volumes by holding the Option key)\" multiple selections allowed true empty selection allowed true
")

if [ -z "$RESPONSE" -o "$RESPONSE" = false ]; then
	osascript -e "display alert \"BootUnlock\" message \"
You did not select any volumes, so BootUnlock is not going to do anything at the system boot up time.

If you reconsider and will want to enable unlocking of a particular volume you can re-run the '$SELF' script at a later time
\" as critical" &>/dev/null
	exit 0
fi

RESPONSE="$(printf '%s' "$RESPONSE" | tr ',' '\n' | sed 's,^[[:space:]]*,,;s,>.*$,,;s,[[:space:]]*$,,')"

# Real work starts here :)
for V in "${VOLUME[@]}" ; do
	NAME="${V%%:*}";	V="${V#*:}"
	UUID="${V%%:*}";	V="${V#*:}"
	DEVICE="${V%%:*}";	V="${V#*:}"

	# We are going to work only on the volumes selected by the user
	printf '%s' "$RESPONSE" | grep -E "^$DEVICE\$" &>/dev/null || continue

	while : ; do # This is a wrapper in case user provides a wrong password
		PASSPHRASE=$(osascript -e "
			display dialog \"Please provide the passphrase for volume '$NAME':\" with title \"BootUnlock\" buttons { \"Skip\", \"Unlock\" } default button \"Unlock\" with icon file ((path to \"apps\" as text) & \"Utilities:Disk Utility.app:Contents:Resources:AppIcon.icns\") default answer \"\" hidden answer true
		")

		PASSPHRASE=$(printf '%s' "$PASSPHRASE" | cut -f3- -d:)

		if printf '%s' "$PASSPHRASE" | diskutil apfs unlock "$DEVICE" -stdinpassphrase -verify -user "$UUID"; then
			printf 'Adding password for volume "%s" with UUID %s to the System keychain...\n' "$NAME" "$UUID"
			if sudo /usr/bin/security add-generic-password \
				-a "$UUID" -s "$UUID" -l "$NAME" \
				-D 'Encrypted Volume Password' \
				-T '' -T "$WORK_DIR/BootUnlock" \
				-w "$PASSPHRASE" \
				-U \
				/Library/Keychains/System.keychain; then
				break
			else
				osascript -e "display alert \"BootUnlock\" message \"
BootUnlock experienced an internal error while adding password to the System keychain.

Please check the /var/log/BootUnlock.log log file for more information.
\" as critical" &>/dev/null
				exit 1
			fi
		else
			osascript -e "display alert \"BootUnlock\" message \"
The specified password for volume '$NAME' does not seem to be valid.  BootUnlock will prompt you for the password again.

If you believe that you are providing the correct password, yet it is not recognised, please check the /var/log/BootUnlock.log log file for more information.
\" as critical" &>/dev/null
		fi
	done
done

