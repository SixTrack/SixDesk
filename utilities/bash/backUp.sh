#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [action] [option]
   to manage backing up of studies

EOF
}

function preliminaryChecks(){
    local __lerr=0
    return ${__lerr}
}

function setCommand(){
    lxrdcp=false
    lscp=false
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
	[ -n "${fullPathDest}" ] || fullPathDest=$localBaseDirDef/$destPath
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
	[ -n "${fullPathSource}" ] || fullPathSource=$localBaseDirDef/$destPath
	fullSource=${fullPathSource}
    elif [ -n "${storageServiceSource}" ] ; then
	[ -n "${fullPathSource}" ] || fullPathSource=$localBaseDirDef/$sourcePath
	fullSource=$LOGNAME@${storageServiceDest}:${fullPathSource}
	lscp=true
    else
	[ -n "${fullPathSource}" ] || fullPathSource=$sourcePath
	fullSource=${fullPathSource}
    fi
    if ${lreverse} ; then
	local __tmpFull=${fullSource}
	fullSource=${fullDest}
	fullDest=${__tmpFull}
    fi
    fullSource="${fullSource}/${currStudy}"
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
    nsmkdir -p $backUpDir
    nsls -l $castorBaseDir
    nsls -l $backUpDir
    xrdcp test.txt root://castorpublic.cern.ch/$backUpDir
    nsls -l $backUpDir
    rm test.txt
    xrdcp root://castorpublic.cern.ch/$backUpDir/test.txt .
    
    echo ""
    echo "EOS"
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
    eos ls -l $eosBaseDir
    eos mkdir -p $backUpDir
    eos ls -l $eosBaseDir
    eos ls -l $backUpDir
    xrdcp test.txt root://eosuser.cern.ch/$backUpDir
    eos ls -l $backUpDir
    rm test.txt
    xrdcp root://eosuser.cern.ch/$backUpDir/test.txt .
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
localBaseDirDef=/home/$LOGNAME

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

# get options (heading ':' to disable the verbose error handling)
lSerGiven=0
lPatGiven=0
while getopts  ":hd:t:s:R" opt ; do
    case $opt in
	t)
	    # paths
	    if [ ${lPatGiven} -eq 0 ] ; then
		destPath="${OPTARG}"
	    elif [ ${lPatGiven} -eq 1 ] ; then
		sourcePath="${OPTARG}"
	    fi
	    let lPatGiven+=1
	    ;;
	d)
	    # the user is requesting a specific study
	    currStudy="${OPTARG}"
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
		storageServiceSource="${OPTARG}"
	    fi
	    let lSerGiven+=1
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

preliminaryChecks

setCommand

echo "${comProt} ${fullSource} ${fullDest}"

