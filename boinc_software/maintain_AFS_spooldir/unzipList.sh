#!/bin/bash

studyName="wfcchtc_job_arctripdipoctu_geb3_inj"
boincPath="/afs/cern.ch/work/b/boinc/boinc"

echo " analysing status of results of study ${studyName} in path ${boincPath} ..."

# unprocessed results
nFiles=0
totNfiles=0
for zipFile in `ls -1 ${boincPath}/${studyName}/results/*.zip` ; do
    let nFiles=${nFiles}+1
    currNFiles=`unzip -l ${zipFile} | grep "_0$" | wc -l`
    let totNfiles=${totNfiles}+${currNFiles}
done
echo " ...found ${nFiles} .zip archives for ${totNfiles} un-processed results!"

# processed results
nFiles=0
totNfiles=0
for zipFile in `ls -1 ${boincPath}/${studyName}/results/processed/*.zip` ; do
    let nFiles=${nFiles}+1
    currNFiles=`unzip -l ${zipFile} | grep "_0$" | wc -l`
    let totNfiles=${totNfiles}+${currNFiles}
done
echo " ...found ${nFiles} .zip archives for ${totNfiles} processed results!"
