#!/bin/bash

period='2017-01'
toolsdir=`dirname $0`

# create temporary period file
# - general status
tmpFiles=`\ls -1 server_status_${period}-*.dat`
rm -f server_status_${period}.dat
for tmpFile in ${tmpFiles[@]} ; do
    cat ${tmpFile} >> server_status_${period}.dat
done
# - sixtrack status
tmpFiles=`\ls -1 SixTrack_status_${period}-*.dat`
rm -f SixTrack_status_${period}.dat
for tmpFile in ${tmpFiles[@]} ; do
    cat ${tmpFile} >> SixTrack_status_${period}.dat
done

sed -i "s/^period=.*/period='${period}'/" ${toolsdir}/plotData_period.gnu
gnuplot ${toolsdir}/plotData_period.gnu
ps2pdf status_${period}.ps
rm status_${period}.ps
