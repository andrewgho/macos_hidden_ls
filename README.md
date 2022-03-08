macos_hidden_ls - build MacOS ls that skips hidden files
========================================================

This repository contains a build script and patch that modifies the open
source `ls` program for MacOS published by Apple so that it skips showing
files or directories marked with the hidden flag (as per `chflags(1)`).

Getting Started
---------------

To build from scatch:

    $ ./build_ls.sh

This will check out the appropriate source files in the `src` directory, and
leave a build artifact in `src/file_cmds/ls/ls`. To test if it works, you can
do something like this:

    $ echo normal > normal.txt
    $ echo hidden > hidden.txt
    $ /bin/ls
    $ src/file_cmds/ls/ls
    $ chflags hidden hidden.txt
    $ /bin/ls
    $ src/file_cmds/ls/ls

Description
-----------

Normally files and directories with the hidden flag are hidden from the GUI,
but remain visible via command line `ls`. With this patch, hidden files and
directories are treated the same as files and directories whose names begin
with a dot: they are not shown unless the `-a` flag is passed.

Apple publishes source code for BSD userland system utilities such as `ls`.
However, building them on with modern MacOS and Xcode requires some tweaks to
the build process, and to arrange for header files to be found. The script
in this repository automates fetching, patching, and building `ls`. It is
tested on MacOS Monterey (12.1) with Xcode 13.2.1, recent as of Q1 2022.

The patch this script writes makes the following changes:

* Add header search paths for the various source dependencies
* Update obsolete SDK name
* Fix updated header path names
* Patch `ls` to treat the hidden files similarly to dot files

The script leaves the patch file and a build.sh file in the `src/file_cmds`
directory, which can then be used to iterate on and rebuild the code if you
have a different change you wish to make. Regenerate a new patch file with a
command like the following:

    git diff --no-prefix -p | sed 's|'$(cd .. && pwd)'|__ROOTDIR__|'

The script fetches Git repositories into the current working directory.
The script is not repeatable; if you run it multiple times, it will try
to patch the files in `src/file_cmd` twice, and probably fail.

References
----------

To build file_cmds interactively via Xcode IDE, see this reference:
https://medium.com/macoclock/making-ls-aware-of-hidden-files-f9f977e4077b

That recipe was in turn based on this Superuser answer:
https://superuser.com/a/492957

Author
------

Andrew Ho (<andrew@zeuscat.com>)

License
-------

Apple is a registered trademark of Apple, Inc.
Apple, Inc. does not sponsor, authorize or endorse this codebase.
The files in this repository are authored by Andrew Ho, and are covered by
the following MIT license:

    Copyright 2020 Andrew Ho

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without
    restriction, including without limitation the rights to use, copy,
    modify, merge, publish, distribute, sublicense, and/or sell copies
    of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
