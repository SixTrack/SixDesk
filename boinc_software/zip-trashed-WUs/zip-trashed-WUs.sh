#!/bin/bash

# A.Mereghetti, 2016-08-18
# script for zipping WUs according to study name

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
    WUnames=( ${WUnames} )
    for WUname in ${WUnames[@]} ; do
	zip ${studyName}.zip ${WUname}
	rm ${WUname}
    done
    # all in one go
    # zip ${studyName}.zip ${WUnames}
    # rm ${WUnames}
done

# done
ENDTIME=$(date +%s)
TIMEDELTA=$(($ENDTIME - $STARTTIME))
echo " ...done by `date` - it took ${TIMEDELTA} seconds to zip `echo "${WUs2bZipped=}" | wc -l` WUs."