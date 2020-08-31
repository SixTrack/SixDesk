#!/bin/bash

for iFile in `find ../ -name "server_status*.dat"` ; do
    echo file "${iFile}"
    awk '{if (NF!=16 && $1!="#") {print ("#",$0)}else{print ($0)}}' ${iFile} > temp.dat
    tmpDiff=`diff ${iFile} temp.dat`
    if [ -n "${tmpDiff}" ] ; then
	echo "${tmpDiff}" | colordiff
	mv temp.dat ${iFile}
    fi
    sed -i 's/# #/#/g' ${iFile}
done
rm temp.dat




