#!/bin/bash

archiveDir="$PWD/archive"

echo ""
echo " auto archiving running at `date`"
echo " archive dir: ${archiveDir}"

echo " moving files..."
for tmpDatFile in `ls -1 *.dat *.pdf` ; do
    tmpPeriod=${tmpDatFile:10:7}
    [ -d ${archiveDir}/${tmpPeriod} ] || mkdir ${archiveDir}/${tmpPeriod}
    mv ${tmpDatFile} ${archiveDir}/${tmpPeriod}
done

# ------------------------------------------------------------------------------
# done
# ------------------------------------------------------------------------------
echo " ...done."
