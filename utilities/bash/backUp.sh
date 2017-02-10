#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [action] [option]
   to back a file/study up to a storage resource or to restore locally an existing
      back-up from the storage.
   by A.Mereghetti
      
   actions (mandatory, one of the following):
   -d      name of the study to be backed up. Backing up produces a .zip file (named as
             the study), containing all the files in the following directories:
`for nickDir in ${nickDirs[@]}; do 
echo "                                             ${nickDir}/"
done`
           Moreover, in case the SixDB file is found in the same sixjobs dir,
             it is added to the archive. Similarly, the sixdeskTaskId file in
            sixdeskTaskIds/<studyName> is added to the back-up.
   -f      name of the file to be backed up:
           - if no study is specified, the script assumes that the file already exists;
           - if a study is specified, this option sets the name of the back-up file
             (including extension);
   -F      free dirs locked by a previous call.

   options (optional)
   -s      storage resource (default: ${storageServiceDestDef}). Those presently supported are:
           . EOS (protocol: xrdcp);
           . CASTOR (protocol: xrdcp);
           . LOCAL (i.e. another location on the same machine, eg lxplus - protocol: cp)
           . another machine (e.g. a private desktop pc - protocol: scp). In this case,
             it is user's responsibility to enable passwordless ssh, and to specify
             the fullname of the machine (including domain).
           It is also possible to copy the back-up from one resourse to another one, but
             for the time being this is limited to the use of a common communication
             protocol. As a consequence, only the following combinations are allowed:
             - EOS to CASTOR and vice-versa;
             - LOCAL to another machine and vice-versa.
           By default, the following relative basedirs are ued:
           - ${sourcePathDef} relative to sixjobs/;
           - ${destPathDef} in the storage resource, relative to user's \$HOME;
           When selecting LOCAL as storage resource, in case the local machine is lxplus,
               the basedir of the back-ups is:
               ${localBaseDirAFS}
           Otherwise. it is"
               $HOME
           The relative path on the storage resource can be changed by the user appending ':'
             to the resource specification. If '/' is the first character, then the path is
             intended to be absolute.
   -v      verbose (OFF by default)
   -C      do not remove local .zip files  (default: remove);
   -z      do not zip study files before/after backing up (default: always zip study files);
   -R      reverse selection. This is necessary for restoring locally an existing back-up.

   The default behaviour is to zip a study and back it up to ${storageServiceDestDef};
     local zip files are removed after successfully creating/restoring the back-up.
   In case of a single file, no zipping is performed.

   examples:

   `basename $0` -d fcc_tracking
           back the study fcc_tracking up to ${storageServiceDestDef}. The back-up file
             fcc_tracking.zip is automatically generated and it will be located in:
             ${baseDirDef}/${destPathDef}

   `basename $0` -d fcc_tracking -s pcbe16072.cern.ch:/media/DATA/back_ups -C -z -v
           back the study fcc_tracking up to pcbe16072.cern.ch. The file will be locate in
             /media/DATA/back_ups/fcc_tracking.zip
           The account of $LOGNAME will be used for accessing the machine. Do not remove
             zip files after backing up (-C option). Do not create the back-up .zip file
             (-z option); hence, the .zip file must be already there. Activate verbose
             mode (-v option).

   `basename $0` -d fcc_tracking -s CASTOR:back_me_up/new -R
           restore locally (-R) the back-up of the fcc_tracking study. The back-up
             is on CASTOR, in the specific location:
             ${castorBaseDir}/back_me_up/new/fcc_traking.zip

   `basename $0` -d fcc_tracking -s CASTOR:sixdeskBackUps/2016 -s EOS:backUps/2017
           copy the back-up of the study fcc_tracking from CASTOR:
             ${castorBaseDir}/sixdeskBackUps/2016/fcc_tracking.zip
           to EOS:
             ${eosBaseDir}/backUps/2017/fcc_tracking.zip


EOF
}

function preliminaryChecks(){
    local __lerr=0
    if ! ${lFree} && ! ${lStudyGiven} && ! ${lFileGiven} ; then
	how_to_use
	echo " please specify an action, i.e. backing up a study (-d option) or a file (-f option) or remove existing locks"
	let __lerr+=1
    elif ${lStudyGiven} ; then
	source ${SCRIPTDIR}/bash/set_env.sh -d ${currStudy} ${verbose} -e
	sixdeskDefineUserTree $basedir $scratchdir $workspace
    fi
    return ${__lerr}
}

