#!/bin/bash

# by A.Mereghetti

serverStatusReport=https://lhcathome.cern.ch/lhcathome/server_status.php

# time stamp
rightNow=`date +"%F %T"`
currDay=`echo "${rightNow}" | awk '{print ($1)}'`
currTim=`echo "${rightNow}" | awk '{print ($2)}'`

#
echo ""
echo "new query at: ${rightNow} - on host `hostname -s`"

# parse data
echo " getting report from server and parsing data..."
EXIT_STATUS=10
iCount=0
while [ $EXIT_STATUS -eq 10 ] ; do
    # export PYTHONHTTPSVERIFY=0  # issue with certificate
    tmpCommand="python parseHTML.py --url ${serverStatusReport} -d ${currDay} -t ${currTim}"
    # echo " running command: ${tmpCommand}"
    ${tmpCommand}
    EXIT_STATUS=$?
    let iCount=${iCount}+1
    if [ ${iCount} -ge 10 ] ; then
	echo " ...tried to download server page but encountered error for too many times! Aborting..."
	echo " ...done."
	exit 1
    fi
    echo " `date` - exit status of parser: $EXIT_STATUS"
    sleep 3
done

# plot
echo " updating plots..."
gnuplot plotData.gnu
ps2pdf status_${currDay}.ps
rm status_${currDay}.ps

#
echo " ...done."
