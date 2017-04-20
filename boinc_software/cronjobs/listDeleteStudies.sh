#!/bin/bash

# A.Mereghetti, 2017-04-04
# find studies to be deleted; then, send an email for confirmation
# to be run in:
#     /afs/cern.ch/work/b/boinc/boinc
oldN=30 # days
BOINCspoolDir=$PWD
SCRIPTDIR=`dirname $0`
SCRIPTDIR="`cd ${SCRIPTDIR} ; pwd`"

echo " starting `basename $0` at `date` ..."

# prepare delete dir
[ -d delete ] || mkdir delete

echo " checking BOINC spooldir ${BOINCspoolDir} ..."

# list spooldirs that can be labelled for deletion and
#    ask confirmation to user
now=`date +"%F_%H-%M-%S"`
# find old directories
allStudies=`find . -maxdepth 1 -type d -ctime +${oldN} | grep -v -e upload -e delete`
for tmpStudy in ${allStudies} ; do
    if [ -e ${tmpStudy}/owner ] ; then
	ownerFromFile=`cat ${tmpStudy}/owner`
    else
	ownerFromFile="-"
    fi
    ownerFromUnix=`\ls -ld ${tmpStudy} | awk '{print ($3)}'`
    echo "${tmpStudy}" >> /tmp/delete_${ownerFromUnix}_${now}.txt
    if [ "${ownerFromFile}" == "-" ] ; then
	echo "${tmpStudy}" >> /tmp/no_owner_${now}.txt
    elif [ "${ownerFromFile}" != "${ownerFromUnix}" ] ; then
	echo "${tmpStudy}" >> /tmp/mismatched_owners_${now}.txt
    fi
    echo "study ${tmpStudy} belongs to ${ownerFromFile}/${ownerFromUnix} (owner file / unix)"
done

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

echo " ...ending at `date` ."