function echoOptions(){
    echo ""
    if ${lFree} ; then
	sixdeskmess="freeing locks from a previous run!"
	sixdeskmess
    else
	sixdeskmess="back up:"
	sixdeskmess
	sixdeskmess="- source:      ${fullSource}"
	sixdeskmess
	sixdeskmess="- destination: ${fullDest}"
	sixdeskmess
	sixdeskmess="- protocol:    ${comProt}"
	sixdeskmess
	if ${lverbose} ; then
	    sixdeskmess="--> verbose option active!"
	    sixdeskmess
	fi
	if ${lStudyGiven} ; then
	    if ! ${lzip} ; then
		sixdeskmess="--> do not zip before creating (unzip after restoring) back-up file!"
		sixdeskmess
	    fi
	    if ! ${lclean} ; then
		sixdeskmess="--> .zip files won't be removed locally!"
		sixdeskmess
	    fi
	fi
    fi    
    echo ""
}

function setCommand(){
    lxrdcp=false
    lscp=false
    # file name:
    if [ -z "${fileName}" ] ; then
	# automatic naming convention:
	fileName=${currStudy}.zip
    fi
    if [ ${lSerGiven} -eq 2 ] ; then
	# copying back-up from one storage system to the other one
	# -> change default source path
	if [ "$sourcePath" == "." ] ; then
	    sourcePath=$destPathDef
	fi
	# -> invert assignment of storage service and paths, for a more intuitive user interface
	local __tmpStorageService=${storageServiceSource}
	storageServiceSource=${storageServiceDest}
	storageServiceDest=${__tmpStorageService}
	local __tmpPath=${sourcePath}
	sourcePath=${destPath}
	destPath=${__tmpPath}
    fi
    # swap source and destination
    if ${lreverse} ; then
	# reverse selection
	local __tmpPath=${sourcePath}
	sourcePath=${destPath}
	destPath=${__tmpPath}
	local __tmpStorageService=${storageServiceSource}
	storageServiceSource=${storageServiceDest}
	storageServiceDest=${__tmpStorageService}
    fi
    # fullpaths:
    if [ `echo "$destPath" | cut -c1` == "/" ] ; then
	fullPathDest=$destPath
    fi
    if [ `echo "$sourcePath" | cut -c1` == "/" ] ; then
	fullPathSource=$sourcePath
    fi
    # destination
    if [ "${storageServiceDest}" == "EOS" ] ; then
	[ -n "${fullPathDest}" ] || fullPathDest=$eosBaseDir/$destPath
	fullDest=root://${eosServerName}/${fullPathDest}
	lxrdcp=true
    elif [ "${storageServiceDest}" == "CASTOR" ] ; then
	[ -n "${fullPathDest}" ] || fullPathDest=$castorBaseDir/$destPath
	fullDest=root://${castorServerName}/${fullPathDest}
	lxrdcp=true
    elif [ "${storageServiceDest}" == "LOCAL" ] ; then
	if [ `uname -n | cut -c1-6` == "lxplus" ] ; then
	    localBaseDir=$localBaseDirAFS
	else
	    localBaseDir=$localBaseDirHome
	fi
	[ -n "${fullPathDest}" ] || fullPathDest=$localBaseDir/$destPath
	fullDest=${fullPathDest}
    elif [ -n "${storageServiceDest}" ] ; then
	if [ `echo "${storageServiceDest}" | cut -c1-6` == "lxplus" ] ; then
	    privBaseDir=$localBaseDirAFS
	fi
	[ -n "${fullPathDest}" ] || fullPathDest=$privBaseDir/$destPath
	fullDest=$LOGNAME@${storageServiceDest}:${fullPathDest}
	lscp=true
    else
	[ -n "${fullPathDest}" ] || fullPathDest=$destPath
	fullDest=${fullPathDest}
    fi
    # source
    if [ "${storageServiceSource}" == "EOS" ] ; then
	[ -n "${fullPathSource}" ] || fullPathSource=$eosBaseDir/$sourcePath
	fullSource=root://${eosServerName}/${fullPathSource}
	lxrdcp=true
    elif [ "${storageServiceSource}" == "CASTOR" ] ; then
	[ -n "${fullPathSource}" ] || fullPathSource=$castorBaseDir/$sourcePath
	fullSource=root://${castorServerName}/${fullPathSource}
	lxrdcp=true
    elif [ "${storageServiceSource}" == "LOCAL" ] ; then
	if [ `uname -n | cut -c1-6` == "lxplus" ] ; then
	    localBaseDir=$localBaseDirAFS
	else
	    localBaseDir=$localBaseDirHome
	fi
	[ -n "${fullPathSource}" ] || fullPathSource=$localBaseDir/$sourcePath
	fullSource=${fullPathSource}
    elif [ -n "${storageServiceSource}" ] ; then
	if [ `echo "${storageServiceSource}" | cut -c1-6` == "lxplus" ] ; then
	    privBaseDir=$localBaseDirAFS
	fi
	[ -n "${fullPathSource}" ] || fullPathSource=$privBaseDir/$sourcePath
	fullSource=$LOGNAME@${storageServiceSource}:${fullPathSource}
	lscp=true
    else
	[ -n "${fullPathSource}" ] || fullPathSource=$sourcePath
	fullSource=${fullPathSource}
    fi
    # add filename to full path of source
    fullSource="${fullSource}/${fileName}"
    # protocol
    if ${lxrdcp} && ${lscp} ; then
	how_to_use
	echo "cannot xrdcp and scp at the same time"
	exit 1
    elif ${lxrdcp} ; then
	comProt="xrdcp"
    elif ${lscp} ; then
	comProt="scp -p"
    else
	comProt="cp -p"
    fi
}

