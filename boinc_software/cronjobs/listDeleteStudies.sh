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

# list spooldirs that can be labelled for deletion and
#    ask confirmation to user
now=`date +"%F_%H-%M-%S"`
# find old directories
allStudies=`find . -maxdepth 1 -type d -ctime +${oldN}`
for tmpStudy in ${allStudies} ; do
    tmpUserName=`cat ${tmpStudy}/owner`
    if [ -n "${tmpUserName}" ] ; then
	appendFile=/tmp/delete_${tmpUserName}_${now}.txt
    else
	appendFile=/tmp/delete_amereghe_${now}.txt
    fi
    echo "${tmpStudy}" >> ${appendFile}
    echo "added study ${tmpStudy} to ${appendFile}"
done

allUsers=`ls -1 /tmp/delete_*txt | cut -d\_ -f2`
for tmpUserName in ${allUsers} ; do
    echo "sending notification to ${tmpUserName} ..."
    allStudies=`cat /tmp/delete_${tmpUserName}_${now}.txt`
    echo -e "`cat ${SCRIPTDIR}/mail.txt`\n`\du -ch --summarize ${allStudies}`" | sed -e "s/<SixDeskUser>/${tmpUserName}/g" -e "s#<spooldir>#${BOINCspoolDir}#g" -e "s/<xxx>/${oldN}/g" | mail -a /tmp/delete_${tmpUserName}_${now}.txt -c amereghe@cern.ch -s 'old studies in BOINC spooldir' amereghe@cern.ch
    rm /tmp/delete_${tmpUserName}_${now}.txt
done

echo " ...ending at `date` ."
