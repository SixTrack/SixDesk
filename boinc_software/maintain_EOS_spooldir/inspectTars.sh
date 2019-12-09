#!/bin/bash

# please use it as:
#     ./inspectTars.sh 2>&1 | tee -a inspectTars.sh.log

export EOS_MGM_URL=root://eosuser.cern.ch
eospath=/eos/user/s/sixtadm/spooldirs/uploads/boinc
# regexp: no wildcards!!!!!
regexp="workspace1_HEL_Qp_2_MO_0_1t_3s_1e7turns"
regexp="workspace2_lhc2017_c14_o20_N"
nMaxRetrial=10
lFilter=true
lCorrectStructure=true

tmpDir="/tmp/sixtadm/`basename $0`"
[ -d ${tmpDir} ] || mkdir ${tmpDir}

function loopMe(){
    # myCommand should be defined before the call
    local __reply=1
    local __iTrials=0
    while [ ${__reply} -ne 0 ] && [ ${__iTrials} -lt ${nMaxRetrial} ] ; do
        let __iTrials+=1
        log "command: ${myCommand} - run at `date` - trial ${__iTrials}"
        ${myCommand}
        __reply=$?
    done
    if [ ${__reply} -ne 0 ] ; then
        log " ...giving up on command."
    fi
    return ${__reply}
}

function log(){
    echo "$(date -Iseconds) $*"
}

if ${lFilter} ; then
    log "looking for ${regexp} in .tar.gz files in ${eospath} ..."
    totalRemoved=0
    trap "log \"killed \${totalRemoved} WUs in total\"" exit
fi

log "scanning `eos ls -1 "${eospath}/*.tar.gz" | wc -l` .tar.gz files ..."
cd ${tmpDir}

for tmpTarGz in `eos ls -1 "${eospath}/*.tar.gz"` ; do
    log "checking ${eospath}/${tmpTarGz} ..."
    lTreated=false
    tmpTar=${tmpTarGz%.gz}

    log " ...downloading from EOS ..."
    myCommand="xrdcp -f --cksum adler32 ${EOS_MGM_URL}/${eospath}/${tmpTarGz} ."
    loopMe
    oldDim=`ls -ltrh ${tmpTarGz}`

    log " ...gunzipping ..."
    myCommand="gunzip ${tmpTarGz}"
    loopMe
    cp ${tmpTar} orig1.tar
        
    if ${lCorrectStructure} ; then

        log " ...counting number of files contained in ${tmpTar}"
        nFiles=`tar -tvf ${tmpTar} | wc -l`
        log "    ...contains ${nFiles} file(s)"

        if [ ${nFiles} -eq 1 ] ; then
        	log "    ...restoring regular structure:"
        
        	log "       extract .tar.gz from .tar..."
        	myCommand="tar -xvf ${tmpTar}"
        	loopMe
        	rm ${tmpTar}
        
        	log "       extract all .desc and .zip from .tar.gz ..."
        	myCommand="tar -xvzf ${tmpTarGz}"
        	loopMe
        	rm ${tmpTarGz} 
        
        	log "       tar all .desc and .zip into new .tar file..."
        	myCommand="tar -cvf ${tmpTar} *.desc *.zip"
        	loopMe
        	rm -f *.desc *.zip
        
		lTreated=true

        elif [ $((${nFiles} % 2)) -eq 1 ] ; then
        	log "    ...odd number of files: suspect..."
        
        	log "       extract all .desc and .zip from .tar ..."
        	myCommand="tar -xvf ${tmpTar}"
        	loopMe
        	rm ${tmpTar}
        
        	log "       tar all .desc and .zip into new .tar file..."
        	myCommand="tar -cvf ${tmpTar} *.desc *.zip"
        	loopMe
        	rm -f *.desc *.zip

		lTreated=true

        else
        	log "    ...everything is fine."
        fi
    fi

    cp ${tmpTar} orig2.tar

    if ${lFilter} ; then
        log " ...finding instances of ${regexp} in ${tmpTar}"
	WUs=`tar -tvf ${tmpTar} | grep ${regexp}`
	if [ -n "${WUs}" ] ; then
    	    nInstances=`echo "${WUs}" | wc -l | awk '{print ($1/2)}'`
    	    log "...found ${nInstances} instances of searched regexp"
    	    log "...removing files:"
    	    myCommand="tar -vf ${tmpTar} --delete "'*'"${regexp}"'*'
	    loopMe

    	    let totalRemoved=${totalRemoved}+${nInstances}
    	    log "...removed:"
    	    echo "${WUs}" | grep .desc

	    lTreated=true
	fi
    fi

    log "    ...gzipping..."
    myCommand="gzip ${tmpTar}"
    loopMe

    log "    ...new dimension:"
    log `ls -ltrh ${tmpTarGz}`
    log "    ...old dimension:"
    log "${oldDim}"

    log "    ...quick checks"
    log "       tar -tvzf ${tmpTarGz} | wc -l : `tar -tvzf ${tmpTarGz} | wc -l`"
    log "       tar -tvzf ${tmpTarGz} | grep ${regexp} | wc -l : `tar -tvzf ${tmpTarGz} | grep ${regexp} | wc -l`"
    log "       tar -tvzf orig2.tar | wc -l : `tar -tvf orig2.tar | wc -l`"
    log "       tar -tvzf orig2.tar | grep ${regexp} | wc -l : `tar -tvf orig2.tar | grep ${regexp} | wc -l`"

    log "    ...copying ${tmpTarGz} back to EOS..."
    myCommand="xrdcp -f --cksum adler32 ${tmpTarGz} ${EOS_MGM_URL}/${eospath}/"
    log "${myCommand}"

    ans='p'
    while [ ${ans} != "y" ] && [ ${ans} != "n" ] ; do
	log " shall I proceed with copying back to / cleaning away file from EOS? [y/n]"
	read ans
    done

    if [ ${ans} == "y" ] ; then
	log " proceed"
	if [ `tar -tvzf ${tmpTarGz} | wc -l` -eq 0 ] ; then
	    log " no need of copying back to EOS but removing original file"
	    myCommand="eos rm ${eospath}/${tmpTarGz}"
	    loopMe
	else
	    # xrdcp
	    loopMe
	fi
    else
	log " going on with next .tar.gz"
    fi
    log " cleaning tmp ${tmpDir} "
    rm orig?.tar ${tmpTarGz}

done

cd - 2>&1 . /dev/null
log ...ended by `date`

