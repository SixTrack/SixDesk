#!/bin/bash

# A.Mereghetti, 2017-04-04
# delete studies dirs in BOINC spooldir
# the dirs to be deleted are listed in txt files
# to be run in:
#     /afs/cern.ch/work/b/boinc/boinc

echo ""
echo ""
echo " starting `basename $0` at `date` - spooldir: ${PWD} ..."

ls -1  delete/* > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    # delete spooldirs labelled for deletion
    for userfile in `ls -1 delete/*` ; do
	echo ""
	echo "file ${userfile} ..."
	dos2unix ${userfile}
	allStudies=`grep . ${userfile} | grep -v '#' | awk '{for (ii=1;ii<=NF;ii++) {print ($ii)}}'`
	echo "removing the following study dirs and freeing space:"
	duLines=`\du -ch --summarize ${allStudies}`
	nStudies=`echo "${allStudies}" | wc -l`
	for tmpStudy in ${allStudies} ; do
	    if [ -d ${tmpStudy} ] ; then
		echo "rm -rf ${tmpStudy}"
		rm -rf ${tmpStudy}
	    fi
	done
	echo "rm ${userfile}"
	rm ${userfile}
	echo " ...for ${nStudies} studies: `tail -1 \"${duLines}\"`;"
    done
else
    echo " nothing to do: no files in delete/"
fi
echo " ...ending at `date` ."
