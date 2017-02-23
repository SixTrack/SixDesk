#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [option]
   script for controlling sequential calls to sixdesk scripts.
      STDERR and STDOUT are redirected to log files like (always
      in append mode):
                                          <study_name>.log
      in the workspace of the current study.
      Gzipping of log files is performed by default.

   actions [mandatory]
   -M      -> mad6t.sh -s -d <study_name>
   -S      -> run_six.sh -a -d <study_name>
   -R      -> run_results <study_name> BOINC
   -U      -> user-defined operation
              in this case, it is user's responsibility to provide the command line between
                 SINGLE QUOTEs, with the correct name of the script with its fullpath, e.g.:
              `basename $0` -f ./checkList.txt -U '/full/path/to/script.sh -<flag>'
              NB: the variable \${SCRIPTDIR}:
                     ${SCRIPTDIR}
                  is available to the user.
   -B      -> backUp.sh <study_name> (default settings are used)
   for the time being, only one action at a time can be requested

   options
   -f      file containing workspaces and studies of interest
           the user can specify as many files as desired. Each file must
             preceeded by a -f
   -w      fullpath to workspace where the study of interest is located
             (including sixjobs dir)
   -s      study of interest. A -s option is required for every study of
             interest (limitation from bash getops). The study must be in
             the last workspace specified.
           The special name ALL indicates all studies in a workspace
   -k      triggers a kinit before doing anything:
           N: a brand new kerberos token is generated (password requested!)
           R: the exising kerberos token is renewed (no password needed, but
              pay attention to max renewal date of token)
   -L      do not gunzip/gzip log file before/after running command
   -P      split operations on a given number of CPUs (parallel operations).
           If the special key 'ALL' is given, a call to `basename $0` will be
              performed for each study.
           Please, do not exagereate with this option, as parallel operations may
              dramatically overload your storage volume, with counter-productive
              effects.

   All the calls are logged in ${commandsLog}

   example:
   `basename $0` -k N -R -f ./checkList.txt -P 4 \\
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
lZipLog=true
lParallel=false
nCPUs=1
delayTime=60 # [s]

commandsLog="$HOME/.`basename $0`.log"
allARGs="$0"
calledMe="$0 $*"
commandLine=""

# get options (heading ':' to disable the verbose error handling)
while getopts  ":MSRBLU:hf:w:s:k:P:" opt ; do
    case $opt in
	M)
	    lmad=true
	    allARGs="${allARGs} -M"
	    ;;
	S)
	    lrunsix=true
	    allARGs="${allARGs} -S"
	    ;;
	R)
	    lrunres=true
	    allARGs="${allARGs} -R"
	    ;;
	B)
	    lbackup=true
	    allARGs="${allARGs} -B"
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
	L)
	    lZipLog=false
	    allARGs="${allARGs} -L"
	    ;;
	k)
	    # renew kerberos token
	    lkinit=true
	    if [ "$OPTARG" == "R" ] ; then
		lkrenew=true
		allARGs="${allARGs} -k R"
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
	P)
	    # parallel operations
	    lParallel=true
	    if [ `echo ${OPTARG} | awk '{print (toupper($1))}'` == "ALL" ] ; then
		# a CPU for each study to be treated
		nCPUs="ALL"
	    elif [ `echo ${OPTARG} | awk '$1 ~ /^[0-9]+$/' | wc -l` -ne 0 ] ; then
		# distribute the studies over $OPTARG CPUs
		nCPUs=${OPTARG}
	    else
		how_to_use
		echo "Invalid argument $OPTARG to -$opt option"
		exit 1
	    fi
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

# echo command in log of commands
echo "[`date +"%F %T"`] $PWD - ${calledMe}" >> ${commandsLog}

