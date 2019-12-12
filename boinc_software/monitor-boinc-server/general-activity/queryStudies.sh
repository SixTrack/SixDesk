#!/bin/bash

lQuery=true
lPython=true
lTrafficLight=true

oFileBOINCdb=all_WUs.txt
oFileTrafficLight=all_trafficLight.txt
oStudyFile=studies.txt
eosSpoolDirs=(
    /eos/user/s/sixtadm/spooldirs/uploads/boinc
)

now=`date '+%F %T'`

echo ""
echo "starting at ${now} ..."

if ${lQuery} ; then
    echo "   querying the database ..."
    echo "now: ${now}"> ${oFileBOINCdb}
    mysql -h dbod-sixtrack.cern.ch -u sixtadm -P 5513 -Dsixt_production -e"select name,assimilate_state from workunit where appid=1 or appid=10;"  >> ${oFileBOINCdb}
    echo "   ...done."
fi

if ${lPython} ; then
    echo "   parsing results..."
    python parseStudyStates.py ${oFileBOINCdb} ${oStudyFile}
    [ $? -ne 0 ] || rm ${oFileBOINCdb}
    echo "   ...done."
fi

if ${lTrafficLight} ; then
    echo "looking at WUs behind traffic light..."
    for eosSpoolDir in ${eosSpoolDirs[@]} ; do
	echo "...spooldir ${eosSpoolDir} ..."
    	for tmpFile in `ls -1 ${eosSpoolDir}/*.tar.gz` ; do
	    echo "   ...archive `basename ${tmpFile}` ..."
    	    tar -tvzf ${tmpFile} "*.zip" | awk '{print ($6)}' | awk 'BEGIN{FS="__"}{print ($1)}' | sort | uniq -c >> ${oFileTrafficLight}
    	done
    done
    echo "...summarising..."
    echo "" >> ${oStudyFile}
    echo "" >> ${oStudyFile}
    echo "# status of traffic light" >> ${oStudyFile}
    printf "# %-68s %18s\n" "study name" "tot WUs" >> ${oStudyFile}
    cat ${oFileTrafficLight} | sort -k2 | awk '{if ($2!=CurrName) {if (NR>1) { printf("%-70s %18i TL\n",CurrName,tot) }; CurrName=$2; tot=0}; tot+=$1}END{if (NR>1) { printf("%-70s %18i TL\n",CurrName,tot)}}' >> ${oStudyFile}
    echo "...cleaning..."
    rm ${oFileTrafficLight}
    echo "...traffic light done."
fi

now=`date '+%F %T'`
echo "...done by ${now}."
