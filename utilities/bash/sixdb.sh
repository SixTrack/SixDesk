#!/bin/bash

# use at least a given version of python
requiredPyVersion=2.7

function how_to_use() {
    cat <<EOF

   `basename $0` [options]
   to manage calls to sixdb

   This is mainly a bash wrapper for sixdb, and all terminal line arguments
      will be passed to sixdb BUT those preceeded by options.

   options (optional):
   -P      python path
   -d      study name
   -a      action

   NB: in case you want yo use an option, please leave the actual arguments to
       sixdb to the end of the terminal-line command;

EOF
}
# get path to scripts (normalised)
if [ -z "${SCRIPTDIR}" ] ; then
    SCRIPTDIR=`dirname $0`
    SCRIPTDIR="`cd ${SCRIPTDIR};pwd`"
    export SCRIPTDIR=`dirname ${SCRIPTDIR}`
fi

# initialisation of local vars
pythonPath=""
action=""
studyName=""

source ${SCRIPTDIR}/bash/dot_profile

# get options (heading ':' to disable the verbose error handling)
while getopts  ":hP:d:a:" opt ; do
    case $opt in
        a)
            action="${OPTARG}"
	    ;;
        d)
            studyName="${OPTARG}"
	    ;;
	h)
	    how_to_use
	    exit 1
	    ;;
	P)
	    # the user is requesting a specific path to python
	    pythonPath="${OPTARG}"
	    ;;
	:)
	    how_to_use
	    echo "Option -$OPTARG requires an argument."
	    exit 1
	    ;;
	\?)
	    how_to_use
	    echo "Invalid option: -$OPTARG"
	    exit 1
	    ;;
    esac
done
shift "$(($OPTIND - 1))"

# python path
if [ -n "${pythonPath}" ] ; then
    sixdeskDefinePythonPath ${pythonPath}
else
    sixdeskSetLocalNodeStuff
fi

# check it is python 2.7 at least
pyVer=`python --version 2>&1 | gawk '{print ($NF)}'`
if [ `sixdeskCompareVersions ${pyVer} ${requiredPyVersion}` -eq 0 ] ; then
    echo "python version too old: ${pyVer}"
    echo "please use at least ${requiredPyVersion} (included)"
    exit 1
fi

# actually call sixdb
if [ -z "${action}" ] && [ -z "${studyName}" ] ; then
    python ${SCRIPTDIR}/externals/SixDeskDB/sixdb $*
elif [ -n "${action}" ] && [ -n "${studyName}" ] ; then
    case ${action} in
        load_dir )
            python ${SCRIPTDIR}/externals/SixDeskDB/sixdb studies/${studyName} ${action}
            ;;
        da | mad )
            python ${SCRIPTDIR}/externals/SixDeskDB/sixdb ${studyName}.db ${action}
            ;;
        *)
            echo "Please specify a recognised action [load_dir|da|mad]"
            exit 1
            ;;
    esac
else
    echo "Please specify both -d and -a options at the same time or nothing"
    exit 1
fi

exit 0
