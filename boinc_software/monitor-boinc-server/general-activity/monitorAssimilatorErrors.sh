#!/bin/bash

assimilatorErrorFile='errors'
assimilatorErrorFilePath='/data/boinc/project/sixtrack/sample_results'
currentLog='assimilator.log'
# NB:
# - spooldir deleted by user: "POS=2 : 2" -> "POS=5 : 2";
# - full AFS dir: "POS=5 : 27"; (NB: POS=3 should never be seen...)
knownErrors=(
    "POS=1"
    "POS=2"
    "POS=3"
    "POS=5"
    "POS=7"
    "POS=8"
)
labelErrors=(
    "assimilator_var_name_too_short"
    "non_existing_spool_dir"
    "AFS_file_too_large_beginning"
    "AFS_file_too_large_dispatching"
    "no_canonical_result"
    "error_with_trashbin"
)

# time stamp
rightNow=`date +"%F %T"`
currDay=`echo "${rightNow}" | awk '{print ($1)}'`
currTim=`echo "${rightNow}" | awk '{print ($2)}'`

#
echo ""
echo "new query at: ${rightNow}"

# make a temp copy, to work on a file which does not get updated in the meanwhile
# updates will be caught in the next round
echo "copying ${assimilatorErrorFilePath}/${assimilatorErrorFile} ..."
cp ${assimilatorErrorFilePath}/${assimilatorErrorFile} .

# getting updates
echo "getting updates..."
nLinesOld=`grep '...current length of file:' ${currentLog} | tail -1 | awk '{print ($NF)}'`
nLines=`wc -l ${assimilatorErrorFile} | awk '{print ($1)}'`
echo "...current length of file: ${nLines}"
let nTail=${nLines}-${nLinesOld}
newLines=`tail -n ${nTail} ${assimilatorErrorFile}`
# statistics about error codes
newLinesStat=`echo "${newLines}" | awk '{print ($1)}' | sort | uniq -c`
echo "statistics on errors:"
echo "${newLinesStat}"
# new errors:
currErrorCodes=`echo "${newLinesStat}" | awk '{print ($2)}'`
currErrorCodes=( ${currErrorCodes} )
for currErrorCode in ${currErrorCodes[@]} ; do
    lfound=false
    for knownError in ${knownErrors[@]} ; do
	if [ "${currErrorCode}" == "${knownError}" ] ; then
	    lfound=true
	    break
	fi
    done
    if ! ${lfound} ; then
	echo "unknown error code: ${currErrorCode}"
    fi
done
echo "analysing known errors..."
# -
echo "...spooldir deleted by user: POS=2 : 2 -> POS=5 : 2;"
# . all lines:
allWUs=`echo "${newLines}" | grep 'POS=5 : 2 ' | awk '{print ($NF)}' | awk 'BEGIN{FS="/";}{print ($NF)}'`
# . workspaces:
echo "   ...workspaces:"
echo "${allWUs}" | awk 'BEGIN{FS="__"}{print ($1)}' | sort | uniq -c
# . WUs:
echo "   ...WUs:"
echo "${allWUs}"
echo ""
# -
echo "...full AFS dir: POS=5 : 27;"
# . all lines:
allWUs=`echo "${newLines}" | grep 'POS=5 : 27' | awk '{print ($NF)}' | awk 'BEGIN{FS="/";}{print ($NF)}'`
# . workspaces:
echo "   ...workspaces:"
echo "${allWUs}" | awk 'BEGIN{FS="__"}{print ($1)}' | sort | uniq -c
# . WUs:
echo "   ...WUs:"
echo "${allWUs}"
echo ""

# clean
echo "cleaning..."
rm ${assimilatorErrorFile}

# done
echo "...done."
