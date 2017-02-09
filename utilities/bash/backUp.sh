#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [action] [option]
   to manage backing up of studies

EOF
}

function preliminaryChecks(){
    local __lerr=0
    if [ -n "${fileName}" ] ; then
	if ! [ -s ${fileName} ] ; then
	    how_to_use
	    echo " file ${fileName} (-f option) does not exist or is empty"
	    let __lerr+=1
	fi
    elif [ -n "${currStudy}" ] ; then
	source ${SCRIPTDIR}/bash/set_env.sh -d ${currStudy} -e
	sixdeskDefineUserTree $basedir $scratchdir $workspace
    else
	how_to_use
	echo " please specify a study (-d option) or a file (-f option)"
	let __lerr+=1
    fi
    return ${__lerr}
}

function setCommand(){
    lxrdcp=false
    lscp=false
    # file name:
    if [ -z "${fileName}" ] ; then
	# automatic naming convention:
	fileName=${currStudy}.zip
    fi
    # swap source and destination
    if ${lreverse} ; then
	local __tmpPath=${sourcePath}
	sourcePath=${destPath}
	destPath=${__tmpPath}
	local __tmpFull=${fullPathSource}
	fullPathSource=${fullPathDest}
	fullPathDest=${__tmpFull}
	local __tmpStorageService=${storageServiceSource}
	storageServiceSource=${storageServiceDest}
	storageServiceDest=${__tmpStorageService}
    fi
    # destination
    if [ "${storageServiceDest}" == "EOS" ] ; then
	[ -n "${fullPathDest}" ] || fullPathDest=$eosBaseDirDef/$destPath
	fullDest=root://${eosServeraName}${fullPathDest}
	lxrdcp=true
    elif [ "${storageServiceDest}" == "CASTOR" ] ; then
	[ -n "${fullPathDest}" ] || fullPathDest=$castorBaseDirDef/$destPath
	fullDest=root://${castorServeraName}${fullPathDest}
	lxrdcp=true
    elif [ "${storageServiceDest}" == "LOCAL" ] ; then
	[ -n "${fullPathDest}" ] || fullPathDest=$localBaseDirDef/$destPath
	fullDest=${fullPathDest}
    elif [ -n "${storageServiceDest}" ] ; then
	[ -n "${fullPathDest}" ] || fullPathDest=$privBaseDirDef/$destPath
	fullDest=$LOGNAME@${storageServiceDest}:${fullPathDest}
	lscp=true
    else
	[ -n "${fullPathDest}" ] || fullPathDest=$destPath
	fullDest=${fullPathDest}
    fi
    # source
    if [ "${storageServiceSource}" == "EOS" ] ; then
	[ -n "${fullPathSource}" ] || fullPathSource=$eosBaseDirDef/$sourcePath
	fullSource=root://${eosServeraName}${fullPathSource}
	lxrdcp=true
    elif [ "${storageServiceSource}" == "CASTOR" ] ; then
	[ -n "${fullPathSource}" ] || fullPathSource=$castorBaseDirDef/$sourcePath
	fullSource=root://${castorServeraName}${fullPathSource}
	lxrdcp=true
    elif [ "${storageServiceSource}" == "LOCAL" ] ; then
	[ -n "${fullPathSource}" ] || fullPathSource=$localBaseDirDef/$sourcePath
	fullSource=${fullPathSource}
    elif [ -n "${storageServiceSource}" ] ; then
	[ -n "${fullPathSource}" ] || fullPathSource=$localBaseDirDef/$sourcePath
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

function prepareDest(){
    # prepare destination:
    # - check that destination folder exists
    # - remove destination file, to avoid copy of backup is rejected by xrdcp
    #   (and useless error messages)
    if [ "${storageServiceDest}" == "EOS" ] ; then
	echo "eos ls -l ${fullPathDest} > /dev/null 2>&1"
	if [ $? -ne 0 ] ; then
	    echo "eos mkdir -p ${fullPathDest}"
	fi
	echo "eos ls -l ${fullPathDest}/${fileName} > /dev/null 2>&1"
	if [ $? -eq 0 ] ; then
	    echo "eos rm ${fullPathDest}/${fileName}"
	fi
    elif [ "${storageServiceDest}" == "CASTOR" ] ; then
	echo "nsls -l ${fullPathDest} > /dev/null 2>&1"
	if [ $? -ne 0 ] ; then
	    echo "nsmkdir -p ${fullPathDest}"
	fi
	echo "nsls -l ${fullPathDest}/${fileName} > /dev/null 2>&1"
	if [ $? -eq 0 ] ; then
	    echo "nsrm ${fullPathDest}/${fileName}"
	fi
    elif [ "${storageServiceDest}" == "LOCAL" ] ; then
	if [ "${destPath}" != "." ] ; then
	    echo "ls -l ${fullPathDest} > /dev/null 2>&1"
	    if [ $? -ne 0 ] ; then
		echo "mkdir -p ${fullPathDest}"
	    fi
	fi
	echo "ls -l ${fullPathDest}/${fileName} > /dev/null 2>&1"
	if [ $? -eq 0 ] ; then
	    echo "rm -f ${fullPathDest}/${fileName}"
	fi
    elif [ -n "${storageServiceDest}" ] ; then
	echo "ssh $LOGNAME@${storageServiceDest} \"ls -l ${fullPathDest}\" > /dev/null 2>&1"
	if [ $? -ne 0 ] ; then
	    echo "ssh $LOGNAME@${storageServiceDest} \"mkdir -p ${fullPathDest}\""
	fi
	echo "ssh $LOGNAME@${storageServiceDest} \"ls -l ${fullPathDest}/${fileName}\" > /dev/null 2>&1"
	if [ $? -eq 0 ] ; then
	    echo "ssh $LOGNAME@${storageServiceDest} \"rm -f ${fullPathDest}/${fileName}\""
	fi
    else
	if [ "${destPath}" != "." ] ; then
	    echo "ls -l ${fullPathDest} > /dev/null 2>&1"
	    if [ $? -ne 0 ] ; then
		echo "mkdir -p ${fullPathDest}"
	    fi
	fi
	echo "ls -l ${fullPathDest}/${fileName} > /dev/null 2>&1"
	if [ $? -eq 0 ] ; then
	    echo "rm -f ${fullPathDest}/${fileName}"
	fi
    fi
}

# preliminary:
# - preliminary kinit
# - SCRIPTDIR
# - set_env
# - check of variables: CASTOR_HOME
# - lock dirs

function template(){
    initial=`echo $LOGNAME | cut -c 1`

    echo ""
    echo "CASTOR"
    rm test.txt
    echo "cacco" >> test.txt
    echo "cacco" >> test.txt
    echo "cacco" >> test.txt
    #    https://cern.service-now.com/service-portal/article.do?n=KB0001103
    # quick:
    # - nsmkdir /castor/cern.ch/user/l/laman/castor_tutorial
    # - xrdcp test.txt root://castorpublic.cern.ch//castor/cern.ch/user/l/laman/castor_tutorial/castor.txt
    # - xrdcp root://castorpublic.cern.ch//castor/cern.ch/user/l/laman/castor_tutorial/castor.txt myfile.txt
    # - nsls -l /castor/cern.ch/user/l/laman/castor_tutorial
    # - nsrm -rf $CASTORDIR
    export STAGE_HOST="castorpublic"
    export STAGE_SVCCLASS="default"
    castorBaseDir=/castor/cern.ch/user/$initial/$LOGNAME
    #
    backUpDir=$castorBaseDir/test
    nsls -l $castorBaseDir
    nsrm -r $backUpDir
    nsls -l $castorBaseDir
    nsls -l $backUpDir/test.txt
    echo $?
    nsmkdir -p $backUpDir
    nsls -l $castorBaseDir
    nsls -l $backUpDir
    echo "copy 1:"
    xrdcp test.txt root://castorpublic.cern.ch/$backUpDir
    nsls -l $backUpDir
    echo "copy 2:"
    xrdcp test.txt root://castorpublic.cern.ch/$backUpDir
    nsls -l $backUpDir
    rm test.txt
    touch test.txt
    xrdcp root://castorpublic.cern.ch/$backUpDir/test.txt .
    echo "test.txt:"
    cat test.txt
    
    echo ""
    echo "EOS"
    rm test.txt
    echo "cacco" >> test.txt
    echo "cacco" >> test.txt
    echo "cacco" >> test.txt
    #   https://cern.service-now.com/service-portal/article.do?n=KB0001998
    # quick:
    # - eos mkdir /eos/<experiment>/user/l/laman/eos_tutorial
    # - xrdcp test.txt root://eos<experiment>.cern.ch//eos/<experiment>/user/l/laman/eos_tutorial/eos.txt
    # - xrdcp root://eos<experiment>.cern.ch//eos/<experiment>/user/l/laman/eos_tutorial/eos.txt eos.txt
    # - eos ls -l /eos/<experiment>/user/l/laman/eos_tutorial
    export EOS_MGM_URL=root://eosuser.cern.ch
    eosBaseDir=/eos/user/$initial/$LOGNAME
    #
    backUpDir=$eosBaseDir/test
    eos ls -l $eosBaseDir
    eos rm -r $backUpDir
    eos ls -l $backUpDir/test.txt
    echo $?
    eos ls -l $eosBaseDir
    eos mkdir -p $backUpDir
    eos ls -l $eosBaseDir
    eos ls -l $backUpDir
    echo "copy 1:"
    xrdcp test.txt root://eosuser.cern.ch/$backUpDir
    eos ls -l $backUpDir
    echo "copy 2:"
    xrdcp test.txt root://eosuser.cern.ch/$backUpDir
    eos ls -l $backUpDir
    rm test.txt
    touch test.txt
    xrdcp root://eosuser.cern.ch/$backUpDir/test.txt .
    echo "test.txt:"
    cat test.txt
}

# ==============================================================================
# main
# ==============================================================================

# AM -> template
# AM -> exit

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
eosBaseDirDef=/eos/user/$initial/$LOGNAME
eosServeraName=eosuser.cern.ch
# CASTOR
export STAGE_HOST="castorpublic"
export STAGE_SVCCLASS="default"
castorBaseDirDef=/castor/cern.ch/user/$initial/$LOGNAME
castorServeraName=castorpublic.cern.ch
# LOCAL
localBaseDirDef=$HOME
# private machine
privBaseDirDef=/home/$LOGNAME

# defaults
currStudyDef=''
sourcePathDef='.'
destPathDef='back_ups'
storageServiceDestDef='EOS'
storageServiceSourceDef=''

# actions and options
currStudy=$currStudyDef
sourcePath=$sourcePathDef
destPath=$destPathDef
storageServiceDest=$storageServiceDestDef
storageServiceSource=$storageServiceSourceDef
lreverse=false
lzip=false

# get options (heading ':' to disable the verbose error handling)
lSerGiven=0
lPatGiven=0
while getopts  ":hd:t:s:f:Rz" opt ; do
    case $opt in
	t)
	    # paths
	    if [ ${lPatGiven} -eq 0 ] ; then
		destPath="${OPTARG}"
	    elif [ ${lPatGiven} -eq 1 ] ; then
		# copying back up from one storage system to the other one
		# -> invert assignment, for a more intuitive user interface
		sourcePath="${destPath}"
		destPath="${OPTARG}"
	    fi
	    let lPatGiven+=1
	    ;;
	d)
	    # the user is requesting a specific study
	    currStudy="${OPTARG}"
	    # automatically zip
	    lzip=true
	    ;;
	f)
	    # the user is requesting a specific file
	    fileName="${OPTARG}"
	    ;;
	s)
	    # the user is requesting a specific storage service
	    if [ "${OPTARG}" != "EOS" ] && [ "${OPTARG}" != "CASTOR" ] && [ "${OPTARG}" != "LOCAL" ] ; then
		# it might be a machine: try to ping
		ping -c1 ${OPTARG} >/dev/null 2>&1
		if [ $? -ne 0 ] ; then
		    how_to_use
		    echo "Invalid storage service or ${OPTARG} not available"
		    exit 1
		fi
	    fi
	    if [ ${lSerGiven} -eq 0 ] ; then
		storageServiceDest="${OPTARG}"
	    elif [ ${lSerGiven} -eq 1 ] ; then
		# copying back up from one storage system to the other one
		# -> invert assignment, for a more intuitive user interface
		storageServiceSource="${storageServiceDest}"
		storageServiceDest="${OPTARG}"
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

