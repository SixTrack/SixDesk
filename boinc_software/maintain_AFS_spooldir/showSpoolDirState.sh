#!/bin/bash

echo "# study, number of waiting jobs, number of problematic files, disk occupancy: work,results"
for tmpWorkDir in `find . -maxdepth 2 -type d -name "work"` ; do
    nFiles=`ls -1 ${tmpWorkDir}/*.desc 2> /dev/null | wc -l`
    nFilesProbl=`ls -1 ${tmpWorkDir}/*.desc.problem 2> /dev/null | wc -l`
    diskOccupancyWork=`\du -csh ${tmpWorkDir}/ | tail -1 | awk '{print ($(NF-1))}'`
    diskOccupancyResult=`\du -csh ${tmpWorkDir}/../results | tail -1 | awk '{print ($(NF-1))}'`
    [ ${nFiles} -eq 0 -a ${nFilesProbl} -eq 0 ] || echo ${tmpWorkDir} ${nFiles} - ${nFilesProbl} - ${diskOccupancyWork} ${diskOccupancyResult}
done