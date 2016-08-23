#!/bin/bash

# A.Mereghetti, 2016-08-18
# script for zipping WUs according to study name
iNLT=200

echo ""
echo " starting zipping at `date` ..."
STARTTIME=$(date +%s)

# get new WUs (grep -v is redundant, but it is kept for security)
WUs2bZipped=`find -mmin +5 -name "*__*" | grep -v '.zip'`

# get study names and simple statistics
studyNameStats=`echo "${WUs2bZipped}" | awk 'BEGIN{FS="__"}{print ($1)}' | sort | uniq -c`
echo " ...studies involved:"
echo "${studyNameStats}"

# actually zip
studyNames=`echo "${studyNameStats}" | awk '{print ($2)}'`
studyNames=( ${studyNames} )
for studyName in ${studyNames[@]} ; do
    WUnames=`echo "${WUs2bZipped}" | grep ${studyName}`
    # zip/rm WUs in bunches
    nWUnames=`echo "${WUnames}" | wc -l`
    iiMax=`echo "${iNLT} ${nWUnames}" | awk '{print (int($2/$1*1.0))}'`
    nResiduals=`echo "${iNLT} ${nWUnames} ${iiMax}" | awk '{print ($2-$3*$1)}'`
    for (( ii=1; ii<=${iiMax} ; ii++ )) ; do
	let nHead=$ii*$iNLT
	tmpWUnames=`echo "${WUnames}" | head -n ${nHead} | tail -n ${iNLT}`
	zip ${studyName}.zip ${tmpWUnames}
	rm ${tmpWUnames}
    done
    if [ ${nResiduals} -gt 0 ] ; then
	tmpWUnames=`echo "${WUnames}" | tail -n ${nResiduals}`
	zip ${studyName}.zip ${tmpWUnames}
	rm ${tmpWUnames}
    fi
    # zip/rm one WUs at time
    # WUnames=( ${WUnames} )
    # for WUname in ${WUnames[@]} ; do
    # 	zip ${studyName}.zip ${WUname}
    # 	rm ${WUname}
    # done
    # zip/rm all WUs in one go
    # zip ${studyName}.zip ${WUnames}
    # rm ${WUnames}
done

# done
ENDTIME=$(date +%s)
TIMEDELTA=$(($ENDTIME - $STARTTIME))
echo " ...done by `date` - it took ${TIMEDELTA} seconds to zip `echo "${WUs2bZipped=}" | wc -l` WUs."