if ${lParallel} ; then

    # parallel jobs
    echo " --> requesting parallel jobs!"
    requestedCommand="$allARGs"
    if ${luser} ; then
	requestedCommand="${requestedCommand} -U \"${commandLine}\""
    fi
    echo "     command: ${requestedCommand}"
    nCPUsOld=${nCPUs}
    if [ ${nCPUs} == "ALL" ] || [ ${#studies[@]} -lt ${nCPUs} ] ; then
	nCPUs=${#studies[@]}
    fi
    nCPUsString="nCPUs: ${nCPUs}"
    if [ "${nCPUsOld}" != "${nCPUs}" ] ; then
	nCPUsString="${nCPUsString} - original request by user: ${nCPUsOld}"
    fi
    echo " --> ${nCPUsString};"

    # - tmp files, with lists of workspace/studies
    tmpFiles=""
    for (( ii=0; ii<${nCPUs} ; ii++ )) ; do
	tmpFiles="${tmpFiles} $(mktemp /tmp/`basename $0`.XXXXXXXXX)"
    done
    tmpFiles=( ${tmpFiles} )
    for tmpFile in ${tmpFiles[@]} ; do
	rm -f ${tmpFile}
    done

    # - distribute studies over the files
    nStudiesPerFile=`echo ${#studies[@]} ${nCPUs} | awk '{print (int($1/$2+0.00001))}'`
    nExcess=`echo ${#studies[@]} ${nCPUs} | awk '{print (int($1%$2+0.00001))}'`
    let nStudiesPerFileExcess=$nStudiesPerFile+1
    nInFile=0
    kk=0
    for (( ii=0 ; ii<${#studies[@]} ; ii++ )) ; do
	echo "${workspaces[$ii]} ${studies[$ii]}" >> ${tmpFiles[$kk]}
	let nInFile+=1
	if [ $kk -lt $nExcess ] ; then
	    if [ $nInFile -eq $nStudiesPerFileExcess ] ; then
		let kk+=1
		nInFile=0
	    fi
	else
	    if [ $nInFile -eq $nStudiesPerFile ] ; then
		let kk+=1
		nInFile=0
	    fi
	fi
    done

    # - execute parallel tasks
    for tmpFile in ${tmpFiles[@]} ; do
	if ${luser} ; then
	    krenew -b -t -- $allARGs -U "${commandLine}" -f $tmpFile
	else
	    krenew -b -t -- $allARGs -f $tmpFile
	fi
    done

    # - remove tmp files, after a while
    echo "sleeping ${delayTime} seconds before removing tmp files"
    sleep ${delayTime}
    for tmpFile in ${tmpFiles[@]} ; do
	rm -f ${tmpFile}
    done

else

    # loop through studies one by one
    for (( ii=0 ; ii<${#studies[@]} ; ii++ )) ; do
	cd ${workspaces[$ii]}
	if ${lZipLog} ; then
   	    if [ -e ${studies[$ii]}.log.gz ] ; then
   		gunzip ${studies[$ii]}.log.gz
   	    fi
	fi
	if ${lmad} ; then
   	    echo " producing fort.?? input files to study ${studies[$ii]} in workspace ${workspaces[$ii]} ..."
   	    ${SCRIPTDIR}/bash/mad6t.sh -s -d ${studies[$ii]} 2>&1 | tee -a ${studies[$ii]}.log
	elif ${lrunsix} ; then
   	    echo " submitting study ${studies[$ii]} in workspace ${workspaces[$ii]} ..."
   	    ${SCRIPTDIR}/bash/run_six.sh -a -d ${studies[$ii]} 2>&1 | tee -a ${studies[$ii]}.log
	elif ${lrunres} ; then
   	    echo " retrieving BOINC results of study ${studies[$ii]} in workspace ${workspaces[$ii]} ..."
   	    ${SCRIPTDIR}/bash/run_results ${studies[$ii]} boinc 2>&1 | tee -a ${studies[$ii]}.log
	elif ${lbackup} ; then
   	    echo " backing up study ${studies[$ii]} in workspace ${workspaces[$ii]} ..."
   	    ${SCRIPTDIR}/bash/backUp.sh -d ${studies[$ii]} | tee -a ${studies[$ii]}.log
	elif ${luser} ; then
   	    echo " executing user-defined command ${commandLine} on study ${studies[$ii]} in workspace ${workspaces[$ii]} ..."
   	    eval ${commandLine} -d ${studies[$ii]} 2>&1 | tee -a ${studies[$ii]}.log
	fi
	if ${lZipLog} ; then
   	    gzip ${studies[$ii]}.log
	fi
	if [ ${#studies[@]} -gt 1 ] ; then
	    echo " getting ready for new study..."
	fi
	cd - > /dev/null 2>&1
    done
    
fi

# done
echo " ...done."
