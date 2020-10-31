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
