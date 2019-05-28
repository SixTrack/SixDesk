#!/bin/bash

period='2019-05'
toolsdir=`dirname $0`

# create temporary period files
for what in server SixTrack sixtracktest ; do
    tmpWhat="${what}_status"
    tmpFiles=`\ls -1 ${tmpWhat}_${period}-*.dat`
    rm -f ${tmpWhat}_${period}.dat
    for tmpFile in ${tmpFiles[@]} ; do
	cat ${tmpFile} >> ${tmpWhat}_${period}.dat
    done
done

sed -i "s/^period=.*/period='${period}'/" ${toolsdir}/plotData_period.gnu
gnuplot ${toolsdir}/plotData_period.gnu
ps2pdf status_${period}.ps
rm status_${period}.ps
