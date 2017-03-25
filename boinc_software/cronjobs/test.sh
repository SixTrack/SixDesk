#!/bin/bash

spooldir=/afs/cern.ch/work/b/boinc/boinc

submit_descfile(){ #$1=full path to .desc file
    workdir="${1%/*}"
    descfile="${1#$workdir/}"
    WUname="${descfile%.desc}"
    zipfile="${descfile%.desc}.zip"
    studydir="${workdir%/work}"
    studyname="${studydir#$spooldir/}"
    #
    echo "\$1: $1"
    echo "\${workdir}: ${workdir}"
    echo "\${descfile}: ${descfile}"
    echo "\${WUname}: ${WUname}"
    echo "\${zipfile}: ${zipfile}"
    echo "\${studydir}: ${studydir}"
    echo "\${studyname}: ${studyname}"
}

submit_descfile_new(){ #$1=.desc file
    descfile=`basename $1`
    WUname="${descfile%.desc}"
    zipfile="${descfile%.desc}.zip"
    studyName=`echo "${WUname}" | awk 'BEGIN{FS="__"}{print ($1)}'`
    studydir=$spooldir/$studyName
    workdir=$studydir/work
    #
    echo "\$1: $1"
    echo "\${workdir}: ${workdir}"
    echo "\${descfile}: ${descfile}"
    echo "\${WUname}: ${WUname}"
    echo "\${zipfile}: ${zipfile}"
    echo "\${studydir}: ${studydir}"
    echo "\${studyname}: ${studyname}"
}

test_parse_descFile_fullPath(){
    echo "-- original:"
    submit_descfile /afs/cern.ch/work/b/boinc/boinc/w4_test_hlfast/work/w4_test_hlfast__2__s__62.31_60.32__2_2.5__e3__15_1_sixvf_boinc21.desc
    echo "-- new:"
    submit_descfile_new w4_test_hlfast__2__s__62.31_60.32__2_2.5__e3__15_1_sixvf_boinc21.desc
    echo "-- new (with old input):"
    submit_descfile_new /afs/cern.ch/work/b/boinc/boinc/w4_test_hlfast/work/w4_test_hlfast__2__s__62.31_60.32__2_2.5__e3__15_1_sixvf_boinc21.desc
}

evaluate_string_in_file(){
    # $1: filename
    local __tmpVar=`cat $1`
    echo "${__tmpVar}"
    if ${__tmpVar} ; then
	echo "true"
    else
	echo "false"
    fi
}

test_flag(){
    echo "true" > temp.txt
    evaluate_string_in_file temp.txt
    echo "false" > temp.txt
    evaluate_string_in_file temp.txt
    rm temp.txt
}

test_flag