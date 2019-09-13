#!/bin/bash

# A.Mereghetti, 2019-09-10
# script for spooling tasks from AFS work.boinc volume to
#   sixtadm EOS space

toolsDir=`dirname $0`
tmpDirBase=/tmp/sixtadm/`basename $0`
host=$(hostname -s)

spooldirs=( /afs/cern.ch/work/b/boinc/boinc )

LOGFILE="$toolsDir/$(basename $0).log"
lockfile="$toolsDir/$(basename $0).lock"

export EOS_MGM_URL=root://eosuser.cern.ch 
eosSpoolDirsPath=/eos/user/s/sixtadm/spooldirs

nMaxRetrial=10

function log(){ # log_message
    echo "$(date -Iseconds) $*" >>"$LOGFILE"
}   

function getlock(){
    if  ln -s PID:$$ $lockfile >/dev/null 2>&1 ; then
	trap "log \" cleaning ${tmpDirBase} away...\" ; rm -rf ${tmpDirBase} ; rm $lockfile; log \" Relase lock $lockfile\"" EXIT
 	log "got lock $lockfile"
    else 
	log "$lockfile already exists. $0 already running? Abort..."
	#never get here
	exit 1
    fi
}

run_spool(){ # max_jobs_to_submit, max_jobs_perStudy, max_jobs_perTar, specific_study

    local max_jobs="$1"	
    local lMaxJobs=false
    [ -z "${max_jobs}" -o "${max_jobs}" = "0" ] || lMaxJobs=true

    local max_jobs_perStudy="$2"	
    local lMaxJobsPerStudy=false
    [ -z "${max_jobs_perStudy}" -o "${max_jobs_perStudy}" = "0" ] || lMaxJobsPerStudy=true

    local max_jobs_perTar="$3"	
    local lMaxJobsPerTar=false
    [ -z "${max_jobs_perTar}" -o "${max_jobs_perTar}" = "0" ] || lMaxJobsPerTar=true

    if [ -z "$4" ] ; then
        #find the work dirs 2 levels down
	# take into account arrival time
	local allWorkDirs=`find "$spooldir" -maxdepth 2 -type d -name "work" -printf "%T+\t%p\n" | sort | awk '{print ($2)}'`
    else
	#target a specific study
	local allWorkDirs=$spooldir/$4/work
    fi

    # main loop
    local __starttime=$(date +%s)
    local __nCompleted=0
    for workdir in ${allWorkDirs} ; do
        local __nCompletedStudy=0
	#check for desc files in the current work dir, and subfolders
	# take into account arrival time
	if ${lMaxJobsPerStudy} ; then
	    local allDescs=`find "$workdir" -maxdepth 2 -mmin +5 -type f -name '*.desc' -printf "%T+\t%p\n" | sort | awk '{print ($2)}' | head -n ${max_jobs_perStudy}`
	else
	    local allDescs=`find "$workdir" -maxdepth 2 -mmin +5 -type f -name '*.desc' -printf "%T+\t%p\n" | sort | awk '{print ($2)}'`
	fi
	for descfile in ${allDescs} ; do
	    #process the desc files
	    cp ${descfile} ${descfile%.desc}.zip ${taringDir}
	    if [ $? -eq 0 ] ; then
		__nCompletedStudy=$(( ${__nCompletedStudy} + 1 ))
		__nCompleted=$(( ${__nCompleted} + 1 ))
		log "Submitted `basename ${descfile%.desc}`"
		rm ${descfile} ${descfile%.desc}.zip
		# proceed with tar in case max reached
		if ${lMaxJobsPerTar} ; then
		    if [ $((${__nCompleted}%${max_jobs_perTar})) -eq 0 ] && [ ${__nCompleted} -ne 0 ] ; then
                        log "reached ${max_jobs_perTar} - proceed with tar file"
			makeTar
		    fi
		fi
		# stop after max_jobs (0=unlimited)
		if ${lMaxJobs} ; then
		    if [ ${__nCompleted} -ge ${max_jobs} ] ; then
                        log "reached ${max_jobs} in total"
			break 2
		    fi
		fi
	    else
		log "Problem submitting ${descfile%.desc}"
	    fi
	done
	if [ -n "${allDescs}" ] ; then
	    if ${lMaxJobsPerStudy} ; then
                if [ ${__nCompletedStudy} -eq ${max_jobs_perStudy} ] ; then
		    log "limit of ${max_jobs_perStudy} reached for ${workdir}"
	        fi
            fi
	fi
    done

    makeTar

    local __endtime=$(date +%s)
    local __timedelta=$((${__endtime} - ${__starttime}))
    log "it took ${__timedelta} seconds for ${__nCompleted} WUs."

}

