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