function checkSourceFile(){
    # for each storage service, check that the back-up file exists
    local __lerr=0
    if [ "${storageServiceSource}" == "EOS" ] ; then
	eos ls -l ${fullPathSource}/${fileName} > /dev/null 2>&1
	__lerr=$?
    elif [ "${storageServiceSource}" == "CASTOR" ] ; then
	nsls -l ${fullPathSource}/${fileName} > /dev/null 2>&1
	__lerr=$?
    elif [ "${storageServiceSource}" == "LOCAL" ] ; then
	ls -l ${fullPathSource}/${fileName} > /dev/null 2>&1
	__lerr=$?
    elif [ -n "${storageServiceSource}" ] ; then
	ssh $LOGNAME@${storageServiceSource} "ls -l ${fullPathSource}/${fileName}" > /dev/null 2>&1
	__lerr=$?
    else
	ls -l ${fullPathSource}/${fileName} > /dev/null 2>&1
	__lerr=$?
    fi
    return $__lerr
}

function prepareDest(){
    # for each storage service:
    # - check that destination folder exists
    # - remove destination file, to avoid copy of backup is rejected by xrdcp
    #   (and useless error messages)
    if [ "${storageServiceDest}" == "EOS" ] ; then
	eos ls -l ${fullPathDest} > /dev/null 2>&1
	if [ $? -ne 0 ] ; then
	    eos mkdir -p ${fullPathDest}
	fi
	eos ls -l ${fullPathDest}/${fileName} > /dev/null 2>&1
	if [ $? -eq 0 ] ; then
	    eos rm ${fullPathDest}/${fileName}
	fi
    elif [ "${storageServiceDest}" == "CASTOR" ] ; then
	nsls -l ${fullPathDest} > /dev/null 2>&1
	if [ $? -ne 0 ] ; then
	    nsmkdir -p ${fullPathDest}
	fi
	nsls -l ${fullPathDest}/${fileName} > /dev/null 2>&1
	if [ $? -eq 0 ] ; then
	    nsrm ${fullPathDest}/${fileName}
	fi
    elif [ "${storageServiceDest}" == "LOCAL" ] ; then
	if [ "${destPath}" != "." ] ; then
	    ls -l ${fullPathDest} > /dev/null 2>&1
	    if [ $? -ne 0 ] ; then
		mkdir -p ${fullPathDest}
	    fi
	fi
	ls -l ${fullPathDest}/${fileName} > /dev/null 2>&1
	if [ $? -eq 0 ] ; then
	    rm -f ${fullPathDest}/${fileName}
	fi
    elif [ -n "${storageServiceDest}" ] ; then
	ssh $LOGNAME@${storageServiceDest} "ls -l ${fullPathDest}" > /dev/null 2>&1
	if [ $? -ne 0 ] ; then
	    ssh $LOGNAME@${storageServiceDest} "mkdir -p ${fullPathDest}"
	fi
	ssh $LOGNAME@${storageServiceDest} "ls -l ${fullPathDest}/${fileName}" > /dev/null 2>&1
	if [ $? -eq 0 ] ; then
	    ssh $LOGNAME@${storageServiceDest} "rm -f ${fullPathDest}/${fileName}"
	fi
    else
	if [ "${destPath}" != "." ] ; then
	    ls -l ${fullPathDest} > /dev/null 2>&1
	    if [ $? -ne 0 ] ; then
		mkdir -p ${fullPathDest}
	    fi
	fi
	ls -l ${fullPathDest}/${fileName} > /dev/null 2>&1
	if [ $? -eq 0 ] ; then
	    rm -f ${fullPathDest}/${fileName}
	fi
    fi
}

