#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [option]
   script for controlling sequential calls to sixdesk scripts.
      STDERR and STDOUT are redirected to log files like:
                                          <study_name>_<script_name>.log
      in the workspace of the current study.

   actions [mandatory]
   -M      -> mad6t.sh -s -d <study_name>
   -S      -> run_six.sh -a -d <study_name>
   -R      -> run_results <study_name> BOINC
   -U      -> user-defined operation
              in this case, it is user's reposnibility to provide the command line between
                 SINGLE QUOTEs, with the correct name of the script with its fullpath, e.g.:
              `basename $0` -f ./checkList.txt -U '/full/path/to/script.sh -<flag> \\
                                    \${studies[\$ii]} > \${studies[\$ii]}.log 2>&1'
              NB: the variable \${SCRIPTDIR}:
                     ${SCRIPTDIR}
                  is available to the user.
              NBB: the user should also explicitely state the redirection of STDOUT/STDERR
   -B      -> backUp.sh <study_name> (not yet available!)
   for the time being, only one action at a time can be requested

   options
   -f      file containing workspaces and studies of interest
           the user can specify as many files as desired. Each file must
             preceeded by a -f
   -w      fullpath to workspace where the study of interest is located
             (including sixjobs dir)
   -s      study of interest. A -s option is required for every study of
             interest. The study must be in the last workspace specified.
           The special name ALL indicates all studies in a workspace
   -k      triggers a kinit before doing anything:
           N: a brand new kerberos token is generated (password requested!)
           R: the exising kerberos token is renewed (no password needed, but
              pay attention to max renewal date of token)

   example:
   `basename $0` -k N -R -f ./checkList.txt \\
                 -w /afs/cern.ch/user/g/goofy/w1/sixjobs -s study01 -s study02 -s study03
             
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
	    tmpStudy="${__data[$jj]}"
	    getStudy
	done
    done
}

function checkWS(){
    if [ ! -d ${tmpworkspace} ] ; then
	how_to_use
	echo " workspace ${tmpworkspace} not reachable!"
	exit 1
    else
	# remove trailing slashes
	tmpworkspace=`echo ${tmpworkspace} |  sed 's:/*$::'`
    fi
}

function getStudy(){
    if [ -z "${tmpworkspace}" ] ; then
	how_to_use
	echo " no workspace specified for study ${tmpStudy}!"
	exit 1
    else
	if [ -z "${tmpStudy}" ] ; then
	    how_to_use
	    echo " no study requested!"
	    exit 1
	fi
	# remove trailing slashes
	local __tmpStudy=`echo ${tmpStudy} |  sed 's:/*$::'`
	if [ "${__tmpStudy}" == "ALL" ] ; then
	    local __allStudies=`ls -1d ${tmpworkspace}/studies/*/`
	    for tmpStudy in ${__allStudies} ; do
		tmpStudy=`basename ${tmpStudy}`
		getStudy
	    done
	else
	    studyDir="${tmpworkspace}/studies/${__tmpStudy}"
	    if [ ! -d ${studyDir} ] ; then
		echo " study ${tmpStudy} not reachable at ${studyDir}!"
		exit 1
	    else
		workspaces="${workspaces} ${tmpworkspace}"
		studies="${studies} ${__tmpStudy}"
	    fi
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
tmpStudy=""
workspaces=""
studies=""
lmad=false
lrunsix=false
lrunres=false
lbackup=false
luser=false
lkinit=false
lkrenew=false

# get options (heading ':' to disable the verbose error handling)
while getopts  ":MSRBU:hf:w:s:k:" opt ; do
    case $opt in
	M)
	    lmad=true
	    ;;
	S)
	    lrunsix=true
	    ;;
	R)
	    lrunres=true
	    ;;
	B)
	    lbackup=true
	    how_to_use
	    echo " -B option not yet available!"
	    exit 1
	    ;;
	U)
	    luser=true
	    commandLine=$OPTARG
	    if [ -z "${commandLine}" ] ; then
		how_to_use
		echo " empty user command!"
		exit 1
	    fi
	    ;;
	k)
	    # renew kerberos token
	    lkinit=true
	    if [ "$OPTARG" == "R" ] ; then
		lkrenew=true
	    elif [ "$OPTARG" != "N" ] ; then
		how_to_use
		echo " Invalid argument $OPTARG to -$opt option"
		exit 1
	    fi
	    ;;
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
	    tmpStudy="$OPTARG"
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

# ------------------------------------------------------------------------------
# checks on user's requests
# ------------------------------------------------------------------------------
# - actions
if ! ${lmad} && ! ${lrunsix} && ! ${lrunres} && ! ${lbackup} && ! ${luser} ; then
    how_to_use
    echo "No action specified!"
    exit 1
fi
# - studies
if [ -z "${studies}" ] ; then
    how_to_use
    echo " no study requested!"
    exit 1
else
    studies=( ${studies} )
    workspaces=( ${workspaces} )
fi

# ------------------------------------------------------------------------------
# kinit
# ------------------------------------------------------------------------------
if ${lkinit} ; then
    if ${lkrenew} ; then
	echo " --> kinit -R beforehand:"
	kinit -R
    else
	echo " --> kinit beforehand:"
	kinit
    fi
    if [ $? -gt 0 ] ; then
	echo "--> kinit failed - AFS/Kerberos credentials expired!!! aborting..."
	exit 1
    else
	echo " --> klist output:"
	klist
    fi
fi

# ------------------------------------------------------------------------------
# actual script
# ------------------------------------------------------------------------------
for (( ii=0 ; ii<${#studies[@]} ; ii++ )) ; do
    cd ${workspaces[$ii]}
    if ${lmad} ; then
	echo " producing fort.?? input files to study ${studies[$ii]} in workspace ${workspaces[$ii]} ..."
	${SCRIPTDIR}/bash/mad6t.sh -s -d ${studies[$ii]} > ${studies[$ii]}_mad6t.log 2>&1
    elif ${lrunsix} ; then
	echo " submitting study ${studies[$ii]} in workspace ${workspaces[$ii]} ..."
	${SCRIPTDIR}/bash/run_six.sh -a -d ${studies[$ii]} > ${studies[$ii]}_run_six.log 2>&1
    elif ${lrunres} ; then
	echo " retrieving BOINC results of study ${studies[$ii]} in workspace ${workspaces[$ii]} ..."
	${SCRIPTDIR}/bash/run_results ${studies[$ii]} boinc > ${studies[$ii]}_run_results.log 2>&1
    elif ${lbackup} ; then
	echo " --> no back-up for the moment! skipping..."
    elif ${luser} ; then
	echo " executing user-defined command on study ${studies[$ii]} in workspace ${workspaces[$ii]} ..."
	echo ${commandLine}
    fi
    echo " getting ready for new study..."
    cd - > /dev/null 2>&1
done

# done
echo " ...done."
