#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [option]
   crontab job for retrieving results from boinc buffer dirs

   options
   -f      file containing workspaces and studies to be checked
           the user can specify as many files as desired. Each file must
             preceeded by a -f
   -w      workspace to be checked
   -s      study to be checked. A -s option is required for any study to
             be checked. The study will be looked into the last workspace
             specified.

   example:
   `basename $0`  -f ./checkList.txt -w /afs/cern.ch/user/g/goofy/w1/sixjobs -s study01 -s study02 -s study03
             
   In case the option -f is used, the file looks like:
# retrieve results of studies in w1
/afs/cern.ch/user/g/goofy/w1/sixjobs        myStudy01 myStudy03 myStudy230
# retrieve results of studies in ws_LHC
/afs/cern.ch/user/g/goofy/ws_LHC/sixjobs    all_octu_213 all_octu_pos_341

EOF
}

function parseFile(){
    local __allActiveLines=`grep -v '#' ${tmpFile}`
    local __nL=`echo "${__allActiveLines}" | wc -l`
    for (( ii=1; ii<=${__nL} ; ii++ )) ; do
	local __line=`echo "${__allActiveLines}" | head -n ${ii} | tail -1`
	local __data=( ${__line} )
	tmpworkspace="${__data[0]}"
	checkWS
	for (( jj=1; jj<${#__data[@]}; jj++ )) ; do
	    tmpstudy="${__data[$jj]}"
	    getStudy
	done
    done
}

function checkWS(){
    if [ ! -d ${tmpworkspace} ] ; then
	echo " workspace ${tmpworkspace} not reachable!"
	echo " aborting..."
	exit 1
    else
	# remove trailing slashes
	tmpworkspace=`echo ${tmpworkspace} |  sed 's:/*$::'`
    fi
}

function getStudy(){
    if [ -z "${tmpworkspace}" ] ; then
	echo " no workspace specified for study ${tmpstudy}!"
	echo " aborting..."
	exit 1
    else
	if [ -z "${tmpstudy}" ] ; then
	    echo " no study specified!"
	    echo " aborting..."
	    exit 1
	fi
	# remove trailing slashes
	tmpstudy=`echo ${tmpstudy} |  sed 's:/*$::'`
	studyDir=`printf "${studytree}" "${tmpworkspace}" "${tmpstudy}"`
	if [ ! -d ${studyDir} ] ; then
	    echo " study ${tmpstudy} not reachable!"
	    echo " fullpath: ${studyDir}"
	    echo " aborting..."
	    exit 1
	else
	    workspaces="${workspaces} ${tmpworkspace}"
	    studies="${studies} ${tmpstudy}"
	fi
    fi
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

# actions and options
tmpworkspace=""
tmpstudy=""
workspaces=""
studies=""
studytree="%s/studies/%s"

# get options (heading ':' to disable the verbose error handling)
while getopts  ":hf:w:s:" opt ; do
    case $opt in
	f)
	# get workspaces/studies from file
	    tmpFile="$OPTARG"
	    parseFile
	    ;;
	w)
	    # new workspace
	    tmpworkspace="$OPTARG"
	    checkWS
	    ;;
	s)
	    # new study
	    tmpstudy="$OPTARG"
	    getStudy
	    ;;
	h)
	    how_to_use
	    exit 1
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

if [ -z "${studies}" ] ; then
    how_to_use
    echo " no study requested."
    exit 1
else
    studies=( ${studies} )
    workspaces=( ${workspaces} )
fi

# actual script:
for (( ii=0 ; ii<${#studies[@]} ; ii++ )) ; do
    echo " retrieving BOINC results of study ${studies[$ii]} in workspace ${workspaces[$ii]} ..."
    cd ${workspaces[$ii]}
    ${SCRIPTDIR}/bash/run_results ${studies[$ii]} boinc
    echo " getting ready for new study..."
    cd - > /dev/null 2>&1
done

# done
echo " ...done."