# - temporary trap
trap "sixdeskexit 1" EXIT

# - locking dirs
if ${lzip} ; then
    lockingDirs=( . ${sixdeskstudy} ${sixtrack_input} ${sixdesktrackStudy} ${sixdeskwork} )
else
    lockingDirs=( . )
fi

# - lock dirs
for tmpDir in ${lockingDirs[@]} ; do
    [ -d $tmpDir ] || mkdir -p $tmpDir
    sixdesklock $tmpDir
done

# - actual trap
trap "sixdeskCleanExit 1" EXIT

# ------------------------------------------------------------------------------
# actual operations
# ------------------------------------------------------------------------------

echo ""

# set the backing up command
setCommand

# prepare destination
prepareDest

# zip files: backing up an existing study
if ${lzip} && [ "${sourcePath}" == "." ] ; then
    sixdeskmess="zipping files in study dir ${sixdeskstudy}"
    sixdeskmess
    echo "zip -r --symlinks ${fileName} ${sixdeskstudy}"
    sixdeskmess="zipping files in sixtrack_input dir ${sixtrack_input}"
    sixdeskmess
    echo "zip -r --symlinks ${fileName} ${sixtrack_input}"
    sixdeskmess="zipping files in track dir ${sixdesktrackStudy}"
    sixdeskmess
    echo "zip -r --symlinks ${fileName} ${sixdesktrackStudy}"
    sixdeskmess="zipping files in work dir ${sixdeskwork}"
    sixdeskmess
    echo "zip -r --symlinks ${fileName} ${sixdeskwork}"
    if [ -s "${currStudy}.db" ] ; then
	sixdeskmess="zipping sixdb file ${currStudy}.db"
	sixdeskmess
	echo "zip ${fileName} ${currStudy}.db"
    fi
