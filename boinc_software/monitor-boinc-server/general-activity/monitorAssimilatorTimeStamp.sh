#!/bin/bash

sixtrackProjPath="/share/boinc/project/sixtrack"
assimilatorLogFileName="log_boincai08/sixtrack_assimilator.log"
lastMtimeFile='lastMtimeAssimilator.txt'
logFilesPath="."

echo " starting `basename $0` at `date` ..."

presTime=`ssh amereghe@boincai08.cern.ch "cd /afs/cern.ch/user/a/amereghe/Downloads/monitorBoincServer ; stat ${sixtrackProjPath}/${assimilatorLogFileName} | grep Modify"`
# from boincai08 -> cd /afs/cern.ch/user/a/amereghe/Downloads/monitorBoincServer
# from boincai08 -> presTime=`stat ${sixtrackProjPath}/${assimilatorLogFileName} | grep Modify`
# parse presTime, removing the fractional part of seconds
presTime=`echo "${presTime}" | awk '{print ($2,$3)}' | cut -d\. -f1`
presUpdate=0

if [ -e ${lastMtimeFile} ] ; then
    lastTime=`cat ${lastMtimeFile} | head -1`
    lastUpdate=`cat ${lastMtimeFile} | head -2 | tail -1`
    if [ "${presTime}" == "${lastTime}" ] ; then
	if [ ${lastUpdate} -eq 0 ] ; then
	    # first time that the assimilator log does not get updated
	    echo "assimilator stuck: ${presTime}"
	    echo "${presTime}" >> ${logFilesPath}/assimilatorStuck.txt
	    echo "" | mail -s 'assimilator stuck' amereghe@cern.ch
	else
	    echo "assimilator still stuck at `date +%Y-%m-%d\ %H:%M:%S`"
	fi
	presUpdate=1
    else
	if [ ${lastUpdate} -eq 1 ] ; then
	    # assimilator log restarted
	    echo "assimilator restarted: ${presTime}"
	    echo "${presTime}" >> ${logFilesPath}/assimilatorRestart.txt
	else
	    echo "assimilator running regularly"
	fi
    fi
fi

echo "${presTime}" > ${lastMtimeFile}
echo "${presUpdate}" >> ${lastMtimeFile}

echo " ...done."