makeTar(){

    local __origDir=$PWD
    cd ${taringDir}

    if [ `ls -1 *.zip 2> /dev/null | wc -l` -ne 0 ] ; then
	tarName=`basename ${spooldir}`_`date "+%Y-%m-%d_%H-%M-%S".tar`
	log "new tar name: ${tarName}"

	myCommand="tar -cvf ../${tarName} ."
	log "${myCommand}"
	${myCommand}
    else
	log "no .zip files"
    fi

    for tarFile in `ls -1 ../*.tar 2> /dev/null` ; do
	myCommand="gzip ${tarFile}"
	log "${myCommand}"
	${myCommand}
    done

    for gzFile in `ls -1 ../*.gz 2> /dev/null` ; do
	# xrdcp tar
	myCommand="xrdcp -f --cksum adler32 ${gzFile} ${EOS_MGM_URL}/${pathInEos}/"
	loopMe
	if [ $? -ne 0 ] ; then
	    log "unable to upload to EOS at ${EOS_MGM_URL}/${pathInEos} - moving it to ${spooldirUpload}"
	    mv ${gzFile} ${spooldirUpload}
	fi
    done

    rm -f * ../*.gz
    cd ${__origDir}
}

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

printhelp(){
cat <<EOF
Usage: $(basename $0) [options]

        Where options are:
        -d string       - limit processing to the specified study only
        -h              - print usage and exit
        -m number       - set max no of jobs per study in the current run
        -n number       - set max no of jobs in the current run
        -N number       - set max no of jobs per tar in the current run
	-k		- Keep .desc.done and .zip contents

EOF
}

# ==============================================================================
# start
# ==============================================================================

maxjobs=0 # =0: no limits
maxjobs_perStudy=1000
maxjobs_perTar=10000
studyName=""

while getopts ":hd:m:n:N:"  OPT
do
  #Debug
  #echo "OPT is $OPT. OPTIND is $OPTIND. OPTARG is $OPTARG."
case "$OPT" in
h) printhelp ; exit 0 ;;
m) maxjobs_perStudy="$OPTARG" ;;
n) maxjobs="$OPTARG" ;;
N) maxjobs_perTar="$OPTARG" ;;
d) studyName="$OPTARG" ;;
:|?) log 'Invalid Argument(s)' ; printhelp; exit 0 ;;
esac
done

log ""
log "starting `basename $0` at `date` on host ${host} ..."

# adding lock mechanism
getlock

# ==============================================================================
# processing
# ==============================================================================

for spooldir in ${spooldirs[@]} ; do
    pathInEos=${eosSpoolDirsPath}/uploads/`basename ${spooldir}`
    spooldirUpload=$spooldir/upload

    taringDir=${tmpDirBase}/taring/`basename ${spooldir}`
    if ! [ -d ${taringDir} ] ; then
	mkdir -p ${taringDir}
	if [ $? -ne 0 ] ; then
	    log "problems in creating ${taringDir} - cannot proceed"
	    exit 1
	fi
    fi

    # finalise a potential previous round ended early
    log "finalise a potential previous round ended early"
    makeTar

    log run_spool $maxjobs $maxjobs_perStudy $maxjobs_perTar $studyName
    run_spool $maxjobs $maxjobs_perStudy $maxjobs_perTar $studyName
done

# ==============================================================================
# close processing
# ==============================================================================

# done
log "...done by `date`"
