#!/bin/bash

sixtrackProjPath="/usr/local/boinc/project/sixtrack"
assimilatorLogFileName="log_boincai11/sixtrack_assimilator.log"
lastMtimeFile='lastMtimeAssimilator.txt'
logFilesPath="."
monitorBoincServerDir=$PWD

echo " starting `basename $0` at `date` ..."

presTime=`ssh sixtadm@boincai11.cern.ch "cd ${monitorBoincServerDir} ; stat ${sixtrackProjPath}/${assimilatorLogFileName} | grep Modify"`
# from boincai11 -> cd /afs/cern.ch/user/a/amereghe/Downloads/monitorBoincServer
# from boincai11 -> presTime=`stat ${sixtrackProjPath}/${assimilatorLogFileName} | grep Modify`
# parse presTime, removing the fractional part of seconds
presTime=`echo "${presTime}" | awk '{print ($2,$3)}' | cut -d\. -f1`
presUpdate=0

if [ -e ${lastMtimeFile} ] ; then
    lastTime=`head -1 ${lastMtimeFile}`
    lastUpdate=`head -2 ${lastMtimeFile} | tail -1`
    if [ "${presTime}" == "${lastTime}" ] ; then
	if [ ${lastUpdate} -eq 0 ] ; then
	    # first time that the assimilator log does not get updated
	    echo "assimilator stuck: ${presTime}"
	    echo "${presTime}" | tee -a ${logFilesPath}/assimilatorStuck.txt
	    echo "" | mail -s 'assimilator stuck' sixtadm@cern.ch
	else
	    echo "assimilator still stuck at `date +%Y-%m-%d\ %H:%M:%S`"
	fi
	presUpdate=1
    else
	if [ ${lastUpdate} -eq 1 ] ; then
	    # assimilator log restarted
	    echo "assimilator restarted: ${presTime}"
	    echo "${presTime}" | tee -a ${logFilesPath}/assimilatorRestart.txt
	else
	    echo "assimilator running regularly"
	fi
    fi
fi

echo "saving status in ${lastMtimeFile} ..."
echo "${presTime}" | tee ${lastMtimeFile}
echo "${presUpdate}" | tee -a ${lastMtimeFile}

echo " ...done."
