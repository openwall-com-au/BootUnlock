# BootUnlock
A helper script that unlocks macOS'es encrypted APFS volumes before login

The idea behind this package was to leverage the standard system tools to overcome
the limitation of macOS.  A quick search on the Internet showed that similar tools
were created obviously by developers who are eager to write something up from
scratch.  However, good engineering requires critical thinking and if the problem
can be addressed using the existing tools, then this is the challenge worth
puzzling your head with.  The entire package is using bash scripting language only.

To build an macOS package you can either use "make" (if you have Xcode
installed) or just run "build/build.sh" (if you do not want to install Xcode).
The result will be the same: a package is going to be created in the "out"
directory.

Alternatively, if you do not want to build the package yourself, you can grab the
premade one from the [releases](../../releases) section here.

To install the package just open it in Finder and follow the installation prompts.

## Use case

The typical usage scenario is the following:

1. One adds a dedicated encrypted APFS volume to hold home directories for the
   normal users on the system (e.g. by going to the Disk Utility application and
   adding a volume over there as an administrator);
2. The newly created volume is manually mounted by the administrator;
3. Then the required home directories need to be moved over to that new volume
   (use Finder as an administrator and drag and drop the folders, this will
   ensure that all the necessary permissions and extended attributes are
   preserved -- you cannot easily copy over a home directory via the Terminal
   application, unfortunately);
4. Now, to modify the home directory for the required users, one need to open
   System Setting (or System Preferences in older macOS versions), find the
   "Users & Groups" section, and after right-clicking on a user account, select
   "Advanced Options ...": there the home directory can be changed to point to
   the new volume;
5. Finally, this is where BootUnlock comes in: to automatically unlock the newly
   created volume for home directories upon the user login, install BootUnlock
   and specify the password for the volume during the installation.

This approach allows you to easily upgrade macOS (or even run different versions
of macOS on different APFS volumes), yet have your user data intact and in one
place.  For example, you may want to trial a new beta of macOS by creating a new
APFS volume, installing the beta over there, then attach the volume with home
directories to that new installation, and update your account in the beta to use
the home directory on that volume: your home will be shared between two versions
of macOS with all the settings preserved.  There is a slight chance that the new
macOS version may make an incompatible change to the preferences which would not
be recognised by the older version, but I was running Yosemite, Big Sur, Catalina,
and Monterey -- switching between them regularly and did not experience any issues.
