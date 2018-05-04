#!/bin/bash

nDays=60

echo ""
echo "--> cleaning at `date`"

# 
echo "--> remove all files older than ${nDays} days..."
find . -mtime +${nDays} -name "*.zip" -print -exec rm {} \;

# 
echo "--> remove all directories with no .zip files at all"
for tmpDir in `find . -maxdepth 1 -type d -exec bash -c "echo -ne '{} '; ls '{}' | wc -l" \; | awk '$NF==1 {print ($1)}'` ; do
    deleteDir=`find ${tmpDir} -maxdepth 1 -type d -exec bash -c "echo -ne '{} '; ls '{}' | wc -l" \; | awk '$NF==0 {print ($1)}'`
    if [ -n "${deleteDir}" ] ; then
	tree ${tmpDir}
	rm -rf ${tmpDir}
    fi
done
