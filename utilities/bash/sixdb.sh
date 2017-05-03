#!/bin/bash

# python path
PYTHONPATH="/afs/cern.ch/work/r/rdemaria/public/anaconda/bin"

# get path to scripts (normalised)
if [ -z "${SCRIPTDIR}" ] ; then
    SCRIPTDIR=`dirname $0`
    SCRIPTDIR="`cd ${SCRIPTDIR};pwd`"
    export SCRIPTDIR=`dirname ${SCRIPTDIR}`
fi

# actually call sixdb
${PYTHONPATH}/python ${SCRIPTDIR}/externals/SixDeskDB/sixdb $*
