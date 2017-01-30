#!/bin/bash

archiveDir="/afs/cern.ch/user/a/amereghe/Downloads/monitorBoincServer/submissions/archive"

# time stamp
year=`date +"%Y"`
month=`date +"%m"`
logDirName="$year-$month"

echo ""
echo " auto archiving running at `date`"
echo " archive dir: ${archiveDir}"
echo " period dir: ${logDirName}" 

if [ ! -d ${archiveDir}/${logDirName} ] ; then
    mkdir ${archiveDir}/${logDirName}
# AM ->    sed -i "s/^period=.*/period=\'${logDirName}\'/" ${archiveDir}/plotPeriod.sh
    echo " ...new month!"
fi

echo " moving files..."
mv *.dat *.pdf ${archiveDir}/${logDirName}

# AM -> echo " running plotPeriod.sh..."
# AM -> cd ${archiveDir}/${logDirName}
# AM -> ${archiveDir}/plotPeriod.sh
# AM -> cd - > /dev/null 2>&1

# ------------------------------------------------------------------------------
# done
# ------------------------------------------------------------------------------
echo " ...done."
