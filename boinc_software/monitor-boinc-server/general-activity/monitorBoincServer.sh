#!/bin/bash

# by A.Mereghetti

serverStatusReport=https://lhcathome.cern.ch/sixtrack/server_status.php

# time stamp
rightNow=`date +"%F %T"`
currDay=`echo "${rightNow}" | awk '{print ($1)}'`
currTim=`echo "${rightNow}" | awk '{print ($2)}'`

#
echo ""
echo "new query at: ${rightNow}"

# parse data
echo " getting report from server and parsing data..."
EXIT_STATUS=10
while [ $EXIT_STATUS -eq 10 ] ; do
    tmpCommand="python parseHTML.py --url ${serverStatusReport} -d ${currDay} -t ${currTim}"
    # echo " running command: ${tmpCommand}"
    ${tmpCommand}
    EXIT_STATUS=$?
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
