#!/bin/bash
# Create python virtualenvs for NSO package based on a requirements(-dev).txt
# file(s)
#
# It is possible to either define a single virtualenv, which is used both at run
# time and build time, or to define a virtualenv for run time and another
# "development" virtualenv that is used at build time.
# The presence of src/requirements.txt will automatically build a virtualenv in
# pyvenv/ which is activated at run time and if it is the only virtualenv
# present (pyvenv-dev/ does not exist), it will also be activated at build time.
# However, if src/requirements-dev.txt is present, it will be used to build a
# virtualenv in pyvenv-dev/ that is used at build time. It is *strongly*
# recommended to let requirements-dev.txt be a superset of requirements.txt by
# including requirements.txt from requirements-dev.txt. To include, put this in
# requirements-dev.txt:
#   -r requirements.txt

# Change directory into the package provided as first argument
cd $1

if [ -f "src/requirements-dev.txt" ]; then
    # use --system-site-packages to be able to use already installed things,
    # like pylint (which is built with the venv activated), without also having
    # to install it in our venv
    python3 -m venv --symlinks --system-site-packages --clear pyvenv-dev
    # venv starts by resolving the symlink of its own location, thus doesn't
    # think /var/opt/ncs/packages/ is its location but /src/(test-)?packages
    # - we fix that with sed...
    sed -e 's,/src/\(test-\)\?packages/,/var/opt/ncs/packages/,' -i pyvenv-dev/bin/activate
    . pyvenv-dev/bin/activate
    # we ignore-installed to installed things even thought they are already
    # installed in the system as otherwise we depend on the system packages and
    # as those can shift between the -dev container and the -base container we
    # might get unexpected results
    pip3 install -r src/requirements-dev.txt --ignore-installed
    chown -R $(ls -nd /src | awk '{ print $3":"$4 }') pyvenv-dev
    deactivate
fi

if [ -f "src/requirements.txt" ]; then
    # use --system-site-packages to be able to use already installed things,
    # like pylint (which is built with the venv activated), without also having
    # to install it in our venv
    python3 -m venv --symlinks --system-site-packages --clear pyvenv
    # venv starts by resolving the symlink of its own location, thus doesn't
    # think /var/opt/ncs/packages/ is its location but /src/(test-)?packages
    # - we fix that with sed...
    sed -e 's,/src/\(test-\)\?packages/,/var/opt/ncs/packages/,' -i pyvenv/bin/activate
    . pyvenv/bin/activate
    # we ignore-installed to installed things even thought they are already
    # installed in the system as otherwise we depend on the system packages and
    # as those can shift between the -dev container and the -base container we
    # might get unexpected results
    pip3 install -r src/requirements.txt --ignore-installed
    chown -R $(ls -nd /src | awk '{ print $3":"$4 }') pyvenv
    # TODO: strip away pip etc to reduce size of venv?
    deactivate
fi