function backUpCleanExit(){
    local __lerr=$1

    # remove zip files
    if $lclean ; then
	sixdeskmess="cleaning zip files..."
	sixdeskmess
	cleanFiles="${fileName}"
	if ${lzip} ; then
	    cleanFiles="${cleanFiles} ${zipFiles}"
	fi
	for cleanFile in  ${cleanFiles}; do
	    if ${lverbose} ; then
		sixdeskmess="- file: ${cleanFile}"
		sixdeskmess
	    fi
	    rm -f ${cleanFile}
	done
    fi

    sixdeskCleanExit $__lerr
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

initial=`echo $LOGNAME | cut -c 1`

# EOS
export EOS_MGM_URL=root://eosuser.cern.ch
eosBaseDir=/eos/user/$initial/$LOGNAME
eosServerName=eosuser.cern.ch
# CASTOR
export STAGE_HOST="castorpublic"
export STAGE_SVCCLASS="default"
castorBaseDir=/castor/cern.ch/user/$initial/$LOGNAME
castorServerName=castorpublic.cern.ch
# LOCAL
localBaseDirAFS=/afs/cern.ch/work/$initial/$LOGNAME
localBaseDirHome=$HOME
# private machine
privBaseDir=/home/$LOGNAME

# defaults
currStudyDef=''
sourcePathDef='.'
destPathDef='back_ups'
storageServiceDestDef='EOS'
storageServiceSourceDef=''
baseDirDef=${eosBaseDir}

# actions and options
currStudy=$currStudyDef
sourcePath=$sourcePathDef
destPath=$destPathDef
storageServiceDest=$storageServiceDestDef
storageServiceSource=$storageServiceSourceDef
lreverse=false
lzip=false
lclean=true
lverbose=false
lFree=false
lFileGiven=false
lStudyGiven=false
verbose=""

# dirs to be zipped
nickDirs=( "study" "sixtrack_input" "track" "work" "logs" )

# get options (heading ':' to disable the verbose error handling)
lSerGiven=0
lPatGiven=0
while getopts  ":hvCd:s:f:FRz" opt ; do
    case $opt in
	d)
	    # the user is requesting a specific study
	    currStudy="${OPTARG}"
	    lStudyGiven=true
	    # automatically zip
	    lzip=true
	    ;;
	f)
	    # the user is requesting a specific file
	    fileName="${OPTARG}"
	    lFileGiven=true
	    # skip zipping
	    lzip=false
	    # do not clean, ie remove zip files
	    lclean=false
	    ;;
	v)
	    # verbose
	    lverbose=true
	    ;;
	C)
	    # do not clean, ie remove zip files
	    lclean=false
	    ;;
	s)
	    # the user is requesting a specific storage service
	    tmpString="${OPTARG}:"
	    tmpService=`echo "${tmpString}" | cut -d: -f1`
	    tmpPath=`echo "${tmpString}" | cut -d: -f2`
	    if [ "${tmpService}" != "EOS" ] && [ "${tmpService}" != "CASTOR" ] && [ "${tmpService}" != "LOCAL" ] ; then
		# it might be a machine: try to ping
		ping -c1 ${tmpService} >/dev/null 2>&1
		if [ $? -ne 0 ] ; then
		    how_to_use
		    echo "Invalid storage service or ${tmpService} not available"
		    exit 1
		fi
	    fi
	    if [ ${lSerGiven} -eq 0 ] ; then
		storageServiceDest="${tmpService}"
		if [ -n "${tmpPath}" ] ; then
		    destPath="${tmpPath}"
		fi
	    elif [ ${lSerGiven} -eq 1 ] ; then
		storageServiceSource="${tmpService}"
		if [ -n "${tmpPath}" ] ; then
		    sourcePath="${tmpPath}"
		fi
	    fi
	    let lSerGiven+=1
	    ;;
	z)
	    # skip zipping
	    lzip=false
	    ;;
	R)
	    # reverse selection
	    lreverse=true
	    ;;
	F)
	    # free locks
	    lFree=true
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

