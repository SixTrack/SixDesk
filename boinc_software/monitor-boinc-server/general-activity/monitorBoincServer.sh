#!/bin/bash

serverStatusReport=http://lhcathomeclassic.cern.ch/sixtrack/server_status.php

# time stamp
rightNow=`date +"%F %T"`
currDay=`echo "${rightNow}" | awk '{print ($1)}'`
currTim=`echo "${rightNow}" | awk '{print ($2)}'`

#
echo ""
echo "new query at: ${rightNow}"

# parse data
echo " getting report from server and parsing data..."
python parseHTML.py --url ${serverStatusReport} -d ${currDay} -t ${currTim}

# plot
echo " updating plots..."
gnuplot plotData.gnu
ps2pdf status_${currDay}.ps
rm status_${currDay}.ps

#
echo " ...done."
