#!/bin/bash

period='2017-01'
periodFile='server_status_'${period}'.dat'
toolsdir=`dirname $0`

# create temporary period file
tmpFiles=`\ls -1 *${period}-*.dat`
rm -f ${periodFile}
for tmpFile in ${tmpFiles[@]} ; do
    cat ${tmpFile} >> ${periodFile}
done

sed -i "s/^period=.*/period='${period}'/" ${toolsdir}/plotData_period.gnu
gnuplot ${toolsdir}/plotData_period.gnu
ps2pdf server_status_${period}.ps
rm server_status_${period}.ps
