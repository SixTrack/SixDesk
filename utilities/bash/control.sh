#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [option]
   script for controlling calls to sixdesk scripts.
      STDERR and STDOUT are redirected to log files like (always
      in append mode):
                                          logs/<study_name>.log
      in the workspace of the current study.
      (un-)gzipping of log files is performed (before/)after by default.

   actions [mandatory]
   -M      -> ${defaultMadCommand}
   -S      -> ${defaultRunSixCommand}
   -R      -> ${defaultRunResults}
   -B      -> ${defaultBackUp} (default settings are used)
   -U      -> user-defined operation
              in this case, it is user's responsibility to provide the command line between
                 SINGLE QUOTEs, with the correct name of the script with its fullpath, e.g.:
              `basename $0` -f ./checkList.txt -U '/full/path/to/script.sh -<flag>'
              NB: the variable \${SCRIPTDIR}:
                     ${SCRIPTDIR}
                  is available to the user.
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
   -L      skip gunzip/gzip log file before/after running command
   -P      split operations on a given number of CPUs (parallel operations). Alternative
              to specifying the number of CPUs, special keys are available:
              - ALL: a call to `basename $0` will be performed for each study;
                     if the number of studies exceeds the number of available cores,
                     parallelisation will be limited to all available cores.
                     In case the script fails to retrieve this piece of info,
                     parallelisation will be limited to ${nCPUsDef};
              - LXPLUS (not yet available): all studies will be treated separately, 
                     each by a node reached via ssh;
              - LSF (not yet available): an LSF job for each study will be created
                     and submitted;
              - HTCONDOR (not yet available): an HTCONDOR job for each study will be created
                     and submitted;
              A part from 'ALL', all other options are limited to ${nParalMax}.
           Please, do not exagereate with this option, as parallel operations may
              dramatically overload your storage volume, with counter-productive
              effects.

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
nCPUsDef=4
nParalMax=10

allARGs="$0"
commandLine=""

defaultMadCommand="mad6t.sh -s"
defaultRunSixCommand="run_six.sh -a"
defaultRunResults="run_results"
defaultBackUp="backUp.sh"

# get options (heading ':' to disable the verbose error handling)
while getopts  ":MSRBLU:hf:w:s:k:P:" opt ; do
    case $opt in
	M)
	    lmad=true
	    tmpCommand="${SCRIPTDIR}/bash/${defaultMadCommand}"
	    allARGs="${allARGs} -M"
	    ;;
	S)
	    lrunsix=true
	    tmpCommand="${SCRIPTDIR}/bash/${defaultRunSixCommand}"
	    allARGs="${allARGs} -S"
	    ;;
	R)
	    lrunres=true
	    tmpCommand="${SCRIPTDIR}/bash/${defaultRunResults}"
	    allARGs="${allARGs} -R"
	    ;;
	B)
	    lbackup=true
	    tmpCommand="${SCRIPTDIR}/bash/${defaultBackUp}"
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
	    tmpCommand="eval ${commandLine}"
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
	    elif [ `echo ${OPTARG} | awk '{print (toupper($1))}'` == "LXPLUS" ] || `echo ${OPTARG} | awk '{print (toupper($1))}'` == "LSF" ] || `echo ${OPTARG} | awk '{print (toupper($1))}'` == "HTCONDOR" ] ; then
		echo "option not yet available! switching to ALL"
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

if ${lParallel} ; then

    # parallel jobs
    echo " --> requesting parallel jobs!"
    requestedCommand="$allARGs"
    if ${luser} ; then
	requestedCommand="${requestedCommand} -U \"${commandLine}\""
    fi
    echo "     command: ${requestedCommand}"
    nCPUsOld=${nCPUs}
    if [ ${nCPUs} == "ALL" ] ; then
	nCPUs=${#studies[@]}
    fi
    # a sanity checks
    if [ ${#studies[@]} -lt ${nCPUs} ] ; then
	nCPUs=${#studies[@]}
    fi
    nCPUsSys=`grep -c ^processor /proc/cpuinfo`
    if [ -z "${nCPUsSys}" ] ; then
        # unable to retrieve number of CPUs on current machine
        # setting nCPUs to default value
	nCPUsSys=${nCPUsDef}
    fi
    if [ ${nCPUsSys} -lt ${nCPUs} ]  ; then
	nCPUs=${nCPUsSys}
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
	if [ -d logs ] || mkdir logs
	__logFile=logs/${studies[$ii]}.log
	if ${lZipLog} ; then
   	    if [ -e ${__logFile}.gz ] ; then
   		gunzip ${__logFile}.gz
   	    fi
	fi
	
	# actually run the command and make reasonable log file
	echo -e "\n\n" >> ${__logFile}
	printf "=%.0s" {1..80} >> ${__logFile}
	echo "" >> ${__logFile}
	echo " [START] - `date` - workspace: ${workspaces[$ii]} - study: ${studies[$ii]} - command: ${tmpCommand}" >> ${__logFile}
	STARTTIME=$(date +%s)
	eval ${tmpCommand} -d ${studies[$ii]} 2>&1 | tee -a ${__logFile}
	ENDTIME=$(date +%s)
	TIMEDELTA=$(($ENDTIME - $STARTTIME))
	echo " [END]   - `date` - it took ${TIMEDELTA} seconds" >> ${__logFile}
	
	if ${lZipLog} ; then
   	    gzip ${__logFile}
	fi
	if [ ${#studies[@]} -gt 1 ] ; then
	    echo " getting ready for new study..."
	fi
	cd - > /dev/null 2>&1
    done
    
fi

# done
echo " ...done."
