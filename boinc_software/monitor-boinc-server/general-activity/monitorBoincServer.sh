#!/bin/bash

# time stamp
rightNow=`date +"%F %T"`
currDay=`echo "${rightNow}" | awk '{print ($1)}'`
currTim=`echo "${rightNow}" | awk '{print ($2)}'`

#
echo ""
echo "new query at: ${rightNow}"

# get data
wget http://lhcathomeclassic.cern.ch/sixtrack/server_status.php

# parse data
echo " parsing report from server..."
lines=`python parseHTML.py`

# echo in dat file
echo " updating data..."
dataLine=`echo $lines | awk '{gsub(/,/,"",$0); print ($0)}'`
echo "${currDay} ${currTim} ${dataLine}" >> server_status_${currDay}.dat

# plot
echo " updating plots..."
gnuplot plotData.gnu
ps2pdf server_status_${currDay}.ps
rm server_status_${currDay}.ps

# clean
echo " cleaning..."
rm server_status.php

#
echo " ...done."