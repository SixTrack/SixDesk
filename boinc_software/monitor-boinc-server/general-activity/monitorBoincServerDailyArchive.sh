#!/bin/bash

archiveDir="$PWD/archive"

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
    sed -i "s/^period=.*/period=\'${logDirName}\'/" ${archiveDir}/plotPeriod.sh
    echo " ...new month!"
fi

echo " copying files..."
cp *.dat *.pdf ${archiveDir}/${logDirName}

echo " running plotPeriod.sh..."
cd ${archiveDir}/${logDirName}
${archiveDir}/plotPeriod.sh
cd - > /dev/null 2>&1

# ------------------------------------------------------------------------------
# done
# ------------------------------------------------------------------------------
echo " ...done."