# workaround to get getopts working properly in sourced script
OPTIND=1

if ${lverbose} ; then
    verbose="-v"
fi

preliminaryChecks
exitStatus=$?
if [ $exitStatus -ne 0 ] ; then
    exit ${exitStatus}
fi

# ------------------------------------------------------------------------------
# preparatory steps
# ------------------------------------------------------------------------------

if [ -z "${currStudy}" ] ; then
    export sixdeskhostname=`hostname`
    export sixdeskname=`basename $0`
    export sixdeskroot=`basename $PWD`
    export sixdeskwhere=`dirname $PWD`
    # Set up some temporary values until we execute sixdeskenv/sysenv
    # Don't issue lock/unlock debug text (use 2 for that)
    export sixdesklogdir=""
    export sixdesklevel=1
    export sixdeskhome="."
    export sixdeskecho="yes!"
    if [ ! -s ${SCRIPTDIR}/bash/dot_profile ] ; then
	echo "dot_profile is missing!!!"
	exit 1
    fi
    # - load environment
    source ${SCRIPTDIR}/bash/dot_profile
    # - settings for sixdeskmessages
    sixdeskmessleveldef=0
    sixdeskmesslevel=$sixdeskmessleveldef
fi

# set the backing up command
setCommand

# echo options
echoOptions

# - dirs to be zipped
zipDirs=( ${sixdeskstudy} ${sixtrack_input} ${sixdesktrackStudy} ${sixdeskwork} ${sixdesklogdir} )

# - locking dirs
lockingDirs=( . )
if ${lzip} ; then
    lockingDirs+=( "${zipDirs[@]}" )
fi

# - free locked dirs (user request)
if ${lFree} ; then
    sixdeskCleanExit 0
fi

# - temporary trap
trap "sixdeskexit 1" EXIT

# lock dirs
for tmpDir in ${lockingDirs[@]} ; do
    [ -d $tmpDir ] || mkdir -p $tmpDir
    sixdesklock $tmpDir
done

# - actual trap
trap "backUpCleanExit 1" EXIT

# ------------------------------------------------------------------------------
# actual operations
# ------------------------------------------------------------------------------

echo ""

currDir=$PWD

# ---------------------------------------
# zip files: backing up an existing study
# ---------------------------------------

