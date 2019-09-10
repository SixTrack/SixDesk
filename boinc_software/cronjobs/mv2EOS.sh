#!/bin/bash

# A.Mereghetti, 2019-09-10
# script for zipping WUs according to study name
iNLT=400
boincDownloadDir="/afs/cern.ch/work/b/boinc/download"
boincSpoolDirPath="/afs/cern.ch/work/b/boinc"
allDir=all
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
