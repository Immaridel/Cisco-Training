#!/bin/bash

# This script is called from the testenv-build make target - it is not meant to
# be run manually.

# testenv-build does an incremental recompile of packages and loads them in to a
# running NSO instance through the most efficient way.
#
# Source files are rsynced over, to only copy the things that have changed.
# Packages are then built, as the old build output is still present the build
# will be incremental and only rebuild things that have been updated. This
# assumes the makefile for the project correctly declares dependencies.
# The rsync operation is analyzed (by looking at the log) to determine what
# files were updated and based on that either reload all package or selectively
# redeploy individual packages.
#
# Package redeploy is treated differently pre and post NSO 5.3. ENG-20488,
# released in NSO 5.3, made large improvements to package redeploy, before it,
# changed configuration template required a package reload. We take this into
# account by first looking at the NSO version.
#
# Note how the package name can be different from the package directory name,
# thus we use xmlstarlet to get the package name from package-meta-data.xml.
#
# A full package reload can be forced by setting PACKAGE_RELOAD to anything
# non-empty.
#
# build-meta-data.xml is also generated for packages that do not ship / build
# one themselves. Note how NSO only reads in build-meta-data.xml on package
# *reload*. A package *redeploy* will thus lead to a stale view in NSO. Since we
# always update build-meta-data.xml on every invocation of testenv-build, it
# would if properly honored always lead to a package reload, which is clearly
# not what we want.

# Determine NSO version with major / minor version component
if [[ $(ncs --version) =~ ^([0-9]+)\.([0-9]+) ]]; then
    NSO_VERSION_MAJOR=${BASH_REMATCH[1]}
    NSO_VERSION_MINOR=${BASH_REMATCH[2]}
else
    echo "Not a proper NSO version"
    exit 1
fi

# Determine if our NSO supports the new package redeploy that was introduced in
# NSO version 5.3
SUPPORTS_NEW_REDEPLOY=$(if [ ${NSO_VERSION_MAJOR} -gt 5 ] || [ ${NSO_VERSION_MAJOR} -eq 5 -a ${NSO_VERSION_MINOR} -ge 3 ]; then echo "true"; fi)

if [ "${SUPPORTS_NEW_REDEPLOY}" = "true" ]; then
    RELOAD_PATTERN="(^package-meta-data.xml$|\.cli$|\.yang$)"
else
    RELOAD_PATTERN="(^package-meta-data.xml$|templates/.*\.xml$|\.cli$|\.yang$)"
fi
echo ${RELOAD_PATTERN}

# Copy in new source using rsync. Exclude Emacs and vim temp files.
# grep -v is for ignoring directory changes. We just care about changed files.
rsync -aEim --exclude '.#*' --exclude '.*.sw[a-p]' /src/packages/. /src/test-packages/. /var/opt/ncs/packages/ | grep -v "^\.d\.\.t\.\.\.\.\.\. " > /tmp/rsync.log
for PKG_SRC in $(find /src/packages /src/test-packages -mindepth 1 -maxdepth 1 -type d); do
    export PKG_NAME=$(basename ${PKG_SRC});
    export PKG_DIR=/var/opt/ncs/packages/${PKG_NAME}/
    if [ -f "${PKG_DIR}pyvenv/bin/activate" ]; then . ${PKG_DIR}pyvenv/bin/activate; fi;
    make -C /var/opt/ncs/packages/${PKG_NAME}/src || exit 1;
    if [ -f "${PKG_DIR}pyvenv/bin/activate" ]; then deactivate; fi;
    OUTPUT_PATH=${PKG_DIR}/ make -f /src/nid/bmd.mk -C ${PKG_SRC} build-meta-data.xml;
done

# Analyze what files were transferred and if we need to reload packages or
# redeploy individual packages
egrep ${RELOAD_PATTERN} /tmp/rsync.log >/dev/null
if [ $? -eq 0 ] || [ -n "${PACKAGE_RELOAD}" ]; then
    echo "-- Reloading packages for NSO ${NSO}";
    echo "request packages reload force" | ncs_cli -u admin
else
    for PKG in $(sed -E 's,^........... ([^/]+).*,\1,' /tmp/rsync.log | sort | uniq); do
        echo "-- Redeploying package ${PKG} for NSO ${NSO}";
        PKG_NAME=$(xmlstarlet sel -N x=http://tail-f.com/ns/ncs-packages -t -v "/x:ncs-package/x:name" -nl /var/opt/ncs/packages/${PKG}/package-meta-data.xml) && \
            echo "request packages package ${PKG_NAME} redeploy" | ncs_cli -u admin
    done
fi