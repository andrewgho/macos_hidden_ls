#!/bin/sh
# build_ls.sh - build file_cmds/ls from Apple open source distribution
# Andrew Ho <andrew@zeuscat.com>
#
# Apple publishes source code for BSD userland system utilities such as ls.
# Building them on with modern MacOS and Xcode requires some tweaks to the
# build process and to arrange for header files to be found. This script
# automates fetching, patching, and building src/file_cmds/ls, tested on
# MacOS Monterey (12.1) with Xcode 13.2.1.
#
# To build file_cmds interactively via Xcode IDE, see this reference:
# https://medium.com/macoclock/making-ls-aware-of-hidden-files-f9f977e4077b
#
# Which was in turn based on this recipe: https://superuser.com/a/492957
#
# The patch this script writes makes the following changes:
# * Add header search paths for the various source dependencies
# * Update obsolete SDK name
# * Fix updated header path names
#
# This script leaves the patch file and a build.sh file in the src/file_cmds
# directory, which can then be used to iterate on and rebuild the code.
# Regenerate a new patch file with a command like the following:
#
#     git diff --no-prefix -p | sed 's|'$(cd .. && pwd)'|__ROOTDIR__|'
#
# This script fetches Git repositories into the current working directory.
# This script is not repeatable; if you run it multiple times, it will try
# to patch the files in src/file_cmd twice, and probably fail.

# Exit on any command failing, including in pipeline
set -e -o pipefail

# Do checkouts and builds in src directory
[ -d src ] || mkdir src
cd src

# Fetch or refresh repos from the unofficial GitHub mirror
# TODO: it might be better to fetch from: https://opensource.apple.com/source
for repo in file_cmds libinfo libutil xnu; do
    [ -d "$repo" ] || git clone "https://github.com/apple-opensource/$repo"
done

# Write patch file, fixing __ROOTDIR__ to be the current working directory.
rootdir=$(pwd)
perl -pe 's{__ROOTDIR__}{'"$rootdir"'}' > file_cmds/file_cmds.patch <<'EOF'
diff --git file_cmds.xcodeproj/project.pbxproj file_cmds.xcodeproj/project.pbxproj
index dcf7d02..f75ee68 100644
--- file_cmds.xcodeproj/project.pbxproj
+++ file_cmds.xcodeproj/project.pbxproj
@@ -3514,6 +3514,11 @@
 					COLORLS,
 				);
 				GCC_WARN_64_TO_32_BIT_CONVERSION = NO;
+				HEADER_SEARCH_PATHS = (
+					__ROOTDIR__/libinfo/membership.subproj,
+					__ROOTDIR__/libutil,
+					__ROOTDIR__/xnu,
+				);
 				INSTALL_PATH = /bin;
 			};
 			name = Release;
@@ -3675,7 +3680,7 @@
 				GCC_WARN_UNUSED_VARIABLE = YES;
 				INSTALL_PATH = /usr/bin;
 				PRODUCT_NAME = "$(TARGET_NAME)";
-				SDKROOT = macosx.internal;
+				SDKROOT = macosx;
 				VERSIONING_SYSTEM = "apple-generic";
 				WARNING_CFLAGS = (
 					"-Wall",
diff --git ls/ls.c ls/ls.c
index e079333..96dea16 100644
--- ls/ls.c
+++ ls/ls.c
@@ -75,7 +75,7 @@ __RCSID("$FreeBSD: src/bin/ls/ls.c,v 1.66 2002/09/21 01:28:36 wollman Exp $");
 #include <sys/param.h>
 #include <get_compat.h>
 #include <sys/sysctl.h>
-#include <System/sys/fsctl.h>
+#include <bsd/sys/fsctl.h>
 #else
 #define COMPAT_MODE(a,b) (1)
 #endif /* __APPLE__ */
@@ -760,6 +760,12 @@ display(FTSENT *p, FTSENT *list)
 				cur->fts_number = NO_PRINT;
 				continue;
 			}
+			/* Only display file with hidden flag if -a/-A set. */
+			sp = cur->fts_statp;
+			if ((sp && (sp->st_flags & UF_HIDDEN)) && !f_listdot) {
+				cur->fts_number = NO_PRINT;
+				continue;
+			}
 		}
 		if (cur->fts_namelen > maxlen)
 			maxlen = cur->fts_namelen;
EOF

# Apply the patch we just wrote
(cd file_cmds && patch -p0 < file_cmds.patch)

# Write build script (recipe from: https://stackoverflow.com/a/47283761)
cat > file_cmds/ls/build.sh <<'EOF'
#!/bin/sh
# build.sh - build ls and copy binary here
# Andrew Ho <andrew@zeuscat.com>

cd ..
xcodebuild -scheme ls build
build_dir=$(xcodebuild -showBuildSettings 2>&1 |
    sed -n 's/^ *TARGET_BUILD_DIR = //p')
cp "$build_dir/ls" ls/
EOF
chmod 755 file_cmds/ls/build.sh

# Run the build, and show the result
(cd file_cmds/ls && ./build.sh)
(cd .. && ls -l src/file_cmds/ls/ls)
