#!/bin/bash

boincSpoolDirPath=/afs/cern.ch/work/b/boinc/boinc

for tmpStudy in `ls -1d */ | grep -v -e private -e public` ; do
    tmpStudy=${tmpStudy//\//}
    if [ -d ${boincSpoolDirPath}/${tmpStudy} ] ; then
	mv ${tmpStudy}/work/* ${boincSpoolDirPath}/${tmpStudy}/work
    else
	mv ${tmpStudy} ${boincSpoolDirPath}
    fi
done