fi

# copy the backup file
echo "${comProt} ${fullSource} ${fullDest}"

# zip files: extracting an existing backup to a study
if ${lzip} && [ "${destPath}" == "." ] ; then
    sixdeskmess="unzipping files in study dir ${sixdeskstudy}"
    sixdeskmess
    echo "unzip ${fileName} ${sixdeskstudy}"
    sixdeskmess="unzipping files in sixtrack_input dir ${sixtrack_input}"
    sixdeskmess
    echo "unzip ${fileName} ${sixtrack_input}"
    sixdeskmess="unzipping files in track dir ${sixdesktrackStudy}"
    sixdeskmess
    echo "unzip ${fileName} ${sixdesktrackStudy}"
    sixdeskmess="unzipping files in work dir ${sixdeskwork}"
    sixdeskmess
    echo "unzip ${fileName} ${sixdeskwork}"
    if [ -s "${currStudy}.db" ] ; then
	sixdeskmess="unzipping sixdb file ${currStudy}.db"
	sixdeskmess
	echo "unzip ${fileName} ${currStudy}.db"
    fi
fi

# ------------------------------------------------------------------------------
# end
# ------------------------------------------------------------------------------

# redefine trap
trap "sixdeskCleanExit 0" EXIT

# echo that everything went fine
echo ""
sixdeskmess="Completed normally"
sixdeskmess
