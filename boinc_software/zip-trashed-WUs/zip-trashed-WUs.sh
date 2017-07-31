#!/bin/bash

# A.Mereghetti, 2016-08-18
# script for zipping WUs according to study name
iNLT=400
boincDownloadDir="/afs/cern.ch/work/b/boinc/download"
boincSpoolDirPath="/afs/cern.ch/work/b/boinc"
allDir=all
zipToolDir=`basename $0`
zipToolDir=${zipToolDir//.sh}

boincdir=/data/boinc/project/sixtrack
host=$(hostname -s)
lockdir=$boincdir/pid_$host
[ -d $lockdir ] || mkdir $lockdir
lockfile=$lockdir/$(basename $0).lock

function getlock(){
    if  ln -s PID:$$ $lockfile >/dev/null 2>&1 ; then
	trap " rm $lockfile; echo \" Relase lock $lockfile\"" EXIT
	echo " got lock $lockfile"
    else 
	echo "$lockfile already exists. $PWD/$0 already running? Abort..."
	#never get here
	exit 1
    fi
}

function mvZip(){
    local __fileToCopy=$1
    local __studyName=$2
    
    for __destDir in `ls -1d ${boincSpoolDirPath}/` ; do
	local __destPath=${__destDir}/${__studyName}/results
	! [ -d ${__destPath} ] || break
    done
    if ! [ -d ${__destPath} ] ; then
	if ${lGenDownloadDir} ; then
	    # day dir in download area
	    boincDownloadDir=${boincDownloadDir}/`date "+%Y-%m-%d"`
	    [ -d ${boincDownloadDir} ] || mkdir -p ${boincDownloadDir}
	    [ -d ${boincDownloadDir}/processed ] || mkdir -p ${boincDownloadDir}/processed
	    lGenDownloadDir=false
	fi
	local __destPath=${boincDownloadDir}
    fi
    echo "...cp ${__fileToCopy} ${__destPath}"
    cp ${__fileToCopy} ${__destPath}
    if [ $? -eq 0 ] ; then
	rm -f ${__fileToCopy}
    fi
}

function zipAll(){
    # - WUnames: WUs to be zipped
    # - zipFileName: name of zip file
    # - Nzipped: total number of zipped WUs
    
    # zip/rm WUs in bunches
    local __nWUnames=`echo "${WUnames}" | wc -l`
    local __iiMax=`echo "${iNLT} ${__nWUnames}" | awk '{print (int($2/$1*1.0))}'`
    local __nResiduals=`echo "${iNLT} ${__nWUnames} ${__iiMax}" | awk '{print ($2-$3*$1)}'`
    for (( __ii=1; __ii<=${__iiMax} ; __ii++ )) ; do
	let __nHead=$__ii*$iNLT
	local __tmpWUnames=`echo "${WUnames}" | head -n ${__nHead} | tail -n ${iNLT}`
	zip ${zipFileName} ${__tmpWUnames}
	rm ${__tmpWUnames}
    done
    if [ ${__nResiduals} -gt 0 ] ; then
	local __tmpWUnames=`echo "${WUnames}" | tail -n ${__nResiduals}`
	zip ${zipFileName} ${__tmpWUnames}
	rm ${__tmpWUnames}
    fi

    # count
    let Nzipped+=${__nWUnames}
    
}

# ==============================================================================
# start
# ==============================================================================

echo ""
echo " starting `basename $0` at `date` ..."

# adding lock mechanism
getlock

lGenDownloadDir=true

STARTTIME=$(date +%s)
Nzipped=0

# ==============================================================================
# treat all
# ==============================================================================

cd ${allDir}

# get new WUs (grep -v is redundant, but it is kept for security)
WUs2bZipped=`find -mmin +5 -name "*__*" | grep -v '.zip'`

if [ -n "${WUs2bZipped}" ] ; then
    # get study names and simple statistics
    studyNameStats=`echo "${WUs2bZipped}" | awk 'BEGIN{FS="__"}{print ($1)}' | sort | uniq -c`

    echo " ... ${allDir} - studies involved:"
    echo "${studyNameStats}"

    # actually zip and move to boincDownloadDir
    for studyName in `echo "${studyNameStats}" | awk '{print ($2)}'` ; do
        # fileName of .zip
	zipFileName=${studyName}__`date "+%Y-%m-%d_%H-%M-%S"`.zip
	WUnames=`echo "${WUs2bZipped}" | grep ${studyName}`
        # zip
	zipAll
	# move
	mvZip ${zipFileName} ${studyName}
    done

    # moving old or remaining .zip files
    echo " old .zip files ..."
    for fileName in `find . -name "*.zip"` ; do
	mvZip ${fileName} ${fileName%%__*}
    done
else
    echo " ...no WUs in ${allDir}!"
fi

cd - > /dev/null 2>&1

# ==============================================================================
# treat studies
# ==============================================================================

for studyName in `ls -1d * | grep -v -e ${allDir} -e ${zipToolDir}` ; do
    echo " ...study ${studyName}"
    cd ${studyName}

    # get ready for zipping and moving
    WUnames=`find -mmin +5 -name "*__*" | grep -v '.zip'`
    if [ -n "${WUnames}" ] ; then
	zipFileName=${studyName}__`date "+%Y-%m-%d_%H-%M-%S"`.zip
        # zip
	zipAll
	# move
	mvZip ${zipFileName} ${studyName}
    
        # moving old .zip files
	echo " old .zip files ..."
	for fileName in `find . -name "*.zip"` ; do
	    mvZip ${fileName} ${studyName}
	done
    else
	echo " ...no WUs in ${studyName}!"
    fi

    # get ready for next study
    cd - > /dev/null 2>&1
done

# ==============================================================================
# close processing
# ==============================================================================

# rm empty dirs
# NB: all might be empty - it is not actually, thanks to: all/.doNotRemoveMe
echo " finding and removing empty dirs..."
find . -maxdepth 1 -type d -empty -delete -print

ENDTIME=$(date +%s)

# done
TIMEDELTA=$(($ENDTIME - $STARTTIME))
echo " ...done by `date` - it took ${TIMEDELTA} seconds - zipped ${Nzipped} WUs."
