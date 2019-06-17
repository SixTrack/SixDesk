#!/bin/bash

boincServer=boincai11.cern.ch
sixtrackProjPath=/usr/local/boinc/project/sixtrack
spoolDirPath=/afs/cern.ch/work/b/boinc/boinc
spoolDirTestPath=/afs/cern.ch/work/b/boinc/boinctest
where=$PWD
lretrieve=true
lgetOwners=true
lclean=true

# date to treat
if [ -z "$1" ] ; then
    echo "please specify a date in format: YYYY-MM-DD"
    exit
else
    tmpDate=$1
fi

#
echo " starting `basename $0` at `date` ..."

if ${lretrieve} ; then
    echo " retrieving submitted WUs and time intervals from log files on ${boincServer} - date: ${tmpDate}"
    # do not use grep -h: the script still needs the study name (from the submit.*.log file)!
    ssh sixtadm@${boincServer} "cd ${sixtrackProjPath}/log_boincai11 ; grep -e $tmpDate submit*log | grep Submitted | awk '{sub(/:/,\"\ \",\$0); print (\$0)}' | sort -k2 > ${where}/submitAll_${tmpDate}.txt"
    echo " reshuffling retrieve info in a more compact and plottable way in submitAll_${tmpDate}.dat ..."
    # $1 is really the study name (from the submit.*.log file)
    # awk '{if ($1!=lastStudy) {print (tStart,lastLine,Ntot); tStart=$2; Ntot=0;} Ntot=Ntot+1; lastLine=$0; lastStudy=$1;}END{print (tStart,$0,Ntot)}' submitAll_${tmpDate}.txt > submitAll_${tmpDate}.dat
    awk '{if ($1!=lastStudy) {if (NR>1) {print (tStart,lastStudy,tStop,Ntot);} tStart=$2; Ntot=0;} Ntot=Ntot+1; lastStudy=$1; tStop=$2;}END{print (tStart,lastStudy,tStop,Ntot)}' submitAll_${tmpDate}.txt > submitAll_${tmpDate}.dat
    # WUs being assimilated
    echo " retrieving assimilated WUs - date: ${tmpDate}"
    ssh sixtadm@${boincServer} "cd ${sixtrackProjPath}/log_boincai11 ; grep Assimilated sixtrack_assimilator.log | grep $tmpDate > ${where}/assimilateAll_${tmpDate}.dat"
fi

if ${lgetOwners} ; then
    echo " getting owners..." 
    tmpLinesSubmit=`cat submitAll_${tmpDate}.dat`
    Nlines=`echo "${tmpLinesSubmit}" | wc -l`
    
    # get unique studies and owners
    uniqueStudyNames=`echo "${tmpLinesSubmit}" | awk '{sub(/submit./,"",$2); sub(/\.log/,"",$2); print ($2)}' | sort -u`
    uniqueStudyNames=( ${uniqueStudyNames} )
    owners=""
    dirOwners=""
    for uniqueStudyName in ${uniqueStudyNames[@]} ; do
	spoolDir=''
	for tmpDir in ${spoolDirPath} ${spoolDirTestPath} ; do
	    if [ -d ${tmpDir}/${uniqueStudyName} ] ; then
		spoolDir=${tmpDir}/${uniqueStudyName}
		break
	    fi
	done
	if [ "${spoolDir}" == "" ] ; then
	    # the spooldir is not there
	    owner="-"
	    dirOwner="-"
	else
	    dirOwner=`ls -ld ${spoolDir} | awk '{print ($3)}'`
	    ownerFile=${spoolDir}/owner
	    if [ -e ${ownerFile} ] ; then
		owner=`cat ${ownerFile}`
	    else
		owner="-"
	    fi
	fi
	owners="${owners} ${owner}"
	dirOwners="${dirOwners} ${dirOwner}"
    done
    owners=( ${owners} )
    dirOwners=( ${dirOwners} )
    
    # paste everything
    Nlines=`echo "${tmpLinesSubmit}" | wc -l`
    rm -f temp.dat
    for (( ii=1; ii<=${Nlines}; ii++ )) ; do
	tmpLine=`echo "${tmpLinesSubmit}" | head -n ${ii} | tail -1`
	# match study with owner
	tmpStudyName=`echo "${tmpLine}" | awk '{sub(/submit./,"",$2); sub(/\.log/,"",$2); print ($2)}'`
	for (( jj=0; jj<${#uniqueStudyNames[@]}; jj++ )) ; do
	    if [ "${tmpStudyName}" == "${uniqueStudyNames[$jj]}" ] ; then
		echo "${tmpLine} ${tmpStudyName} ${dirOwners[$jj]} ${owners[$jj]}" >> temp.dat
		break
	    fi
	done
    done
    mv temp.dat submitAll_${tmpDate}.dat
fi

if ${lclean} ; then
    rm submitAll_${tmpDate}.txt
fi

#
echo " ...done by `date`."
