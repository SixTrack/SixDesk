#!/bin/bash

# A.Mereghetti, 2017-04-04
# delete studies dirs in BOINC spooldir
# the dirs to be deleted are listed in txt files
# to be run in:
#     /afs/cern.ch/work/b/boinc/boinc

echo " starting `basename $0` at `date` ..."

# delete spooldirs labelled for deletion
for userfile in `ls -1 delete/*` ; do
    echo ""
    echo "file ${userfile} ..."
    dos2unix ${userfile}
    allStudies=`grep . ${userfile} | grep -v '#' | awk '{for (ii=1;ii<=NF;ii++) {print ($ii)}}'`
    for tmpStudy in ${allStudies} ; do
	if [ -d ${tmpStudy} ] ; then
	    echo "rm -rf ${tmpStudy}"
	    rm -rf ${tmpStudy}
	fi
    done
    echo "rm ${userfile}"
    rm ${userfile}
done

echo " ...ending at `date` ."
