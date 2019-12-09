#!/bin/bash

# A.Mereghetti, 2016-08-18
# script for zipping WUs according to study name
iNLT=400
boincDownloadDir="/afs/cern.ch/work/b/boinc/download"
boincSpoolDirPath="/afs/cern.ch/work/b/boinc"
allDir=all
abnDir=abnormal
zipToolDir=`basename $0`
zipToolDir=${zipToolDir//.sh}
initDir=$PWD
tmpDirBase=/tmp/sixtadm/`basename $0`
lTest=false

boincdir=/data/boinc/project/sixtrack
host=$(hostname -s)
#
logdir=$boincdir/log_$host
[ -d $logdir ] || mkdir $logdir
LOGFILE="$logdir/$(basename $0).log"
#
lockdir=$boincdir/pid_$host
[ -d $lockdir ] || mkdir $lockdir
lockfile=$lockdir/$(basename $0).lock

function log(){ # log_message
    if [ $# -gt 0 ] ; then 
	logtofile "$*"
    else
	local line
	while read line ; do 
	        logtofile "$line"
		done
    fi
}   

function logtofile(){ #[opt-file] log_message
    local logfile
    logfile="$LOGFILE"
    if [ $# -gt 1 ] ; then 
	logfile="$logdir/$1"
	shift
    fi
    echo "$(date -Iseconds) $1" >>"$logfile"
}

function getlock(){
    if  ln -s PID:$$ $lockfile >/dev/null 2>&1 ; then
	if ${lTest} ; then
 	    trap "rm $lockfile; log \" Relase lock $lockfile\"" EXIT
	else
 	    trap "log \" cleaning ${tmpDirBase} away...\" ; rm -rf ${tmpDirBase} ; rm $lockfile; log \" Relase lock $lockfile\"" EXIT
	fi
	log "got lock $lockfile"
    else 
	log "$lockfile already exists. $PWD/$0 already running? Abort..."
	#never get here
	exit 1
    fi
}

function treatStudy(){
    # global vars:
    # - tmpDirBase

    local __studyName=$1

    # fileName of .zip
    local __zipFileName=${__studyName}__`date "+%Y-%m-%d_%H-%M-%S"`
    # tmpDir
    local __tmpDir=${tmpDirBase}/${__zipFileName}
    mkdir -p ${__tmpDir}
    log "...zipping performed in tmp dir ${__tmpDir} ..."
    # actual fileName of .zip
    __zipFileName=${__zipFileName}.zip
    # zip
    zipAll ${__zipFileName} ${__tmpDir}
    # move
    mvZip ${__tmpDir}/${__zipFileName} ${__studyName}
}

function mvZip(){
    # global vars:
    # - boincSpoolDirPath
    # - lGenDownloadDir
    # - boincDownloadDir
    # - tmpDirBase
    
    local __fileToCopy=$1
    local __studyName=$2
    
    for __destDir in `ls -1d ${boincSpoolDirPath}/*/` ; do
	local __destPath=${__destDir}${__studyName}/results
	! [ -d ${__destPath} ] || break
    done
    if ! [ -d ${__destPath} ] ; then
	if ${lGenDownloadDir} ; then
	    # day dir in download area, only if required
	    boincDownloadDir=${boincDownloadDir}/`date "+%Y-%m-%d"`
	    [ -d ${boincDownloadDir} ] || mkdir -p ${boincDownloadDir}
	    [ -d ${boincDownloadDir}/processed ] || mkdir -p ${boincDownloadDir}/processed
	    lGenDownloadDir=false
	fi
	local __destPath=${boincDownloadDir}
    fi
    log "...cp ${__fileToCopy} ${__destPath}"
    cp ${__fileToCopy} ${__destPath}
    if [ $? -eq 0 ] ; then
	# rm zip file
	log "...cleaning: rm -f ${__fileToCopy}"
	rm -f ${__fileToCopy}
    else
        if [[ "${__fileToCopy}" == "${tmpDirBase}"* ]] ; then
            # in case of zip in a subfolder of ${tmpDirBase}, copy it here
            cp ${__fileToCopy} .
        fi
    fi
}

function zipAll(){
    # global vars:
    # - WUnames: WUs to be zipped
    # - tmpWUnames: WUs to be zipped
    # - Nzipped: total number of zipped WUs
    local __zipFileName=$1
    local __tmpDir=$2
    
    # zip/rm WUs in bunches
    local __nWUnames=`echo "${WUnames}" | wc -l`
    local __iiMax=`echo "${iNLT} ${__nWUnames}" | awk '{print (int($2/$1*1.0))}'`
    local __nResiduals=`echo "${iNLT} ${__nWUnames} ${__iiMax}" | awk '{print ($2-$3*$1)}'`
    for (( __ii=1; __ii<=${__iiMax} ; __ii++ )) ; do
	let __nHead=$__ii*$iNLT
	tmpWUnames=`echo "${WUnames}" | head -n ${__nHead} | tail -n ${iNLT}`
        actualZip ${__zipFileName} ${__tmpDir}
    done
    if [ ${__nResiduals} -gt 0 ] ; then
	tmpWUnames=`echo "${WUnames}" | tail -n ${__nResiduals}`
        actualZip ${__zipFileName} ${__tmpDir}
    fi

    # count
    let Nzipped+=${__nWUnames}
}

function actualZip(){
    # global vars:
    # - tmpWUnames: WUs to be zipped
    local __zipFileName=$1
    local __tmpDir=$2
    
    local __currDir=$PWD
    cp ${tmpWUnames} ${__tmpDir}
    cd ${__tmpDir}
    zip ${__zipFileName} ${tmpWUnames} 2>&1 | log
    local __zipStatus=$?
    # rm result files in ${__tmpDir}
    if ! ${lTest} ; then
	if [ ${__zipStatus} -eq 0 ] ; then
	    log "...cleaning results just zipped in ${__tmpDir}"
	    rm ${tmpWUnames}
	fi
    fi
    cd ${__currDir}
    # rm result files in ${__currDir}
    if ! ${lTest} ; then
	if [ ${__zipStatus} -eq 0 ] ; then
	    log "...cleaning original results in ${__currDir}"
	    rm ${tmpWUnames}
	fi
    fi
}

# ==============================================================================
# start
# ==============================================================================

log ""
log "starting `basename $0` at `date` ..."

# adding lock mechanism
getlock

lGenDownloadDir=true

STARTTIME=$(date +%s)
Nzipped=0

# ==============================================================================
# treat all/ dir
# ==============================================================================

cd ${allDir}

# get WUs (grep -v is redundant, but it is kept for security)
WUs2bZipped=`find . -mmin +5 -name "*__*" | grep -v '.zip'`

if [ -n "${WUs2bZipped}" ] ; then
    # get study names and simple statistics
    studyNameStats=`echo "${WUs2bZipped}" | awk 'BEGIN{FS="__"}{print ($1)}' | sort | uniq -c`

    log "... ${allDir} - studies involved:"
    log "# N_WUs, wSpace_studyName"
    log "${studyNameStats}"

    # actually zip and move to boincDownloadDir
    for studyName in `echo "${studyNameStats}" | awk '{print ($2)}'` ; do
	WUnames=`echo "${WUs2bZipped}" | grep ${studyName}`
	treatStudy ${studyName}
    done

else
    log "...only super-recent WUs or no WUs at all in ${allDir}! - skipping..."
fi

cd ${initDir}

# ==============================================================================
# treat abnormal/ dir
# ==============================================================================

cd ${abnDir}

# get WUs (grep -v is redundant, but it is kept for security)
WUs2bZipped=`find . ! -path . -mmin +5 | grep -v -e '.zip' -e .doNotRemoveMe`

if [ -n "${WUs2bZipped}" ] ; then

    log "... ${abnDir} - results involved:"
    log "${WUs2bZipped}"

    # actually zip and move to boincDownloadDir
    WUnames="${WUs2bZipped}"
    treatStudy abnormal

else
    log "...only super-recent WUs or no WUs at all in ${abnDir}! - skipping..."
fi

cd ${initDir}

# ==============================================================================
# treat studies
# ==============================================================================

for studyName in `ls -1d * | grep -v -e "^${allDir}$" -e "^${abnDir}$" -e "^${zipToolDir}$"` ; do
    log "...study ${studyName}"
    cd ${studyName}

    # get ready for zipping and moving
    WUnames=`find . -mmin +5 -name "*__*" | grep -v '.zip'`
    if [ -n "${WUnames}" ] ; then
	treatStudy ${studyName}
    else
	log "...only super-recent WUs in ${studyName}! - skipping..."
    fi

    # get ready for next study
    cd ${initDir}
done

# ==============================================================================
# close processing
# ==============================================================================

# moving old or remaining .zip files
log "old .zip files ..."
for fileName in `find . -name "*.zip"` ; do
    studyName=`basename ${fileName}`
    studyName=${studyName%%__*}
    log "--> mvZip ${fileName} ${studyName}"
    mvZip ${fileName} ${studyName}
done

# rm empty dirs
# NB: all might be empty - it is not actually, thanks to: all/.doNotRemoveMe
log "finding and removing empty dirs..."
find . -maxdepth 1 -type d -empty -delete -print | log

ENDTIME=$(date +%s)

# done
TIMEDELTA=$(($ENDTIME - $STARTTIME))
log "...done by `date` - it took ${TIMEDELTA} seconds - zipped ${Nzipped} WUs."
