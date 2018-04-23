#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` (-h)
   to manage scans [action] [option]

   -h      displays this help

    actions
    -M      create the mask files for all studies
    -x      loop the given command over all studies


EOF
}

# ==============================================================================
# main
# ==============================================================================

# ------------------------------------------------------------------------------
# preliminary to any action
# ------------------------------------------------------------------------------
# - get path to scripts (normalised)
if [ -z "${SCRIPTDIR}" ] ; then
    SCRIPTDIR=`dirname $0`
    SCRIPTDIR="`cd ${SCRIPTDIR};pwd`"
    export SCRIPTDIR=`dirname ${SCRIPTDIR}`
fi
# ------------------------------------------------------------------------------

# actions
lcreatemask=false
lcommand=false
# options
tmpCommand=""

# get options (heading ':' to disable the verbose error handling)
while getopts  ":hMx:" opt ; do
    case $opt in
	M)  lcreatemask=true
	    ;;
	h)
	    how_to_use
	    exit 1
	    ;;
        x)
            lcommand=true
            tmpCommand="${OPTARG}"
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

# check actions
if ! ${lcommand} && ! ${lcreatemask} ; then
    how_to_use
    echo "ERROR: no action specified"
    exit 1
fi

# check options
if ${lcommand} ; then
    if [ -z "${tmpCommand}" ] ; then
        echo "ERROR: empty command!!"
        exit 1
    fi
fi

# ------------------------------------------------------------------------------
# preparatory steps
# ------------------------------------------------------------------------------

export sixdeskhostname=`hostname`
export sixdeskname=`basename $0`
export sixdesknameshort=`echo "${sixdeskname}" | cut -b 1-15`
export sixdeskecho="yes!"
export sixdesklevel=-1
if [ ! -s ${SCRIPTDIR}/bash/dot_profile ] ; then
    echo "dot_profile is missing!!!"
    exit 1
fi
if [ ! -s ${SCRIPTDIR}/bash/dot_scan ] ; then
    echo "dot_scan is missing!!!"
    exit 1
fi
# - load environment
source ${SCRIPTDIR}/bash/dot_profile
source ${SCRIPTDIR}/bash/dot_scan
# - stuff specific to node where user is running:
sixdeskSetLocalNodeStuff

# actions:
# - create mask files:
if ${lcreatemask}; then
    sixdeskmess 1 "Creating mask file"
    scan_loop generate_mask_file
fi
# - run an actual command available in SixDesk
if ${lcommand} ; then
    # check that desired script is there
    desiredScript=(${tmpCommand})
    desiredScript=${desiredScript[0]}
    if ! [ -e "${SCRIPTDIR}/bash/${desiredScript}" ] ; then
        sixdeskmess -1 "script ${desiredScript} not available in ${SCRIPTDIR}/bash !!"
        exit 1
    fi
    scan_loop "${SCRIPTDIR}/bash/${tmpCommand}"
fi

exit 0
