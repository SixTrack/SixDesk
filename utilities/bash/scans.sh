#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` (-h)
   to manage scans [action] [option]

   -h      displays this help

   actions
   -m      create the mask files for all studies
   -s      set all the studies
   -x      loop the given command over all studies

   options
   -c      do NOT check existence of placeholders before generating the .mask files
           effective only in case of -m action
   -l      use fort.3.local
   -d      file containining the scan definitions. Default name: ${scanDefinitionsFileNameDef}

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

scanDefinitionsFileNameDef="scan_definitions"
scanDefinitionsFileName=""

# actions
lcreatemask=false
lsetstudy=false
lcommand=false
# options
tmpCommand=""
lPlaceHolderCheck=true
llocalfort3=false

# get options (heading ':' to disable the verbose error handling)
while getopts  ":cdhlmsx:" opt ; do
    case $opt in
        c)  lPlaceHolderCheck=false ;;
        d)  scanDefinitionsFileName="${OPTARG}" ;;
	h)  how_to_use
	    exit 1
	    ;;
        l)  llocalfort3=true ;;
	m)  lcreatemask=true ;;
        s)  lsetstudy=true ;;
        x)  lcommand=true
            tmpCommand="${OPTARG}"
            ;;
	:)  how_to_use
	    echo "Option -$OPTARG requires an argument."
	    exit 1
	    ;;
	\?) how_to_use
	    echo "Invalid option: -$OPTARG"
	    exit 1
	    ;;
    esac
done
shift "$(($OPTIND - 1))"

# check actions
if ! ${lcommand} && ! ${lcreatemask} && ! ${lsetstudy} ; then
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

# file containing definition of scans
if [ -z "${scanDefinitionsFileName}" ] ; then
    scanDefinitionsFileName=${scanDefinitionsFileNameDef}
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
# - source definition of scans
source ${scanDefinitionsFileName}
# - get list of studies
get_study_names

# ------------------------------------------------------------------------------
# actions
# ------------------------------------------------------------------------------

# - create mask files:
if ${lcreatemask}; then
    if ${lPlaceHolderCheck} ; then
        sixdeskmess -1 "Checking if all placeholders are existing in mask file "
	check_mask_for_placeholders
    fi
    sixdeskmess -1 "Creating mask files"
    scan_loop generate_mask_file false false
fi

# - create the studies
if ${lsetstudy} ; then
    sixdeskmess -1 "Creating studies"
    scan_loop set_study false ${llocalfort3}
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
    case ${desiredScript} in
        mad6t.sh | run_six.sh | set_env.sh | sixdb.sh )
            # no need to run set_env.sh for loading the study, but -d option is required
            scan_loop "${SCRIPTDIR}/bash/${tmpCommand} -d" false ${llocalfort3}
            ;;
        run_results | run_status )
            # no need to run set_env.sh for loading the study, but study name is required
            scan_loop "${SCRIPTDIR}/bash/${tmpCommand}" false ${llocalfort3}
            ;;
        *)
            scan_loop "${SCRIPTDIR}/bash/${tmpCommand}" true ${llocalfort3}
            ;;
    esac
    
fi

# ------------------------------------------------------------------------------
# go home, man
# ------------------------------------------------------------------------------

sixdeskmess -1 "...done."
exit 0
