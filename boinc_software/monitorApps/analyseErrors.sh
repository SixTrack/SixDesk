#!/bin/bash

# A.Mereghetti, 2017-09-13
# dirty script for analysing error results

appID=10
oFileName=results_`date +"%Y-%m-%d_%H-%M-%S"`.txt
oFileName=results_2017-09-13_09-14-53.txt
lretrieve=false
lanalyse=true
scanErrors=( '-186' '-185' '11' )
scanErrorLabels=( 'ERR_RESULT_DOWNLOAD' 'ERR_RESULT_START' 'Unknown error code' )
appVerIDs=( 451 454 443 453 447 456 442 )
appVerIDLabels=( 'x86_64-apple-darwin,avx' 'x86_64-apple-darwin' 'aarch64-android-linux' 'aarch64-unknown-linux' 'x86_64-pc-freebsd' 'arm-unknown-linux-gnueabihf' 'i686-pc-linux-gnu' )

# retrieve data
if ${lretrieve} ; then
    echo " retrieving data for appID ${appID} ..."
    mysql -h dbod-sixtrack.cern.ch -P 5513 -u admin -p -Dsixt_production -e"select id,workunitid,name,exit_status,create_time,sent_time,received_time,hostid,app_version_id from result where appid =${appID} and outcome=3 order by workunitid;" > oFileName
fi

# analysis
if ${lanalyse} ; then
    #
    echo ""
    echo "=== general overview ==="
    echo "# counts, errorID"
    grep -v 'exit_status' ${oFileName} | awk '{print ($4)}'  | sort -g | uniq -c
    #
    for (( ii=0; ii<${#scanErrors[@]}; ii++ )); do
	echo ""
	echo "=== overview on errorID ${scanErrors[$ii]} (${scanErrorLabels[$ii]}) by hostID, appID ==="
	echo "# counts, hostID, appID"
	grep -v 'exit_status' ${oFileName} | awk -v "errorID=${scanErrors[$ii]}" '{if ($4==errorID) print ($8,$9)}' | sort -g | uniq -c
    done
    # 
    for (( ii=0; ii<${#appVerIDs[@]}; ii++ )); do
	echo ""
	echo "=== overview on appVerID ${appVerIDs[$ii]} (${appVerIDLabels[$ii]}) by hostID ==="
	echo "# counts, hostID, appID"
	grep -v 'exit_status' ${oFileName} | awk -v "appVerID=${appVerIDs[$ii]}" '{if ($9==appVerID) print ($8)}' | sort -g | uniq -c
    done
fi