if ${lzip} && [ "${sourcePath}" == "." ] ; then
    lerr=0
    zipFiles=""
    for (( ii=0; ii<${#zipDirs[@]} ; ii++ )) ; do
	tmpZipFileName=${currStudy}_${nickDirs[$ii]}.zip
	echo ""
	sixdeskmess="zipping files in ${nickDirs[$ii]} dir ${zipDirs[$ii]} in ${tmpZipFileName}"
	sixdeskmess
	cd ${zipDirs[$ii]}
	if ${lverbose} ; then
	    zip -r --symlinks -b /tmp ${currDir}/${tmpZipFileName} .
	    let lerr+=$?
	else
	    zip -r --symlinks -b /tmp ${currDir}/${tmpZipFileName} . > /dev/null 2>&1
	    let lerr+=$?
	fi
	cd - > /dev/null 2>&1
	sixdeskmess="zipping ${tmpZipFileName} in ${fileName}"
	sixdeskmess
	if ${lverbose} ; then
	    zip -b /tmp ${fileName} ${tmpZipFileName}
	    let lerr+=$?
	else
	    zip -b /tmp ${fileName} ${tmpZipFileName} > /dev/null 2>&1
	    let lerr+=$?
	fi
	zipFiles="${zipFiles} ${tmpZipFileName}"
    done
    if [ -s "${sixdeskTaskIds/$LHCDescrip/sixdeskTaskId}" ] ; then
	# sixdesktaskid
	echo ""
	sixdeskmess="zipping sixdeskTaskId file"
	sixdeskmess
	if ${lverbose} ; then
	    zip -b /tmp ${fileName} sixdeskTaskIds/$LHCDescrip/sixdeskTaskId
	    let lerr+=$?
	else
	    zip -b /tmp ${fileName} sixdeskTaskIds/$LHCDescrip/sixdeskTaskId > /dev/null 2>&1
	    let lerr+=$?
	fi
    fi
    if [ -s "${currStudy}.db" ] ; then
	# sixdeskDB
	echo ""
	sixdeskmess="zipping sixdb file ${currStudy}.db"
	sixdeskmess
	if ${lverbose} ; then
	    zip -b /tmp ${fileName} ${currStudy}.db
	    let lerr+=$?
	else
	    zip -b /tmp ${fileName} ${currStudy}.db > /dev/null 2>&1
	    let lerr+=$?
	fi
    fi
    if [ $lerr -ne 0 ] ; then
	echo ""
	sixdeskmess="errors while zipping!"
	sixdeskmess
	exit $lerr
    fi
fi

# --------------------
# copy the backup file
# --------------------

# check source file
checkSourceFile
lerr=$?
if [ $lerr -ne 0 ] ; then
    sixdeskmess="source file on ${storageServiceSource}:"
    sixdeskmess
    sixdeskmess="  ${fullPathSource}/${fileName}"
    sixdeskmess
    sixdeskmess="does not exists!"
    sixdeskmess
    exit $lerr
fi

# prepare destination
prepareDest

echo ""
sixdeskmess="copying back-up file..."
sixdeskmess
${comProt} ${fullSource} ${fullDest}
lerr=$?
if [ $lerr -ne 0 ] ; then
    echo ""
    sixdeskmess="errors while copying backup file!"
    sixdeskmess
    exit $lerr
fi

# ---------------------------------------------------
# zip files: extracting an existing backup to a study
# ---------------------------------------------------

if ${lzip} && [ "${destPath}" == "." ] ; then
    lerr=0
    zipFiles=""
    if ! [ -s ${fileName} ] ; then
	echo ""
	sixdeskmess="file ${fileName} does NOT exist!"
	sixdeskmess
	exit 1
    fi
    archives=`zipinfo -1 ${fileName}`
    if [ -z "${archives}" ] ; then
	echo ""
	sixdeskmess="${fileName} is an empty zip file!"
	sixdeskmess
	exit 1
    fi
    if ! ${lverbose} ; then
	sixdeskmess="archive ${fileName} contains:"
	sixdeskmess
	unzip -l ${fileName}
    fi
    sixdeskmess="unzipping..."
    sixdeskmess
    if ${lverbose} ; then
	unzip ${fileName}
	let lerr+=$?
    else
	unzip ${fileName} > /dev/null 2>&1
	let lerr+=$?
    fi
    for (( ii=0; ii<${#zipDirs[@]} ; ii++ )) ; do
	echo ""
	sixdeskmess="unzipping files in ${nickDirs[$ii]} dir ${zipDirs[$ii]}"
	sixdeskmess
	tmpZipFileName=`echo "${archives}" | grep ${currStudy}_${nickDirs[$ii]}_ | grep zip`
	if [ -z "${tmpZipFileName}" ] ; then
	    sixdeskmess="--> no backup in ${fileName}! skipping it..."
	    sixdeskmess
	    continue
	fi
	cd ${zipDirs[$ii]}
	if ${lverbose} ; then
	    unzip -o ${currDir}/${tmpZipFileName}
	    let lerr+=$?
	else
	    unzip -o ${currDir}/${tmpZipFileName} > /dev/null 2>&1
	    let lerr+=$?
	fi
	cd - > /dev/null 2>&1
	zipFiles="${zipFiles} ${tmpZipFileName}"
    done
    tmpSixDbFileName=`echo "${archives}" | grep '\.db'`
    if [ -n "${tmpSixDbFileName}" ] ; then
	for tmpSixDB in ${tmpSixDbFileName} ; do
	    sixdeskmess="sixdb file ${tmpSixDB} unzipped!"
	    sixdeskmess
	done
    fi
    if [ $lerr -ne 0 ] ; then
	echo ""
	sixdeskmess="errors while unzipping!"
	sixdeskmess
	exit $lerr
    fi
fi

# ------------------------------------------------------------------------------
# end
# ------------------------------------------------------------------------------

# redefine trap
trap "backUpCleanExit 0" EXIT

# echo that everything went fine
echo ""
sixdeskmess="Completed normally"
sixdeskmess
