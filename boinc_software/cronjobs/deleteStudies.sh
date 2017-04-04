#!/bin/bash

# A.Mereghetti, 2017-04-04
# delete studies dirs in BOINC spooldir
# the dirs to be deleted are listed in txt files
# to be run in:
#     /afs/cern.ch/work/b/boinc/boinc

echo " starting `basename $0` at `date` ..."

# delete spooldirs labelled for deletion
[ -d delete ] || mkdir delete
for userfile in `ls -1 delete/*` ; do
    dos2unix ${userfile}
    echo "studies listed in file ${userfile} ..."
    allStudies=`grep . ${userfile} | grep -v '#' | awk '{for (ii=1;ii<=NF;ii++) {print ($ii)}}'`
    for tmpStudy in ${allStudies} ; do
	echo "rm -rf ${tmpStudy}"
	rm -rf ${tmpStudy}
    done
    echo "rm ${userfile}"
    rm ${userfile}
done

echo " ...ending at `date` ."
