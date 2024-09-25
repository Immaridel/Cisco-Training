#!/bin/sh

# First component of PYTHONPATH is the python/ directory in our package
PKG_PATH=$(dirname $(echo ${PYTHONPATH} | awk -F: '{ print $1 }'))

# Look for virtualenv in our package and activate, if found
if [ -n "${PKG_PATH}" ] && [ -f "${PKG_PATH}/pyvenv/bin/activate" ]; then
    echo "Found virtualenv for ${PKG_NAME}, activating it";
    . ${PKG_PATH}/pyvenv/bin/activate;
fi

pypath="${NCS_DIR}/src/ncs/pyapi"

# Make sure everyone finds the NCS Python libraries at startup
if [ "x$PYTHONPATH" != "x" ]; then
    PYTHONPATH=${pypath}:$PYTHONPATH
else
    PYTHONPATH=${pypath}
fi
export PYTHONPATH

# Parse arguments to extract the VM ID value passed with -i|--id. This is then
# used to compare against the value of the DEBUGPY env var. Remote debugging
# will be enabled for the Python VM with the name provided by the DEBUGPY
# variable. We use GNU getopt here to make sure we're always able to recognize
# the arguments, even if the order changes. In addition to VM ID we also handle
# -u|--upgrade, to simplify setting the main executable name.
OPTS="$@"
TEMP=`getopt -o l:f:i:u --long log-level:,log-file:,id:,upgrade -n 'ncs-start-python-vm' -- "$@"`
#if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

main="${pypath}/ncs_pyvm/startup.py"
while true; do
    case "$1" in
        -u | --upgrade ) main="${pypath}/ncs_pyvm/upgrade.py"; shift ;;
        -i | --id ) VMID="$2"; shift 2 ;;
        -- ) shift; break ;;
        * ) if [ "$#" -gt 0 ]; then shift; else break; fi ;;
    esac
done

if [ -x "$(which python3)" ]; then
    PYTHON=python3
else
    PYTHON=python
fi

if [ -n "${DEBUGPY}" ] && [ "${DEBUGPY}" = "${VMID}" ]; then
    DEBUG=$(${PYTHON} -c 'import debugpy' > /dev/null 2>&1 && echo '-m debugpy --listen 0.0.0.0:5678')
    echo "Enabling DAP for PythonVM ${VMID}"
else
    DEBUG=""
    echo "DAP not enabled for PythonVM ${VMID}"
fi

echo "Starting ${PYTHON} -u ${DEBUG} ${main} ${OPTS}"
exec ${PYTHON} -u ${DEBUG} ${main} ${OPTS}