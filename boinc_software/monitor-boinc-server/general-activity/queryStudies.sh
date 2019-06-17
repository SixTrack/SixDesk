#!/bin/bash

lQuery=true
lPython=true

oFile=all_WUs.txt
passWd=`cat ~/private/.mySQLcred`

now=`date '+%F %T'`

echo ""
echo "starting at ${now} ..."

if ${lQuery} ; then
    echo "   querying the database ..."
    echo "now: ${now}"> ${oFile}
    mysql -h dbod-sixtrack.cern.ch -u sixtadm --password="${passWd}" -P 5513 -Dsixt_production -e"select name,assimilate_state from workunit where appid=1 or appid=10;"  >> ${oFile}
    echo "   ...done."
fi

if ${lPython} ; then
    echo "   parsing results..."
    python parseStudyStates.py
    if [ $? -eq 0 ] ; then
	rm all_WUs.txt
    fi
    echo "   ...done."
fi

echo "...done."
