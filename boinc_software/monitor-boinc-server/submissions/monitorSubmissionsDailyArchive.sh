#!/bin/bash

archiveDir="$PWD/archive"

echo ""
echo " auto archiving running at `date`"
echo " archive dir: ${archiveDir}"

echo " moving files..."
for tmpDatFile in `ls -1 submitAll*.dat submitAll*.pdf` ; do
    tmpPeriod=${tmpDatFile:10:7}
    [ -d ${archiveDir}/${tmpPeriod} ] || mkdir ${archiveDir}/${tmpPeriod}
    mv ${tmpDatFile} ${archiveDir}/${tmpPeriod}
done
for tmpDatFile in `ls -1 assimilateAll_*.dat` ; do
    tmpPeriod=${tmpDatFile:14:7}
    [ -d ${archiveDir}/${tmpPeriod} ] || mkdir ${archiveDir}/${tmpPeriod}
    mv ${tmpDatFile} ${archiveDir}/${tmpPeriod}
done

# ------------------------------------------------------------------------------
# done
# ------------------------------------------------------------------------------
echo " ...done."
