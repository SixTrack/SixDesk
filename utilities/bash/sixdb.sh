#!/bin/bash

# get path to scripts (normalised)
if [ -z "${SCRIPTDIR}" ] ; then
    SCRIPTDIR=`dirname $0`
    SCRIPTDIR="`cd ${SCRIPTDIR};pwd`"
    export SCRIPTDIR=`dirname ${SCRIPTDIR}`
fi

# python path
source ${SCRIPTDIR}/bash/dot_profile
sixdeskDefinePythonPath

# actually call sixdb
python ${SCRIPTDIR}/externals/SixDeskDB/sixdb $*
