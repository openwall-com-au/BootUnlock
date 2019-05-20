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
