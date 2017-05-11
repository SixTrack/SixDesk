#!/bin/bash

# A.Mereghetti, 2017-04-04
# find studies to be deleted; then, send an email for confirmation
# to be run in:
#     /afs/cern.ch/work/b/boinc/boinc
oldN=30 # days
BOINCspoolDir=$PWD
SCRIPTDIR=`dirname $0`
SCRIPTDIR="`cd ${SCRIPTDIR} ; pwd`"

function treatSingleDir(){
    local __tmpStudy=$1
    if [ -e ${__tmpStudy}/owner ] ; then
	local __ownerFromFile=`cat ${__tmpStudy}/owner`
    else
	local __ownerFromFile="-"
    fi
    local __ownerFromUnix=`\ls -ld ${__tmpStudy} | awk '{print ($3)}'`
    echo "${__tmpStudy}" >> /tmp/delete_${__ownerFromUnix}_${now}.txt
    if [ "${__ownerFromFile}" == "-" ] ; then
	echo "${__tmpStudy}" >> /tmp/no_owner_${now}.txt
    elif [ "${__ownerFromFile}" != "${__ownerFromUnix}" ] ; then
	echo "${__tmpStudy}" >> /tmp/mismatched_owners_${now}.txt
    fi
    echo "study ${__tmpStudy} belongs to ${__ownerFromFile}/${__ownerFromUnix} (owner file / unix)"
}

trap "echo \" ...ending at \`date\` .\" " exit
echo " starting `basename $0` at `date` ..."
lUseWork=true
if [ $# == 1 ] ; then
    lUseWork=false
fi

# prepare delete dir
[ -d delete ] || mkdir delete

echo " checking BOINC spooldir ${BOINCspoolDir} ..."

# list spooldirs that can be labelled for deletion and
#    ask confirmation to user
now=`date +"%F_%H-%M-%S"`
# find old directories (based on <workspace>_<studyName>/work/)
if ${lUseWork} ; then
    echo " find old directories based on <workspace>_<studyName>/work/ ..."
    allStudies=`find . -maxdepth 2 -type d -name work -ctime +${oldN}`
    for currCase in ${allStudies} ; do
	treatSingleDir ${currCase%/work}
    done
else
    echo " find old directories based on <workspace>_<studyName> only ..."
    allStudies=`find . -maxdepth 1 -type d -ctime +${oldN} | grep -v -e upload -e delete`
    for currCase in ${allStudies} ; do
	treatSingleDir ${currCase}
    done
fi

allUsers=`ls -1 /tmp/delete_*txt | cut -d\_ -f2`
for tmpUserName in ${allUsers} ; do
    echo "sending notification to ${tmpUserName} ..."
    fileList=delete_${tmpUserName}_${now}.txt
    allStudies=`cat /tmp/${fileList}`
    echo -e "`cat ${SCRIPTDIR}/mail.txt`\n`\du -ch --summarize ${allStudies}`" | sed -e "s/<SixDeskUser>/${tmpUserName}/g" -e "s#<spooldir>#${BOINCspoolDir}#g" -e "s/<xxx>/${oldN}/g" -e "s#<fileList>#${fileList}#g" | mail -a /tmp/${fileList} -c amereghe@cern.ch -s "old studies in BOINC spooldir ${BOINCspoolDir}" ${tmpUserName}@cern.ch
    rm /tmp/${fileList}
done

errorFiles=""
[ ! -e /tmp/no_owner_${now}.txt ] || errorFiles="${errorFiles} /tmp/no_owner_${now}.txt"
[ ! -e /tmp/mismatched_owners_${now}.txt ] || errorFiles="${errorFiles} /tmp/mismatched_owners_${now}.txt"
if [ -n "${errorFiles}" ] ; then
    echo "sending error notification to amereghe ..."
    echo "errors!" | mail -a /tmp/no_owner_${now}.txt -s "old studies in BOINC spooldir ${BOINCspoolDir} - errors!" amereghe@cern.ch
    rm -f /tmp/no_owner_${now}.txt
    rm -f /tmp/mismatched_owners_${now}.txt
fi
