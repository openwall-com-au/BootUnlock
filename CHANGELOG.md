1.3.1
-----

- Fixed a bug where the installation script went into the infinite loop asking
  the user for volume's password with no way to cancel the activity;
- Hopefully, addressed an issue where the installation script was not waiting
  for Xcode's installation to complete.

1.3.0
-----

- Added support for ARM-based Macs (e.g. Macbook Pro M2);
- Added the "preinstall" script with a check and a conditional installation of
  the Xcode command-line tools;
- changed the way BootUnlock binary is created from /usr/sbin/security, now
  the lipo tool is used to extract the x86_64 part from the universal Mach-O
  binary.  This allows running it with a adhoc signature on the ARM-based Macs.

1.2.1
-----

- Improved debugging output;
- Replaced "grep" and "cut" with "sed" to avoid "grep" triggering an early exit;
- Removed "RunAtLoad" in the service definition, so the helper script is
  triggered only on "mount" events;

1.2.0
-----
- Replaced some calls to "osascript" where AppleScript was hitting new security
  measures introduced in Catalina with JXA (Javascript for Apps).  This should
  enable the package to work on Catalina.

1.1.0
-----
- Switched to (Semantic Versioning)[https://semver.org/] for the package
- Changed the trigger for launching the helper script, now it will be triggered
  on the "mount" event when a new volume is detected.  This allows to eject and
  re-insert the external encrypted APFS volumes and should help with the volumes
  that take a bit of time to be available for macOS to use.
- Cosmetic fixes in the 'postinstall' script.

1.0
---
- Initial release
