#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [action] [option]
   to manage the submission of sixtrack jobs

   actions (mandatory, one of the following):
   -g      generate simulation files 
           NB: this includes also preliminary SixTrack jobs for computing
               chromas and beta functions
   -s      actually submit
   -c      check that all the input files have been created and job is ready
               for submission on the required platform
           NB: this is done by default after preparation and before submission,
               but this action can be triggered on its own
   -a      equivalent to -g -c -s
   -f      fix compromised directory structure
           similar to -g, but it fixes folders which miss any of the input files
              (i.e. the fort.*.gz) - BOINC .zip/.desc files are not re-generated;
   -C      clean .zip/.desc after submission in boinc
           NB: this is done by default in case of submission to boinc
   -t      report the current status of simulations
           for the time being, it reports the number of input and output files
   -i      submit only incomplete cases. The platform of submission is forced to ${sixdeskplatformDefIncomplete}
           NB: no check at all of concerned directories / inputs is performed
   -U      unlock dirs necessary to the script to run
           PAY ATTENTION when using this option, as no check whether the lock
              belongs to this script or not is performed, and you may screw up
              processing of another script
   -w      before doing any operation, submit any HTCondor cluster of jobs left
              from a previous (failing attempt).
           The platform of submission is forced to ${sixdeskplatformDefIncomplete}

   options (optional)
   -S      selected points of scan only
           in case of preparation of files, regenerate only those directories
              with an incomplete set of input files, unless a fort.10.gz of non-zero
              length or the JOB_NOT_YET_COMPLETED file are there;
           in case of check, check the correct input is generated only in those
              directories that will be submitted (see previous point)
           in case of submission, submit those directories requiring actual submission
              (see previous point)
           NB: 
           - this option is NOT active in case of -c only!
           - this option is NOT compatible with -i action!
   -R      restart action from a specific point in scan (point is not treated again):
           - e.g. -R lhc_coll%1%s%65_64%3_4%5%37.5, for starting from the specified
             point;
           - -R last, for starting from the last point present in taskids;
           NB: when used with -S option, it is your responsibility to make sure that
               there are no points in the scan that should be submitted but they are
               actually skipped as they come 'after' the job you provided
   -M      MegaZip: in case of boinc, WUs all zipped in one file.
              (.zip/.desc files of each WU will be put in a big .zip)
           this option shall be used with both -g and -s actions, and in case
              of explicitely requiring -c
   -B      break backward-compatibility
           for the moment, this sticks only to expressions affecting ratio of
              emittances, amplitude scans and job names in fort.3
   -P      python path
   -v      verbose (OFF by default)
   -d      study name (when running many jobs in parallel)
   -p      platform name (when running many jobs in parallel)
   -n      renew kerberos token every n jobs (default: ${NrenewKerberosDef})
   -N      an HTCondor cluster of jobs should be composed of at most
              N jobs (active only in case of HTCondor - default: ${nMaxJobsSubmitHTCondorDef}).
           this option can be used also for submitting incomplete_cases
   -o      define output (preferred over the definition of sixdesklevel in sixdeskenv)
               0: only error messages and basic output 
               1: full output
               2: extended output for debugging

EOF
}

function preliminaryChecksRS(){
    local __lerr=0
    
    # - check run requests (to be moved to set_env)
    let tmpTot=$da+$short+$long
    if [ $tmpTot -gt 1 ] ; then
	sixdeskmess -1 "Please select only one among short/long/da run"
	let __lerr+=1
    fi

    # - check definition of amplitude range
    if [ $short -eq 1 ] ; then
	if [ -z "${ns1s}" ] || [ -z "${ns2s}" ] ; then
	    sixdeskmess -1 "Please check ns1s/ns2s..."
	    let __lerr+=1
	fi
    elif [ $long -eq 1 ] ; then
	if [ -z "${ns1l}" ] || [ -z "${ns2l}" ] ; then
	    sixdeskmess -1 "Please check ns1l/ns2l..."
	    let __lerr+=1
	fi
    elif [ $da -eq 1 ] ; then
	if [ -z "${dimda}" ] ; then
	    sixdeskmess -1 "Please check dimda..."
	    let __lerr+=1
	fi
    fi

    # - check platforms (to be moved to set_env)
    if [ $short -eq 1 ] ; then
	if [ "$sixdeskplatform" != "lsf" ] ; then
	    sixdeskmess -1 "Only LSF platform for short runs!"
	    let __lerr+=1
	fi
    fi

    return $__lerr
}


function check_output_option(){
    local __selected_output_valid
    __selected_output_valid=false
    
    case ${OPTARG} in
    ''|*[!0-2]*) __selected_output_valid=false ;;
    *)           __selected_output_valid=true  ;;
    esac

    if ! ${__selected_output_valid}; then
	echo "ERROR: Option -o requires the following arguments:"
	echo "    0: only error messages and basic output [default]"
	echo "    1: full output"
	echo "    2: extended output for debugging"
	exit 1
    else
	loutform=true
	sixdesklevel_option=${OPTARG}
    fi
    
}


function preProcessFort3(){
    local __POST=POST
    local __DIFF=DIFF
    local __lerr=0

    # --------------------------------------------------------------------------
    # build fort.3 for momentum scan
    # - first part
    sed -e 's/%turnss/'1'/g' \
	-e 's/%nss/'1'/g' \
	-e 's/%ax0s/'0.'/g' \
	-e 's/%ax1s/'0.'/g' \
	-e 's/%imc/'31'/g' \
	-e 's/%iclo6/'0'/g' \
	-e 's/%writebins/'1'/g' \
	-e 's/%ratios/'0.'/g' \
	-e 's/%dp1/'$dpmax'/g' \
	-e 's/%dp2/'$dpmax'/g' \
	-e 's/%e0/'$e0'/g' \
	-e 's/%ition/'0'/g' \
	-e 's/%idfor/'$idfor'/g' \
	-e 's/%ibtype/'$ibtype'/g' \
	-e 's/%bunch_charge/'$bunch_charge'/g' \
	-e 's?%Runnam?%Runnam '"$sixdeskTitle"'?g' \
        $sixdeskjobs_logs/fort.3.mother1 > $sixdeskjobs_logs/fort0.3.mask
    let __lerr+=$?
    # - multipole blocks
    cat $sixdeskjobs_logs/fort.3.mad >> $sixdeskjobs_logs/fort0.3.mask 
    let __lerr+=$?
    # - second  part
    if [ $reson -eq 1 ] ; then
	local __Qx=`awk '{print $1}' resonance`
	local __Qy=`awk '{print $2}' resonance`
	local __Ax=`awk '{print $3}' resonance`
	local __Ay=`awk '{print $4}' resonance`
	local __N1=`awk '{print $5}' resonance`
	local __N2=`awk '{print $6}' resonance`
	sed -e 's/%SUB/''/g' \
	    -e 's/%Qx/'$__Qx'/g' \
	    -e 's/%Qy/'$__Qy'/g' \
	    -e 's/%Ax/'$__Ax'/g' \
	    -e 's/%Ay/'$__Ay'/g' \
	    -e 's/%chromx/'$chromx'/g' \
	    -e 's/%chromy/'$chromy'/g' \
	    -e 's/%N1/'$__N1'/g' \
	    -e 's/%N2/'$__N2'/g' -i $sixdeskjobs_logs/fort.3.mother2
    else
	sed -i -e 's/%SUB/\//g' $sixdeskjobs_logs/fort.3.mother2
    fi  
    let __lerr+=$?
    local __ndafi="$__imc"
    sed -e 's?%CHRO?'$CHROVAL'?g' \
	-e 's?%TUNE?'$TUNEVAL'?g' \
	-e 's/%POST/'$__POST'/g' \
	-e 's/%POS1/''/g' \
	-e 's/%ndafi/'$__ndafi'/g' \
	-e 's/%chromx/'$chromx'/g' \
	-e 's/%chromy/'$chromy'/g' \
	-e 's/%DIFF/\/'$__DIFF'/g' \
	-e 's/%DIF1/\//g' $sixdeskjobs_logs/fort.3.mother2 >> $sixdeskjobs_logs/fort0.3.mask 
    let __lerr+=$?
    sixdeskmess  1 "Maximum relative energy deviation for momentum scan $dpmax"

    # --------------------------------------------------------------------------
    # build fort.3 for detuning run
    # - first part
    if [ $dimen -eq 6 ] ; then
	local __imc=1
	local __iclo6=2
	local __ition=1
	local __dp1=$dpini
	local __dp2=$dpini
    else
	local __imc=1
	local __iclo6=0
	local __ition=0
	local __dp1=.000
	local __dp2=.000
    fi
    sed -e 's/%imc/'$__imc'/g' \
	-e 's/%iclo6/'$__iclo6'/g' \
	-e 's/%dp1/'$__dp1'/g' \
	-e 's/%dp2/'$__dp2'/g' \
	-e 's/%e0/'$e0'/g' \
	-e 's/%ition/'$__ition'/g' \
	-e 's/%idfor/'$__idfor'/g' \
	-e 's/%ibtype/'$ibtype'/g' \
	-e 's/%bunch_charge/'$bunch_charge'/g' \
	-e 's?%Runnam?%Runnam '"$sixdeskTitle"'?g' \
        $sixdeskjobs_logs/fort.3.mother1 > $sixdeskjobs_logs/forts.3.mask
    let __lerr+=$?
    # - multipole blocks
    cat $sixdeskjobs_logs/fort.3.mad >> $sixdeskjobs_logs/forts.3.mask 
    let __lerr+=$?
    # - second  part
    sed -e 's?%CHRO?'$CHROVAL'?g' \
	-e 's?%TUNE?'$TUNEVAL'?g' \
	-e 's/%POST/'$__POST'/g' \
	-e 's/%POS1/''/g' \
	-e 's/%ndafi/%nss/g' \
	-e 's/%chromx/'$chromx'/g' \
	-e 's/%chromy/'$chromy'/g' \
	-e 's/%DIFF/\/'$__DIFF'/g' \
	-e 's/%DIF1/\//g' $sixdeskjobs_logs/fort.3.mother2 >> $sixdeskjobs_logs/forts.3.mask
    let __lerr+=$?
    
    # --------------------------------------------------------------------------
    # build fort.3 for long term run
    # - first part
    local __imc=1
    if [ $dimen -eq 6 ] ; then
	local __iclo6=2
	local __ition=1
	local __dp1=$dpini
	local __dp2=$dpini
    else
	local __iclo6=0
	local __ition=0
	local __dp1=.0
	local __dp2=.0
    fi
    sed -e 's/%turnss/%turnsl/g' \
	-e 's/%nss/'$sixdeskpairs'/g' \
	-e 's/%imc/'$__imc'/g' \
	-e 's/%iclo6/'$__iclo6'/g' \
	-e 's/%ax0s/%ax0l/g' \
	-e 's/%ax1s/%ax1l/g' \
	-e 's/%writebins/%writebinl/g' \
	-e 's/%ratios/%ratiol/g' \
	-e 's/%dp1/'$__dp1'/g' \
	-e 's/%dp2/'$__dp2'/g' \
	-e 's/%e0/'$e0'/g' \
	-e 's/%ition/'$__ition'/g' \
	-e 's/%idfor/'$idfor'/g' \
	-e 's/%ibtype/'$ibtype'/g' \
	-e 's/%bunch_charge/'$bunch_charge'/g' \
	-e 's?%Runnam?%Runnam '"$sixdeskTitle"'?g' \
        $sixdeskjobs_logs/fort.3.mother1 > $sixdeskjobs_logs/fortl.3.mask
    let __lerr+=$?
    # - multipole blocks
    cat $sixdeskjobs_logs/fort.3.mad >> $sixdeskjobs_logs/fortl.3.mask 
    let __lerr+=$?
    # - second  part
    sed -e 's?%CHRO?'$CHROVAL'?g' \
	-e 's?%TUNE?'$TUNEVAL'?g' \
	-e 's/%POST/'$__POST'/g' \
	-e 's/%POS1/''/g' \
	-e 's/%ndafi/'$sixdeskpairs'/g' \
	-e 's/%chromx/'$chromx'/g' \
	-e 's/%chromy/'$chromy'/g' \
	-e 's/%DIFF/\/'$__DIFF'/g' \
	-e 's/%DIF1/\//g' $sixdeskjobs_logs/fort.3.mother2 >> $sixdeskjobs_logs/fortl.3.mask 
    let __lerr+=$?
    sixdeskmess  1 "Initial relative energy deviation $dpini"

    # --------------------------------------------------------------------------
    # build fort.3 for DA run
    # - first part
    if [ $dimda -eq 6 ] ; then
	local __iclo6=2
	local __ition=1
	local __nsix=0
    else
	local __iclo6=0
	local __ition=0
	local __nsix=0
    fi
    sed -e 's/%turnss/'1'/g' \
	-e 's/%nss/'1'/g' \
	-e 's/%ax0s/'0.'/g' \
	-e 's/%ax1s/'0.'/g' \
	-e 's/%imc/'1'/g' \
	-e 's/%iclo6/'$__iclo6'/g' \
	-e 's/%writebins/'0'/g' \
	-e 's/%ratios/'0.'/g' \
	-e 's/%dp1/'.000'/g' \
	-e 's/%dp2/'.000'/g' \
	-e 's/%e0/'$e0'/g' \
	-e 's/%ition/'$__ition'/g' \
	-e 's/%idfor/'$idfor'/g' \
	-e 's/%ibtype/'$ibtype'/g' \
	-e 's/%bunch_charge/'$bunch_charge'/g' \
	-e 's?%Runnam?%Runnam '"$sixdeskTitle"'?g' \
        $sixdeskjobs_logs/fort.3.mother1 > $sixdeskjobs_logs/fortda.3.mask
    let __lerr+=$?
    # - multipole blocks
    cat $sixdeskjobs_logs/fort.3.mad >> $sixdeskjobs_logs/fortda.3.mask 
    let __lerr+=$?
    # - second  part
    sed -e 's?%CHRO?'$CHROVAL'?g' \
	-e 's?%TUNE?'$TUNEVAL'?g' \
	-e 's/%POST/\/'$__POST'/g' \
	-e 's/%POS1/\//g' \
	-e 's/%DIFF/'$__DIFF'/g' \
	-e 's/%chromx/'$chromx'/g' \
	-e 's/%chromy/'$chromy'/g' \
	-e 's/%nsix/'$__nsix'/g' \
	-e 's/%DIF1//g' $sixdeskjobs_logs/fort.3.mother2 >> $sixdeskjobs_logs/fortda.3.mask 
    let __lerr+=$?
    return $__lerr
}

function preProcessShort(){
    local __lerr=0
    if [ $sussix -eq 1 ] ; then
	local __IANA=1
	local __LR=1
	local __MR=0
	local __KR=0
	local __dimline=1
	sed -e 's/%nss/'$nss'/g' \
            -e 's/%IANA/'$__IANA'/g' \
            -e 's/%turnss/'$turnss'/g' \
            -e 's/%dimsus/'$dimsus'/g' \
            -e 's/%LR/'$__LR'/g' \
            -e 's/%MR/'$__MR'/g' \
            -e 's/%KR/'$__KR'/g' \
            -e 's/%dimline/'$__dimline'/g' ${SCRIPTDIR}/templates/sussix/sussix.inp > \
            $sixdeskjobs_logs/sussix.tmp.1
	let __lerr+=$?
	local __IANA=0
	local __LR=0
	local __MR=1
	local __dimline=2
	sed -e 's/%nss/'$nss'/g' \
            -e 's/%IANA/'$__IANA'/g' \
            -e 's/%turnss/'$turnss'/g' \
            -e 's/%dimsus/'$dimsus'/g' \
            -e 's/%LR/'$__LR'/g' \
            -e 's/%MR/'$__MR'/g' \
            -e 's/%KR/'$__KR'/g' \
            -e 's/%dimline/'$__dimline'/g' ${SCRIPTDIR}/templates/sussix/sussix.inp > \
            $sixdeskjobs_logs/sussix.tmp.2
	let __lerr+=$?
	local __MR=0
	local __KR=1
	local __dimline=3
	sed -e 's/%nss/'$nss'/g' \
            -e 's/%IANA/'$__IANA'/g' \
            -e 's/%turnss/'$turnss'/g' \
            -e 's/%dimsus/'$dimsus'/g' \
            -e 's/%LR/'$__LR'/g' \
            -e 's/%MR/'$__MR'/g' \
            -e 's/%KR/'$__KR'/g' \
            -e 's/%dimline/'$__dimline'/g' ${SCRIPTDIR}/templates/sussix/sussix.inp > \
            $sixdeskjobs_logs/sussix.tmp.3
	let __lerr+=$?
	sed -e 's/%suss//g' \
	    ${SCRIPTDIR}/templates/lsf/${lsfjobtype}.sh > $sixdeskjobs_logs/${lsfjobtype}.sh
    else
	sed -e 's/%suss/'#'/g' \
            ${SCRIPTDIR}/templates/lsf/${lsfjobtype}.sh > $sixdeskjobs_logs/${lsfjobtype}.sh
    fi
    let __lerr+=$?
    sed -i -e 's?SIXTRACKEXE?'$SIXTRACKEXE'?g' \
           -e 's?SIXDESKHOME?'$sixdeskhome'?g' $sixdeskjobs_logs/${lsfjobtype}.sh
    let __lerr+=$?
    chmod 755 $sixdeskjobs_logs/${lsfjobtype}.sh
    let __lerr+=$?
    sed -e 's/%suss/'#'/g' \
        -e 's?SIXTRACKEXE?'$SIXTRACKEXE'?g' \
	-e 's?SIXDESKHOME?'$sixdeskhome'?g' \
        ${SCRIPTDIR}/templates/lsf/${lsfjobtype}.sh > $sixdeskjobs_logs/${lsfjobtype}0.sh
    let __lerr+=$?
    chmod 755 $sixdeskjobs_logs/${lsfjobtype}0.sh
    let __lerr+=$?
    return $__lerr
}

function preProcessDA(){
    local __lerr=0
    if [ $dimda -eq 6 ] ; then
	cp $sixdeskhome/inc/dalie6.data $sixdeskjobs_logs/dalie.data
	let __lerr+=$?
	sed -e 's/%NO/'$NO1'/g' \
	    -e 's/%NV/'$NV'/g' $sixdeskhome/inc/dalie6.mask > $sixdeskjobs_logs/dalie.input
	let __lerr+=$?
	cp $sixdeskhome/bin/dalie6 $sixdeskjobs_logs/dalie
    else
	sed -e 's/%NO/'$NO'/g' $sixdeskhome/inc/dalie4.data.mask > $sixdeskjobs_logs/dalie.data
	let __lerr+=$?
	sed -e 's/%NO/'$NO1'/g' \
	    -e 's/%NV/'$NV'/g' $sixdeskhome/inc/dalie4.mask > $sixdeskjobs_logs/dalie.input
	let __lerr+=$?
	cp $sixdeskhome/bin/dalie4 $sixdeskjobs_logs/dalie
    fi
    let __lerr+=$?
    cp $sixdeskhome/inc/reson.data $sixdeskjobs_logs
    let __lerr+=$?
    cp $sixdeskhome/bin/readda $sixdeskjobs_logs
    let __lerr+=$?
    return $__lerr
}

function preProcessBoinc(){

    local __lerr=0

    # root dir
    [ -d $sixdeskboincdir ] || mkdir -p $sixdeskboincdir
    let __lerr+=$?

    # 'ownership'
    if [ -e $sixdeskboincdir/owner ] ; then
	tmpOwner=`cat $sixdeskboincdir/owner`
	if [ "${tmpOwner}" != "$LOGNAME" ] ; then
	    sixdeskmess -1 "Err of ownership of $sixdeskboincdir: ${tmpOwner} (expected: $LOGNAME)"
	    let __lerr+=1
	    return $__lerr
	fi
    fi	
    
    # acl rights, to modify default settings (inherited by work.boinc volume),
    #   so that all the daughter dirs/files inherit the same acl rights
    fs setacl -dir $sixdeskboincdir -acl $LOGNAME rlidwka -acl boinc:users rl
    if [ $? -gt 0 ] ; then
	sixdeskmess -1 "error while setting acl rights for dir $sixdeskboincdir !!!"
	let __lerr+=1
    fi
	
    [ -e $sixdeskboincdir/owner ] || echo "$LOGNAME" > $sixdeskboincdir/owner
    let __lerr+=$?
    [ -d $sixdeskboincdir/work ] || mkdir $sixdeskboincdir/work
    let __lerr+=$?
    [ -d $sixdeskboincdir/results ] || mkdir $sixdeskboincdir/results
    let __lerr+=$?

    # counter of workunits
    if [ ! -d $sixdeskhome/sixdeskTaskIds/$LHCDescrip ] ; then
	mkdir -p $sixdeskhome/sixdeskTaskIds/$LHCDescrip
	let __lerr+=$?
	echo "0" > $sixdeskhome/sixdeskTaskIds/$LHCDescrip/sixdeskTaskId
	let __lerr+=$?
    fi

    # megaZip
    if ${lmegazip} ; then
	# generate name of megaZip file
	sixdeskDefineMegaZipName "$workspace" "$LHCDescrip" megaZipName
	# ...and keep it until submission takes place
	echo "${megaZipName}" > ${sixdeskjobs_logs}/megaZipName.txt
	# initialise list of .zip/.desc files to be zipped
	[ ! -e ${sixdeskjobs_logs}/megaZipList.txt ] || rm -f ${sixdeskjobs_logs}/megaZipList.txt
	sixdeskmess -1 "Requested submission to boinc through megaZip option - filename: ${megaZipName}"
    fi

    return ${__lerr}
}

function submitChromaJobs(){

    local __destination=$1
    local __GLOBIGNORE='fort.[2,8]:fort.16:fort*.3.*:fort.10*:sixdesklock'
    
    # --------------------------------------------------------------------------
    # generate appropriate fort.3 files as: fort.3.tx + fort.3.mad + fort.3.m2
    # - fort.3.t1 (from .mother1)
    sed -e 's/%turnss/'1'/g' \
        -e 's/%nss/'1'/g' \
        -e 's/%ax0s/'.1'/g' \
        -e 's/%ax1s/'.1'/g' \
        -e 's/%imc/'1'/g' \
        -e 's/%iclo6/'2'/g' \
        -e 's/%writebins/'1'/g' \
        -e 's/%ratios/'1'/g' \
        -e 's/%dp1/'.000'/g' \
        -e 's/%dp2/'.000'/g' \
        -e 's/%e0/'$e0'/g' \
        -e 's/%Runnam/First Turn/g' \
        -e 's/%idfor/0/g' \
        -e 's/%ibtype/0/g' \
        -e 's/%bunch_charge/'$bunch_charge'/g' \
        -e 's/%ition/'0'/g' ${sixtrack_input}/fort.3.mother1 > fort.3.t1
    # - fort.3.t2 (from .mother1)
    sed -e 's/%turnss/'1'/g' \
        -e 's/%nss/'1'/g' \
        -e 's/%ax0s/'.1'/g' \
        -e 's/%ax1s/'.1'/g' \
        -e 's/%imc/'1'/g' \
        -e 's/%iclo6/'2'/g' \
        -e 's/%writebins/'1'/g' \
        -e 's/%ratios/'1'/g' \
        -e 's/%dp1/'$chrom_eps'/g' \
        -e 's/%dp2/'$chrom_eps'/g' \
        -e 's/%e0/'$e0'/g' \
        -e 's/%Runnam/Second Turn/g' \
        -e 's/%idfor/0/g' \
        -e 's/%ibtype/0/g' \
        -e 's/%bunch_charge/'$bunch_charge'/g' \
        -e 's/%ition/'0'/g' ${sixtrack_input}/fort.3.mother1 > fort.3.t2
    # - fort.3.m2 (from .mother2)
    local __CHROVAL='/'
    sed -e 's?%CHRO?'$__CHROVAL'?g' \
        -e 's?%TUNE?'$TUNEVAL'?g' \
        -e 's/%POST/'POST'/g' \
        -e 's/%POS1/''/g' \
        -e 's/%ndafi/'1'/g' \
        -e 's/%tunex/'$tunexx'/g' \
        -e 's/%tuney/'$tuneyy'/g' \
        -e 's/%chromx/'$chromx'/g' \
        -e 's/%chromy/'$chromy'/g' \
        -e 's/%inttunex/'$inttunexx'/g' \
        -e 's/%inttuney/'$inttuneyy'/g' \
        -e 's/%DIFF/\/DIFF/g' \
        -e 's/%DIF1/\//g' $sixdeskjobs_logs/fort.3.mother2 > fort.3.m2

    # --------------------------------------------------------------------------
    # prepare the other input files
    ln -sf ${sixtrack_input}/fort.16
    ln -sf ${sixtrack_input}/fort.2
    if [ -e ${sixtrack_input}/fort.8 ] ; then
        ln -sf ${sixtrack_input}/fort.8
    else
        touch fort.8
    fi
    
    # --------------------------------------------------------------------------
    # actually run
    
    # - first job
    sixdeskmess  1 "Running the first one turn job for chromaticity"
    cat fort.3.t1 fort.3.mad fort.3.m2 > fort.3
    rm -f fort.10
    $SIXTRACKEXE > first_oneturn
    if test $? -ne 0 -o ! -s fort.10 ; then
        sixdeskmess -1 "The first turn Sixtrack for chromaticity FAILED!!!"
        sixdeskmess -1 "Look in $sixdeskjobs_logs to see SixTrack input and output."
        sixdeskmess -1 "Check the file first_oneturn which contains the SixTrack fort.6 output."
	exit
    fi
    # save all interesting files from first job
    [ -d chromaJob01 ] || mkdir chromaJob01
    cp fort.2 fort.3 fort.8 fort.16 fort.10 first_oneturn chromaJob01
    gzip chromaJob01/*
    mv fort.10 fort.10_first_oneturn
    # clean dir
    export GLOBIGNORE=${__GLOBIGNORE}
    rm -f *
    export GLOBIGNORE=

    # - second job
    sixdeskmess  1 "Running the second one turn job for chromaticity"
    cat fort.3.t2 fort.3.mad fort.3.m2 > fort.3
    rm -f fort.10
    $SIXTRACKEXE > second_oneturn
    if test $? -ne 0 -o ! -s fort.10 ; then
        sixdeskmess -1 "The second turn Sixtrack for chromaticity FAILED!!!"
        sixdeskmess -1 "Look in $sixdeskjobs_logs to see SixTrack input and output."
        sixdeskmess -1 "Check the file second_oneturn which contains the SixTrack fort.6 output."
	exit
    fi
    # save all interesting files from second job
    [ -d chromaJob02 ] || mkdir chromaJob02
    cp fort.2 fort.3 fort.8 fort.16 fort.10 second_oneturn chromaJob02
    gzip chromaJob02/*
    mv fort.10 fort.10_second_oneturn
    # clean dir
    export GLOBIGNORE=${__GLOBIGNORE}
    rm -f *
    export GLOBIGNORE=

    # --------------------------------------------------------------------------
    # a bit of arithmetic
    echo "$chrom_eps" > $__destination/sixdesktunes
    gawk 'FNR==1{print $3, $4}' < fort.10_first_oneturn >> $__destination/sixdesktunes
    gawk 'FNR==1{print $3, $4}' < fort.10_second_oneturn >> $__destination/sixdesktunes
    mychrom=`gawk 'FNR==1{E=$1}FNR==2{A=$1;B=$2}FNR==3{C=$1;D=$2}END{print (C-A)/E,(D-B)/E}' < $__destination/sixdesktunes`
    echo "$mychrom" > $__destination/mychrom          
    sixdeskmess -1 "Chromaticity computed as $mychrom"
    
}

function submitBetaJob(){
    
    local __destination=$1
    local __GLOBIGNORE='fort.[2,8]:fort.16:fort*.3.*:fort.10*:sixdesklock:lin*'
    
    # --------------------------------------------------------------------------
    # generate appropriate fort.3 files as: fort.3.m1 + fort.3.mad + fort.3.m2
    sed -e 's/%turnss/'1'/g' \
        -e 's/%nss/'1'/g' \
        -e 's/%ax0s/'.1'/g' \
        -e 's/%ax1s/'.1'/g' \
        -e 's/%imc/'1'/g' \
        -e 's/%iclo6/'2'/g' \
        -e 's/%writebins/'1'/g' \
        -e 's/%ratios/'1'/g' \
        -e 's/%dp1/'.000'/g' \
        -e 's/%dp2/'.000'/g' \
        -e 's/%e0/'$e0'/g' \
        -e 's/%Runnam/One Turn/g' \
        -e 's/%idfor/0/g' \
        -e 's/%ibtype/0/g' \
        -e 's/%bunch_charge/'$bunch_charge'/g' \
        -e 's/%ition/'1'/g' ${sixtrack_input}/fort.3.mother1 > fort.3.m1
    sed -e 's?%CHRO?'$CHROVAL'?g' \
        -e 's?%TUNE?'$TUNEVAL'?g' \
        -e 's/%POST/'POST'/g' \
        -e 's/%POS1/''/g' \
        -e 's/%ndafi/'1'/g' \
        -e 's/%tunex/'$tunexx'/g' \
        -e 's/%tuney/'$tuneyy'/g' \
        -e 's/%chromx/'$chromx'/g' \
        -e 's/%chromy/'$chromy'/g' \
        -e 's/%inttunex/'$inttunexx'/g' \
        -e 's/%inttuney/'$inttuneyy'/g' \
        -e 's/%DIFF/\/DIFF/g' \
        -e 's/%DIF1/\//g' $sixdeskjobs_logs/fort.3.mother2 > fort.3.m2
    cat fort.3.m1 fort.3.mad fort.3.m2 > fort.3
    
    # --------------------------------------------------------------------------
    # prepare the other input files
    ln -sf ${sixtrack_input}/fort.16
    ln -sf ${sixtrack_input}/fort.2
    if [ -e ${sixtrack_input}/fort.8 ] ; then
        ln -sf ${sixtrack_input}/fort.8
    else
        touch fort.8
    fi

    # --------------------------------------------------------------------------
    # actually run
    rm -f fort.10
    $SIXTRACKEXE > lin
    if test $? -ne 0 -o ! -s fort.10 ; then
        sixdeskmess -1 "The one turn Sixtrack for betavalues FAILED!!!"
        sixdeskmess -1 "Look in $sixdeskjobs_logs to see SixTrack input and output."
        sixdeskmess -1 "Check the file lin which contains the SixTrack fort.6 output."
	exit
    fi
    # save all interesting files from beta job
    [ -d betaJob ] || mkdir betaJob
    cp fort.2 fort.3 fort.8 fort.16 fort.10 lin betaJob
    gzip betaJob/*
    mv lin lin_old
    cp fort.10 fort.10_old
    # clean dir
    export GLOBIGNORE=${__GLOBIGNORE}
    rm -f *
    export GLOBIGNORE=

    # --------------------------------------------------------------------------
    # regenerate betavalues file
    echo `gawk 'FNR==1{print $5, $48, $6, $49, $3, $4, $50, $51, $53, $54, $55, $56, $57, $58}' fort.10` > $__destination/betavalues
    # but if chrom=0 we need to update chromx, chromy
    if [ $chrom -eq 0 ] ; then
        beta_x=`gawk '{print $1}' $__destination/betavalues`
        beta_x2=`gawk '{print $2}' $__destination/betavalues`
        beta_y=`gawk '{print $3}' $__destination/betavalues`
        beta_y2=`gawk '{print $4}' $__destination/betavalues`
        mychromx=`gawk '{print $1}' $__destination/mychrom`
        mychromy=`gawk '{print $2}' $__destination/mychrom`
        htune=`gawk '{print $5}' $__destination/betavalues`
        vtune=`gawk '{print $6}' $__destination/betavalues`
        closed_orbit=`awk '{print ($9,$10,$11,$12,$13,$14)}' $__destination/betavalues`
        echo "$beta_x $beta_x2 $beta_y $beta_y2 $htune $vtune $mychromx $mychromy $closed_orbit" > $__destination/betavalues
    fi
    
}

function submitCreateRundir(){
    # this function is called after a sixdeskDefinePointTree, with the check
    #    that RunDirFullPath and actualDirNameFullPath are non-zero length strings
    local __RunDirFullPath=$1
    local __actualDirNameFullPath=$2
    sixdeskmess  1 "Taking care of running dir $__RunDirFullPath (and linking to $__actualDirNameFullPath)"
    [ ! -d $__RunDirFullPath ] || rm -rf $__RunDirFullPath
    mkdir -p $__RunDirFullPath
    [ ! -e $__actualDirNameFullPath ] || rm -rf $__actualDirNameFullPath
    ln -fs $__RunDirFullPath $__actualDirNameFullPath
}

function submitCreateFinalFort3Short(){
    local __kk=$1
    if [ $__kk -eq 0 ] ; then
	sed -e 's/%Runnam/'$Runnam'/g' \
	    -e 's/%tunex/'$tunexx'/g' \
	    -e 's/%tuney/'$tuneyy'/g' \
	    -e 's/%inttunex/'$inttunexx'/g' \
	    -e 's/%inttuney/'$inttuneyy'/g' $sixdeskjobs_logs/fort0.3.mask > $sixdeskjobs_logs/fort.3
    else
        # returns ratio
	sixdeskRatio $kang $lbackcomp
        # returns ax0 and ax1
	sixdeskax0 $factor $beta_x $beta_x2 $beta_y $beta_y2 $ratio $kang $square $ns1s $ns2s $lbackcomp
	sed -e 's/%nss/'$nss'/g' \
	    -e 's/%turnss/'$turnss'/g' \
	    -e 's/%ax0s/'$ax0'/g' \
	    -e 's/%ax1s/'$ax1'/g' \
	    -e 's/%ratios/'$ratio'/g' \
	    -e 's/%tunex/'$tunexx'/g' \
	    -e 's/%tuney/'$tuneyy'/g' \
	    -e 's/%inttunex/'$inttunexx'/g' \
	    -e 's/%inttuney/'$inttuneyy'/g' \
	    -e 's/%Runnam/'$Runnam'/g' \
	    -e 's/%writebins/'$writebins'/g' $sixdeskjobs_logs/forts.3.mask > $sixdeskjobs_logs/fort.3
    fi
}

function submitCreateFinalFort3Long(){

    local __lerr=0

    # returns ratio
    sixdeskRatio $kang $lbackcomp
    [ -n "${ratio}" ] || let __lerr+=1
    # returns ax0 and ax1
    sixdeskax0 $factor $beta_x $beta_x2 $beta_y $beta_y2 $ratio $kang $square $fampstart $fampend $lbackcomp
    [ -n "${ax0}" ] || let __lerr+=1
    [ -n "${ax1}" ] || let __lerr+=1
    #
    sed -e 's/%turnsl/'$turnsl'/g' \
	-e 's/%ax0l/'$ax0'/g' \
	-e 's/%ax1l/'$ax1'/g' \
	-e 's/%ratiol/'$ratio'/g' \
	-e 's/%tunex/'$tunexx'/g' \
	-e 's/%tuney/'$tuneyy'/g' \
	-e 's/%inttunex/'$inttunexx'/g' \
	-e 's/%inttuney/'$inttuneyy'/g' \
	-e 's/%Runnam/'$Runnam'/g' \
	-e 's/%writebinl/'$writebinl'/g' $sixdeskjobs_logs/fortl.3.mask > $sixdeskjobs_logs/fort.3
    let __lerr+=${PIPESTATUS[0]}
    return ${__lerr}
}

function submitCreateFinalFort3DA(){
    sed -e 's/%NO/'$NO'/g' \
        -e 's/%tunex/'$tunexx'/g' \
        -e 's/%tuney/'$tuneyy'/g' \
        -e 's/%inttunex/'$inttunexx'/g' \
        -e 's/%inttuney/'$inttuneyy'/g' \
        -e 's/%Runnam/'$Runnam'/g' \
        -e 's/%NV/'$NV'/g' $sixdeskjobs_logs/fortda.3.mask > $sixdeskjobs_logs/fort.3
}

function submitCreateFinalInputs(){
    local __lerr=0

    sixdeskmess  1 "Taking care of SIXTRACK fort.2/fort.3/fort.8/fort.16 in $RundirFullPath"

    # fort.3
    gzip -c $sixdeskjobs_logs/fort.3 > $RundirFullPath/fort.3.gz
	
    # input from MADX: fort.2/.8/.16
    for iFort in 2 8 16 ; do
	[ ! -e $RundirFullPath/fort.${iFort}.gz ] || rm -f $RundirFullPath/fort.${iFort}.gz
	ln -s $sixtrack_input/fort.${iFort}_$iMad.gz $RundirFullPath/fort.${iFort}.gz
    done
	
    if [ "$sixdeskplatform" == "boinc" ] ; then
	
	# generate zip/description file
	# - generate new taskid
	sixdeskTaskId=`awk '{print ($1+1)}' $sixdeskhome/sixdeskTaskIds/$LHCDescrip/sixdeskTaskId`
	echo $sixdeskTaskId > $sixdeskhome/sixdeskTaskIds/$LHCDescrip/sixdeskTaskId
	sixdesktaskid=boinc$sixdeskTaskId
	sixdeskmess  1 "sixdesktaskid: $sixdesktaskid - $sixdeskTaskId"
	# - return sixdeskTaskName and workunitName
	sixdeskDefineWorkUnitName $workspace $Runnam $sixdesktaskid
	let __lerr+=$?
	if [ ${__lerr} -eq 0 ] ; then
	    # - generate zip file
	    #   NB: -j option, to store only the files, and not the source paths
	    multipleTrials "zip -j $RundirFullPath/$workunitName.zip $sixdeskjobs_logs/fort.3 $sixtrack_input/fort.2 $sixtrack_input/fort.8 $sixtrack_input/fort.16 > $RundirFullPath/zip.log 2>&1; local __zip_exit_status=\$? ; grep warning $RundirFullPath/zip.log >/dev/null 2>&1 ; local __zip_warnings=\$? ; rm -f $RundirFullPath/zip.log" "[ \${__zip_exit_status} -eq 0 ] && [ \${__zip_warnings} -eq 1 ]" "Failing to generate .zip file for WU ${workunitName}"
	    let __lerr+=$?
	    # - generate the workunit description file
	    cat > $RundirFullPath/$workunitName.desc <<EOF
$workunitName
$fpopsEstimate 
$fpopsBound
$memBound
$diskBound
$delayBound
$redundancy
$copies
$errors
$numIssues
$resultsWithoutConcensus
EOF
	    let __lerr+=$?
  	    # - update MegaZip file:
	    if ${lmegazip} ; then
		echo "$RundirFullPath/$workunitName.desc" >> ${sixdeskjobs_logs}/megaZipList.txt
		echo "$RundirFullPath/$workunitName.zip" >> ${sixdeskjobs_logs}/megaZipList.txt
	    fi
	fi
    fi
    
    return $__lerr
}

function fixDir(){
    # this function is called after a sixdeskDefinePointTree, with the check
    #    that RunDirFullPath and actualDirNameFullPath are non-zero length strings
    local __RunDirFullPath=$1
    local __actualDirNameFullPath=$2
    local __iFixed=0
    if [ ! -d $__RunDirFullPath ] ; then
	sixdeskmess -1 "...directory path has problems: recreating it!!!"
	rm -rf $__RunDirFullPath
	mkdir -p $__RunDirFullPath
	let __iFixed+=1
    fi
    if [ ! -L $__actualDirNameFullPath ] ; then
	sixdeskmess -1 "...directory link has problems: recreating it!!!"
	rm -rf $__actualDirNameFullPath
	ln -fs $__RunDirFullPath $__actualDirNameFullPath
	let __iFixed+=1
    fi
    return ${__iFixed}
}

function fixInputFiles(){
    local __RunDirFullPath=$1
    local __iFixed=0
    
    # fort.3
    if [ ! -f $RundirFullPath/fort.3.gz ] ; then
	sixdeskmess -1 "...fort.3.gz has problems: recreating it!!!"
	gzip -c $sixdeskjobs_logs/fort.3 > $RundirFullPath/fort.3.gz
	let __iFixed+=1
    fi
	
    # input from MADX: fort.2/.8/.16
    for iFort in 2 8 16 ; do
	if [ ! -f $RundirFullPath/fort.${iFort}.gz ] ; then
	    sixdeskmess -1 "...fort.${iFort}.gz has problems: recreating it!!!"
	    ln -s $sixtrack_input/fort.${iFort}_$iMad.gz $RundirFullPath/fort.${iFort}.gz
	    let __iFixed+=1
	fi
    done
    return ${__iFixed}
}

function checkDirStatus(){
    sixdeskInspectPrerequisites ${lverbose} $RundirFullPath -d
    if [ $? -eq 0 ] ; then
	let nFound[0]+=1
	for (( iFound=1; iFound<${#foundNames[@]}; iFound++ )) ; do
	    sixdeskInspectPrerequisites ${lverbose} $RundirFullPath -s ${foundNames[$iFound]}
	    if [ $? -eq 0 ] ; then
		let nFound[$iFound]+=1
	    else
		sixdeskmess -1 "${foundNames[$iFound]} in ${RundirFullPath} is missing"
	    fi
	done
    else
	sixdeskmess -1 "point ${RundirFullPath} is missing!"
    fi
}

function checkDirReadyForSubmission(){
    local __lerr=0
    local __llerr=0
    
    sixdeskInspectPrerequisites ${lverbose} $RundirFullPath -d
    let __lerr+=$?
    sixdeskInspectPrerequisites ${lverbose} $RundirFullPath -s fort.2.gz fort.3.gz fort.8.gz fort.16.gz
    let __lerr+=$?
    if [ "$sixdeskplatform" == "lsf" ] ; then
	sixdeskInspectPrerequisites ${lverbose} $RundirFullPath -s $Runnam.sh
	let __lerr+=$?
    elif [ "$sixdeskplatform" == "boinc" ] ; then
	# - there should be only 1 .desc/.zip files
	fileNames=""
	for extension in .desc .zip ; do
	    tmpFileName=`ls -1tr $RundirFullPath/*${extension} 2> /dev/null | tail -1`
	    tmpPath="${tmpFileName%/*}"
	    tmpFileName="${tmpFileName#$tmpPath/*}"
	    tmpFileName="${tmpFileName%$extension}"
	    if [ -z "${tmpFileName}" ] ; then
		sixdeskmess -1 "no ${extension} file in $RundirFullPath!!!"
		let __lerr+=1
		let __llerr+=1
	    else
		sixdeskGetFileName "${tmpFileName}" tmpName
		fileNames="${fileNames} ${tmpName}"
	    fi
	done
	fileNames=( ${fileNames} )
	# - the two files should have the same name
	if [ "${fileNames[0]}" != "${fileNames[1]}" ] ; then
	    sixdeskmess -1 "mismatch between .desc and .zip file names in $RundirFullPath: ${fileNames[0]} and ${fileNames[1]}!"
	    let __lerr+=$?
	elif [ ${__llerr} -eq 0 ] ; then
	    workunitName="${fileNames[0]}"
	    sixdeskmess  1 ".desc and .zip files present in $RundirFullPath!"
	fi
    fi
    if [ $sussix -eq 1 ] ; then
	sixdeskInspectPrerequisites ${lverbose} $RundirFullPath -s sussix.inp.1.gz sussix.inp.2.gz sussix.inp.3.gz
	let __lerr+=$?
    fi

    return $__lerr
}

function checkDirAlreadyRun(){

    local __lstatus=0

    if [ -s $RundirFullPath/JOB_NOT_YET_COMPLETED ] ; then
	sixdeskmess -1 "JOB_NOT_YET_COMPLETED in $RundirFullPath!"
	let __lstatus+=1
    elif [ -s $RundirFullPath/fort.10.gz ] ; then
	sixdeskmess -1 "fort.10.gz already generated in $RundirFullPath!"
	let __lstatus+=1
    fi

    return $__lstatus

}

function dot_bsub(){

    # temporary variables
    local __lerr=0
    local __taskno=""
    local __tmpLines=""

    # actually submit
    # typical message returned by bsub:
    #   Job <864248893> is submitted to queue <8nm>.
    multipleTrials "__tmpLines=\"\`bsub -q $lsfq -o $RundirFullPath/$Runnam.log $RundirFullPath/$Runnam.sh 2>&1\`\" ; __taskno=\`echo \"\${__tmpLines}\" | grep submitted | cut -d\< -f2 | cut -d\> -f1\`;" "[ -n \"\${__taskno}\" ]" "Problem at bsub"
    let __lerr+=$?

    # verify that submission was successfull
    if  [ ${__lerr} -eq 0 ] ; then
	local __taskid="lsf${__taskno}"
	sixdeskmess  1 "`echo \"${__tmpLines}\" | grep submitted`"
    else
	sixdeskmess -1 "bsub of $RundirFullPath/$Runnam.sh to Queue ${lsfq} failed !!! - going to next WU!"
    fi

    if [ ${__lerr} -eq 0 ] ; then
        # keep track of the $Runnam-taskid couple
	updateTaskIdsCases $sixdeskjobs/jobs $sixdeskjobs/incomplete_jobs $__taskid $Runnam
    else
	rm -f $RundirFullPath/JOB_NOT_YET_STARTED 
    fi

    return $__lerr
}

function dot_htcondor(){

    # temporary variables
    local __lerr=0

    # add current point in scan to list of points to be submitted:
    echo "$Rundir" >> ${sixdeskjobs}/${LHCDesName}.list

    return $__lerr
}

function dot_boinc(){

    # temporary variables
    local __lerr=0
    
    # actually submit
    descFileNames=`ls -1 $RundirFullPath/*.desc 2> /dev/null`
    sixdeskGetFileName "${descFileNames}" workunitname
    sixdeskGetTaskIDfromWorkUnitName $workunitname
    if ! ${lmegazip} ; then
	multipleTrials "cp $RundirFullPath/$workunitname.desc $RundirFullPath/$workunitname.zip $sixdeskboincdir/work ; local __exit_status=\$?" "[ \$__exit_status -eq 0 ]" "Submission to BOINC - Problem at cp to spooldir"
	let __lerr+=$?
	if [ ${__lerr} -ne 0 ] ; then
	    sixdeskmess -1 "failed to submit boinc job!!!"
	else
	    sixdeskmess  1 "Submitting WU to BOINC as taskid ${sixdesktaskid}"
	fi
	
    fi

    if [ ${__lerr} -eq 0 ] ; then
        # the job has just started
	touch $RundirFullPath/JOB_NOT_YET_COMPLETED
        # keep track of the $Runnam-taskid couple
	updateTaskIdsCases $sixdeskjobs/tasks $sixdeskjobs/incomplete_tasks $sixdesktaskid $Runnam
    fi

    # in case of LSF, this operation is done either by:
    # - dot_bsub, in case of un-successful submission;
    # - the job at statup, in case of successful submission;
    rm -f $RundirFullPath/JOB_NOT_YET_STARTED

    return $__lerr
}

function condor_sub(){
    local __lerr=0
    echo ""
    printf "=%.0s" {1..80}
    echo ""
    if [ ! -e ${sixdeskjobs}/${LHCDesName}.list ] ; then
	sixdeskmess -1 "List of tasks not there: ${sixdeskjobs}/${LHCDesName}.list"
	let __lerr+=1
    elif [ `wc -l ${sixdeskjobs}/${LHCDesName}.list 2> /dev/null | awk '{print ($1)}'` -eq 0 ] ; then
	sixdeskmess -1 "Empty list of tasks: ${sixdeskjobs}/${LHCDesName}.list"
	rm -f ${sixdeskjobs}/${LHCDesName}.list
	let __lerr+=1
    else
	cd ${sixdesktrack}
	iBatch=$((${nQueued}/${nMaxJobsSubmitHTCondor}))
	if [ ${iBatch} -eq 0 ] ; then
	    sixdeskmess 1 "checking if there are already some condor clusters from the same workspace/study ..."
	    i0Batch=`condor_q -wide | grep run_six/$workspace/$LHCDescrip | awk '{print ($2)}' | cut -d\/ -f4 | sort | tail -1`
	    if [ -n "${i0Batch}" ] ; then
		iBatch=${i0Batch}
	    fi
	fi
	let iBatch+=1
	if [ ${iBatch} -eq 1 ] ; then
            batch_name="run_six/$workspace/$LHCDescrip"
	else
            batch_name="run_six/$workspace/${LHCDescrip}/${iBatch}"
	fi
	sixdeskmess -1 "Submitting jobs to $sixdeskplatform from dir $PWD - batch name: \"$batch_name\""
	sixdeskmess  1 "Depending on the number of points in the scan, this operation can take up to few minutes."
	sixdeskmess -1 "First job: `head -1 ${sixdeskjobs}/${LHCDesName}.list`"
	sixdeskmess -1 "Last job: `tail -1 ${sixdeskjobs}/${LHCDesName}.list`"
	# let's renew the kerberos token just before submitting
	sixdeskmess 2 "renewing kerberos token before submission to HTCondor"
	sixdeskRenewKerberosToken
	multipleTrials "terseString=\"\`condor_submit -batch-name ${batch_name} -terse ${sixdeskjobs}/htcondor_run_six.sub\`\" " "[ -n \"\${terseString}\" ]" "Problem at condor_submit"
	let __lerr+=$?
	if [ ${__lerr} -ne 0 ] ; then
	    sixdeskmess -1 "Something wrong with htcondor submission: submission didn't work properly - exit status: ${__lerr}"
	    # clean
	    while read tmpDir ; do
		rm -f ${tmpDir}/JOB_NOT_YET_STARTED 
	    done < ${sixdeskjobs}/${LHCDesName}.list
	else
	    sixdeskmess -1 "Submission was successful"
	    # parse terse output (example: "23548.0 - 23548.4")
	    clusterID=`echo "${terseString}" | head -1 | cut -d\- -f2 | cut -d\. -f1`
	    clusterID=${clusterID//\ /}
	    jobIDmax=`echo "${terseString}" | head -1 | cut -d\- -f2 | cut -d\. -f2`
	    let jobIDmax+=1
	    nCases=`wc -l ${sixdeskjobs}/${LHCDesName}.list | awk '{print ($1)}'`
	    if [ ${jobIDmax} -ne ${nCases} ] ; then
		sixdeskmess -1 "Something wrong with htcondor submission: I requested ${nCases} to be submitted, and only ${jobIDmax} actually made it!"
	    fi
	    # save taskIDs
	    sixdeskmess -1 "Updating DB..."
	    sixdeskmess  1 "Depending on the number of points in the scan, this operation can take up to few minutes."
	    ii=0
	    while read tmpDir ; do
		taskid="htcondor${clusterID}.${ii}"
		Runnam=$(sixdeskFromJobDirToJobName ${tmpDir} ${lbackcomp})
		updateTaskIdsCases $sixdeskjobs/jobs $sixdeskjobs/incomplete_jobs $taskid $Runnam
		let NsuccessSub+=1
		let ii+=1
	    done < ${sixdeskjobs}/${LHCDesName}.list
	    rm -f ${sixdeskjobs}/${LHCDesName}.list
	fi
	cd - > /dev/null 2>&1
    fi
    echo ""
    printf "=%.0s" {1..80}
    echo ""
    echo ""
    return ${__lerr}
}

function dot_megaZip(){

    local __megaZipFileName=$1
    local __megaZipFileList=$2
    local __lerr=0

    sixdeskmess  1 "generating megaZip file ${__megaZipFileName}"

    local __iNLT=5000
    local __nLines=`wc -l ${__megaZipFileList} | awk '{print ($1)}'`
    local __iiMax=`echo "${__iNLT} ${__nLines}" | awk '{print (int($2/$1+0.001))}'`
    local __nResiduals=`echo "${__iNLT} ${__nLines} ${__iiMax}" | awk '{print (int($2-$3*$1+0.001))}'`
    for (( ii=1; ii<=${__iiMax} ; ii++ )) ; do
	let nHead=$ii*${__iNLT}
	local __tmpLines=`head -n ${nHead} ${__megaZipFileList} | tail -n ${__iNLT}`
	# NB: -j option, to store only the files, and not the source paths
	zip -j ${__megaZipFileName} ${__tmpLines}
	let __lerr+=$?
    done
    if [ ${__nResiduals} -gt 0 ] ; then
	local __tmpLines=`tail -n ${__nResiduals} ${__megaZipFileList}`
	# NB: -j option, to store only the files, and not the source paths
	zip -j ${__megaZipFileName} ${__tmpLines}
	let __lerr+=$?
    fi

    return ${__lerr}

}

function dot_clean(){
    if [ -s $RundirFullPath/fort.10.gz ] || [ -s $RundirFullPath/JOB_NOT_YET_COMPLETED ]; then
	rm -f $RundirFullPath/fort.10.gz
	rm -f $RundirFullPath/JOB_NOT_YET_COMPLETED
	rm -f $RundirFullPath/JOB_NOT_YET_STARTED 
	sed -i -e '/^'$Runnam'$/d' $sixdeskwork/completed_cases
	sed -i -e '/^'$Runnam'$/d' $sixdeskwork/mycompleted_cases
    fi
}
    
function dot_cleanZips(){
    local __tmpPath=$1
    local __zipFileName=$2
    local __descFileName=$3
    if [ ! -e ${__tmpPath}/JOB_NOT_YET_STARTED ] ; then
	sixdeskmess  1 "Removing .desc/.zip files in ${__tmpPath}"
	rm -f ${__tmpPath}/${__zipFileName} ${__tmpPath}/${__descFileName}
    fi
}

function updateTaskIdsCases(){
    # keep track of the $Runnam-taskid couple
    
    local __outFile1=$1
    local __outFile2=$2
    local __taskid=$3
    local __Runnam=$4
    local __taskids
    local __oldtaskid

    __oldtaskid=`grep "${__Runnam} " $sixdeskwork/taskids`
    if [ -n "$__oldtaskid" ] ; then
	__oldtaskid=`echo $__oldtaskid | cut -d " " -f2-`
	sed -i -e "/${__Runnam} /d" $sixdeskwork/taskids
	__taskids="${__oldtaskid} ${__taskid} "
	sixdeskmess 1 "Job ${__Runnam} re-submitted with JobId/taskid $__taskid; old JobId/taskid(s) $__oldtaskid"
    else
	__taskids=$__taskid
	echo ${__Runnam} >> $sixdeskwork/incomplete_cases
	echo ${__Runnam} >> $sixdeskwork/myincomplete_cases
	sixdeskmess 1 "Job ${__Runnam} submitted with JobId/taskid $__taskid"
    fi
    echo "${__Runnam} ${__taskids} " >> $sixdeskwork/taskids
    echo "${__Runnam} ${__taskid} " >> $__outFile1
    echo "${__Runnam} ${__taskid} " >> $__outFile2
    
}

function treatShort(){

    if ${lgenerate} || ${lfix} ; then
	if [ $sussix -eq 1 ] ; then
	    # and now we get fractional tunes to plug in qx/qy
            qx=`gawk 'END{qx='$fhtune'-int('$fhtune');print qx}' /dev/null`
            qy=`gawk 'END{qy='$fvtune'-int('$fvtune');print qy}' /dev/null`
            sixdeskmess -1 "Sussix tunes set to $qx, $qy from $fhtune, $fvtune"
            sed -e 's/%qx/'$qx'/g' \
		-e 's/%qy/'$qy'/g' $sixdeskjobs_logs/sussix.tmp.1 > $sixdeskjobs_logs/sussix.inp.1
            sed -e 's/%qx/'$qx'/g' \
		-e 's/%qy/'$qy'/g' $sixdeskjobs_logs/sussix.tmp.2 > $sixdeskjobs_logs/sussix.inp.2
            sed -e 's/%qx/'$qx'/g' \
		-e 's/%qy/'$qy'/g' $sixdeskjobs_logs/sussix.tmp.3 > $sixdeskjobs_logs/sussix.inp.3
	    for tmpI in $(seq 1 3) ; do
		gzip -f $sixdeskjobs_logs/sussix.inp.$tmpI
	    done
	fi
    fi
    if ${lcheck} ; then
	if [ $sussix -eq 1 ] ; then
	    #
	    sixdeskInspectPrerequisites ${lverbose} $sixdeskjobs_logs -e sussix.inp.1.gz sussix.inp.2.gz sussix.inp.3.gz
	    if [ $? -gt 0 ] ; then
		sixdeskmess -1 "Error in creating sussix input files"
		exit
	    fi
	fi
    fi

    # ======================================================================
    for (( iAngle=0; iAngle<${#KKs[@]}; iAngle++ )) ; do
    # ======================================================================

	# separate output for current case from previous one
	echo ""

	# trigger for preparation
	local __lGenerate=false
	# trigger for submission
	local __lSubmit=false
	# exit status: dir ready for submission
	local __eCheckDirReadyForSubmission=0
	# exit status: dir already run
	local __eCheckDirAlreadyRun=0
	# fixing dir
	local __iFixed=0

	# kk, Angle and kang
	kk=${KKs[${iAngle}]}
	Angle=${Angles[${iAngle}]}
	kang=${kAngs[${iAngle}]}

	let nConsidered+=1
	
	# get dirs for this point in scan (returns Runnam, Rundir, actualDirName)
	# ...and notify user
        if [ $kk -eq 0 ] ; then
	    sixdeskDefinePointTree $LHCDesName $iMad "m" $sixdesktunes "__" "0" $Angle $kk $sixdesktrack
	    if [ $? -gt 0 ] ; then
		# go to next WU (sixdeskmess already printed out and email sent to user/admins)
		continue
	    fi
            sixdeskmess 1 "Momen $Runnam $Rundir, k=$kk"
	else
	    sixdeskDefinePointTree $LHCDesName $iMad "t" $sixdesktunes $Ampl $turnsse $Angle $kk $sixdesktrack
	    if [ $? -gt 0 ] ; then
		# go to next WU (sixdeskmess already printed out and email sent to user/admins)
		continue
	    fi
            sixdeskmess 1 "Trans $Runnam $Rundir, k=$kk"
        fi
        sixdeskmess 1

	# ----------------------------------------------------------------------
	if ${lfix} ; then
	# ----------------------------------------------------------------------

	    sixdeskmess -1 "Analysing and fixing dir $RundirFullPath"
	    # fix dir
	    fixDir $RundirFullPath $actualDirNameFullPath
	    let __iFixed+=$?
	    # finalise generation of fort.3
	    submitCreateFinalFort3Short $kk
	    # fix input files
	    fixInputFiles $RundirFullPath
	    let __iFixed+=$?
	    if [ $__iFixed -ne 0 ] ; then
		let NsuccessFix+=1
	    fi
	    
	# ----------------------------------------------------------------------
	elif ${lstatus} ; then
        # ----------------------------------------------------------------------

	    checkDirStatus
	    let NsuccessSts+=1
	    
	# ----------------------------------------------------------------------
	else
	# ----------------------------------------------------------------------
	    
	    # ------------------------------------------------------------------
	    if ${lgenerate} ; then
	    # ------------------------------------------------------------------
	        if ${lselected} ; then
	    	    checkDirAlreadyRun >/dev/null 2>&1
	    	    if [ $? -eq 0 ] ; then
	    		checkDirReadyForSubmission >/dev/null 2>&1
	    		if [ $? -gt 0 ] ; then
	    		    sixdeskmess  1 "$RundirFullPath NOT ready for submission - regenerating the necessary input files!"
	    		    __lGenerate=true
	    		fi
	    	    fi
	        else
	    	    __lGenerate=true
	        fi
	    
	        if ${__lGenerate} ; then
	        
   	    	    # create rundir
	    	    submitCreateRundir $RundirFullPath $actualDirNameFullPath
	    
	    	    # finalise generation of fort.3
		    submitCreateFinalFort3Short $kk
	    	
	    	    # final preparation of all SIXTRACK files
	    	    # NB: for boinc, it returns workunitName
	    	    submitCreateFinalInputs
		    if [ $? -ne 0 ] ; then
			sixdeskmess  1 "Carrying on with next WU"
			continue
		    fi
	    	
	    	    # sussix input files
	    	    if [ $sussix -eq 1 ] ; then
	    		for tmpI in $(seq 1 3) ; do
	    		    cp $sixdeskjobs_logs/sussix.inp.$tmpI.gz $RundirFullPath
	    		done
	    	    fi
	        
	    	    # submission file
	    	    if [ $kk -eq 0 ] ; then
	    		sed -e 's?SIXJOBNAME?'$Runnam'?g' \
	    		    -e 's?SIXJOBDIR?'$Rundir'?g' \
	    		    -e 's?SIXTRACKDIR?'$sixdesktrack'?g' \
	    		    $sixdeskjobs_logs/${lsfjobtype}0.sh > $RundirFullPath/$Runnam.sh
	    	    else
	    		sed -e 's?SIXJOBNAME?'$Runnam'?g' \
	    		    -e 's?SIXJOBDIR?'$Rundir'?g' \
	    		    -e 's?SIXTRACKDIR?'$sixdesktrack'?g' \
	    		    $sixdeskjobs_logs/${lsfjobtype}.sh > $RundirFullPath/$Runnam.sh
	    	    fi
	    	    chmod 755 $RundirFullPath/$Runnam.sh

		    let NsuccessGen+=1
	        fi
	    fi
	    
	    # ------------------------------------------------------------------
	    if ${lcheck} ; then
            # ------------------------------------------------------------------
	        if ${lselected} && ! ${__lGenerate} ; then
	    	    checkDirAlreadyRun
	    	    __eCheckDirAlreadyRun=$?
	        fi
	        if ! ${lselected} || [ $__eCheckDirAlreadyRun -eq 0 ] ; then
	    	    checkDirReadyForSubmission
	    	    __eCheckDirReadyForSubmission=$?
	        fi
	        if [ $__eCheckDirReadyForSubmission -gt 0 ] ; then
	    	    sixdeskmess -1 "$RundirFullPath NOT ready for submission!"
	        elif [ $__eCheckDirAlreadyRun -gt 0 ] ; then
  	    	    # sensitive to jobs already run/submitted
	    	    sixdeskmess  1 "-> no need to submit: already submitted/finished!"
	        else
	    	    __lSubmit=true
	    	    sixdeskmess  1 "$RundirFullPath ready to submit!"
	        fi
		let NsuccessChk+=1
	    fi
	    
	    # ------------------------------------------------------------------
	    if ${lsubmit} ; then
	    # ------------------------------------------------------------------
	        if ${__lSubmit} ; then
                    # clean, in case
		    dot_clean
		    touch $RundirFullPath/JOB_NOT_YET_STARTED
		    # actually submit
	    	    dot_bsub
		    local __subSuccess=$?
		    if [ ${__subSuccess} -eq 0 ] ; then
			let NsuccessSub+=1
		    fi
	        else
	    	    sixdeskmess -1 "No submission!"
		    echo 
	        fi
	    fi

	# ----------------------------------------------------------------------
	fi
	# ----------------------------------------------------------------------
	
    done

}

function treatLong(){

    if (( $(echo "${lReduceAngsWithAmplitude} > 0 "|bc -l) )) ; then 
        ampl_index=0
    fi
    # ==========================================================================
    for (( iAmple=0; iAmple<${#allAmplitudeSteps[@]}; iAmple++ )) ; do
    # ==========================================================================

	Ampl=${allAmplitudeSteps[${iAmple}]}
	fampstart=${fAmpStarts[${iAmple}]}
	fampend=${fAmpEnds[${iAmple}]}

	if ${lrestart} && ${lrestartAmpli} ; then
	    if [ "${amplisFromName}" == "${Ampl}" ] ; then
 		lrestartAmpli=false
	    else
		continue
	    fi
	fi

	# separate output for current case from previous one
	echo ""
	echo ""

        sixdeskmess -1 "Considering amplitude step: $Ampl"

        if (( $(echo "${lReduceAngsWithAmplitude} > 0 "|bc -l) )) ; then 
            KKs_reduced=""
            Angles_reduced=""
            kAngs_reduced=""
            while [ "${KKs_ampl[${ampl_index}]}" == "${iAmple}" ]	
            do
              KKs_reduced="${KKs_reduced} ${KKs[$ampl_index]}"
              Angles_reduced="${Angles_reduced} ${Angles[$ampl_index]}"
              kAngs_reduced="${kAngs_reduced} ${kAngs[$ampl_index]}"
              ampl_index=$[$ampl_index+1]
             done
	    kksLoop=${KKs_reduced[@]}
	    anglesLoop=${Angles_reduced[@]}
	    kangsLoop=${kAngs_reduced[@]}
        else       
	    kksLoop=${KKs[@]}
 	    anglesLoop=${Angles[@]}
	    kangsLoop=${kAngs[@]}
        fi      
	kksLoop=( ${kksLoop} )
	anglesLoop=( ${anglesLoop} )
	kangsLoop=( ${kangsLoop} )

	# ======================================================================
	for (( iAngle=0; iAngle<${#kksLoop[@]}; iAngle++ )) ; do
	# ======================================================================

	    # trigger for preparation
	    local __lGenerate=false
	    # trigger for submission
	    local __lSubmit=false
	    # exit status: dir ready for submission
	    local __eCheckDirReadyForSubmission=0
	    # exit status: dir already run
	    local __eCheckDirAlreadyRun=0
	    # fixing dir
	    local __iFixed=0

	    # kk, Angle and kang
	    kk=${kksLoop[${iAngle}]}
	    Angle=${anglesLoop[${iAngle}]}
	    kang=${kangsLoop[${iAngle}]}

	    if ${lrestart} && ${lrestartAngle} ; then
	        if [ "${angleFromName}" == "${Angle}" ] ; then
	            lrestartAngle=false
	            if ${lrestartLast} ; then
	        	# -R LAST
	        	continue
	            fi
	        else
	            continue
	        fi
	    fi

	    let nConsidered+=1

	    # get dirs for this point in scan (returns Runnam, Rundir, actualDirName)
	    sixdeskDefinePointTree $LHCDesName $iMad "s" $sixdesktunes $Ampl $turnsle $Angle $kk $sixdesktrack
	    if [ $? -gt 0 ] ; then
	        # go to next WU (sixdeskmess already printed out and email sent to user/admins)
	        continue
	    fi

	    # separate output for current case from previous one
	    if ! ${lquiet}; then
	        echo ""
	    fi
	    sixdeskmess  1 "Point in scan $Runnam $Rundir"
	    sixdeskmess -1 "study: ${LHCDescrip} - Job: ${nConsidered}/${iTotal} - Seed: $iMad [${iMadStart}:${iend}] - Ampl: $Ampl - Angle: $Angle"
	    
	    # ----------------------------------------------------------------------
	    if ${lfix} ; then
            # ----------------------------------------------------------------------

	        # fix dir
	        fixDir $RundirFullPath $actualDirNameFullPath
	        let __iFixed+=$?
	        # finalise generation of fort.3
	        submitCreateFinalFort3Long
	        # fix input files
	        fixInputFiles $RundirFullPath
	        let __iFixed+=$?
	        if [ $__iFixed -ne 0 ] ; then
	            let NsuccessFix+=1
	        fi
	    
	    # ----------------------------------------------------------------------
	    elif ${lstatus} ; then
            # ----------------------------------------------------------------------

	        checkDirStatus
	        let NsuccessSts+=1
	    
	    # ----------------------------------------------------------------------
	    else
            # ----------------------------------------------------------------------
	    
	        # ------------------------------------------------------------------
	        if ${lgenerate} ; then
  	        # ------------------------------------------------------------------
	            if ${lselected} ; then
	        	checkDirAlreadyRun >/dev/null 2>&1
	        	if [ $? -eq 0 ] ; then
	        	    checkDirReadyForSubmission >/dev/null 2>&1
	        	    if [ $? -gt 0 ] ; then
	        		sixdeskmess  1 "$RundirFullPath NOT ready for submission - regenerating the necessary input files!"
	        		__lGenerate=true
	        	    fi
	        	fi
	            else
	        	__lGenerate=true
	            fi
	            
	            if ${__lGenerate} ; then
	        	
	        	# create rundir
	        	submitCreateRundir $RundirFullPath $actualDirNameFullPath
	        	
	        	# finalise generation of fort.3
	        	multipleTrials "submitCreateFinalFort3Long; local __exit_status=\$?" "[ \${__exit_status} -eq 0 ]" "Failing to generate a proper fort.3"
	        	if [ $? -ne 0 ] ; then
	        	    sixdeskmess  1 "Carrying on with next WU"
	        	    continue
	        	fi
	        	
	        	# final preparation of all SIXTRACK files
	        	# NB: for boinc, it returns workunitName
	        	submitCreateFinalInputs
	        	if [ $? -ne 0 ] ; then
	        	    sixdeskmess  1 "Carrying on with next WU"
	        	    continue
	        	fi
	        	
	        	if [ "$sixdeskplatform" == "lsf" ] ; then
	        	    # submission file
	        	    sed -e 's?SIXJOBNAME?'$Runnam'?g' \
	        		-e 's?SIXJOBDIR?'$Rundir'?g' \
	        		-e 's?SIXTRACKDIR?'$sixdesktrack'?g' \
	        		-e 's?SIXTRACKEXE?'$SIXTRACKEXE'?g' \
	        		-e 's?SIXCASTOR?'$sixdeskcastor'?g' ${SCRIPTDIR}/templates/lsf/${lsfjobtype}.sh > $RundirFullPath/$Runnam.sh
	        	    chmod 755 $RundirFullPath/$Runnam.sh
	        	fi
	        	let NsuccessGen+=1
	            fi
	        fi
	        
	        # ------------------------------------------------------------------
	        if ${lcheck} ; then
	        # ------------------------------------------------------------------
	            if ${lselected} && ! ${__lGenerate} ; then
	        	checkDirAlreadyRun
	        	__eCheckDirAlreadyRun=$?
	            fi
	            if ! ${lselected} || [ $__eCheckDirAlreadyRun -eq 0 ] ; then
	        	checkDirReadyForSubmission
	        	__eCheckDirReadyForSubmission=$?
	            fi
	            if [ $__eCheckDirReadyForSubmission -gt 0 ] ; then
	        	sixdeskmess -1 "$RundirFullPath NOT ready for submission!"
	            elif [ $__eCheckDirAlreadyRun -gt 0 ] ; then
	        	# sensitive to jobs already run/submitted
	        	sixdeskmess  1 "-> no need to submit: already submitted/finished!"
	            else
	        	__lSubmit=true
	        	sixdeskmess  1 "$RundirFullPath ready to submit!"
	            fi
	            let NsuccessChk+=1
	        fi
	        
	        # ------------------------------------------------------------------
	        if ${lsubmit} ; then
	        # ------------------------------------------------------------------
	            if ${__lSubmit} ; then
                        # clean, in case
	        	dot_clean
	        	touch $RundirFullPath/JOB_NOT_YET_STARTED
	        	if [ "$sixdeskplatform" == "lsf" ] ; then
	        	    dot_bsub
	        	    local __subSuccess=$?
	        	elif [ "$sixdeskplatform" == "htcondor" ] ; then
	        	    dot_htcondor
	        	    local __subSuccess=1
	        	    let nQueued+=1
	        	    if  [ $((${nQueued}%${nMaxJobsSubmitHTCondor})) -eq 0 ] ; then
	        		condor_sub
	        	    fi
	        	elif [ "$sixdeskplatform" == "boinc" ] ; then
	        	    dot_boinc
	        	    local __subSuccess=$?
	        	fi
	        	if [ ${__subSuccess} -eq 0 ] ; then
	        	    let NsuccessSub+=1
	        	fi
	            else
	        	sixdeskmess -1 "No submission!"
	            fi
	        fi
	        
	        # ------------------------------------------------------------------
	        if ${lcleanzip} ; then
	        # ------------------------------------------------------------------
	            if ! ${lmegazip} ; then
	        	dot_cleanZips $RundirFullPath $workunitname.zip $workunitname.desc
	            fi
	        fi

	        # ------------------------------------------------------------------
	        # renew kerberos ticket (long submissions)
	        # ------------------------------------------------------------------
	        if ${lfix} && [ $((${NsuccessGen}%${NrenewKerberos})) -eq 0 ] && [ ${NsuccessGen} -ne 0 ] ; then
	            sixdeskmess 2 "renewing kerberos token: ${NsuccessGen} vs ${NrenewKerberos}"
	            sixdeskRenewKerberosToken
	        elif ${lstatus} && [ $((${NsuccessSts}%${NrenewKerberos})) -eq 0 ] && [ ${NsuccessSts} -ne 0 ] ; then
	            sixdeskmess 2 "renewing kerberos token: ${NsuccessSts} vs ${NrenewKerberos}"
	            sixdeskRenewKerberosToken
	        elif ${lgenerate} && [ $((${NsuccessFix}%${NrenewKerberos})) -eq 0 ] && [ ${NsuccessFix} -ne 0 ] ; then
	            sixdeskmess 2 "renewing kerberos token: ${NsuccessFix} vs ${NrenewKerberos}"
	            sixdeskRenewKerberosToken
	        elif ${lcheck} && [ $((${NsuccessChk}%${NrenewKerberos})) -eq 0 ] && [ ${NsuccessChk} -ne 0 ] ; then
	            sixdeskmess 2 "renewing kerberos token: ${NsuccessChk} vs ${NrenewKerberos}"
	            sixdeskRenewKerberosToken
	        elif ${lsubmit} && [ $((${NsuccessSub}%${NrenewKerberos})) -eq 0 ] && [ ${NsuccessSub} -ne 0 ] ; then
	            sixdeskmess 2 "renewing kerberos token: ${NsuccessSub} vs ${NrenewKerberos}"
	            sixdeskRenewKerberosToken
	        fi
	        
	    # ----------------------------------------------------------------------
	    fi
	    # ----------------------------------------------------------------------
	
        done
	# end of loop over angles
    done
    # end of loop over amplitudes
}

function treatDA(){
    Angle=0
    kk=0
    
    let nConsidered+=1
    # fixing dir
    local __iFixed=0
    
    # get dirs for this point in scan (returns Runnam, Rundir, actualDirName)
    sixdeskDefinePointTree $LHCDesName $iMad "d" $sixdesktunes $Ampl "0" $Angle $kk $sixdesktrack
    if [ $? -gt 0 ] ; then
	# go to next WU (sixdeskmess already printed out and email sent to user/admins)
	return
    fi

    # ----------------------------------------------------------------------
    if ${lfix} ; then
    # ----------------------------------------------------------------------
	
	sixdeskmess -1 "Analysing and fixing dir $RundirFullPath"
	# fix dir
	fixDir $RundirFullPath $actualDirNameFullPath
	let __iFixed+=$?
	# finalise generation of fort.3
	submitCreateFinalFort3DA
	# fix input files
	fixInputFiles $RundirFullPath
	let __iFixed+=$?
	if [ $__iFixed -ne 0 ] ; then
	    let NsuccessFix+=1
	fi
	    
    # ----------------------------------------------------------------------
    elif ${lstatus} ; then
    # ----------------------------------------------------------------------

	checkDirStatus
	let NsuccessSts+=1
	    
    # ----------------------------------------------------------------------
    else
    # ----------------------------------------------------------------------
        if ${lgenerate} ; then
            # does rundir exist?
            submitCreateRundir $RundirFullPath $actualDirNameFullPath
            
            # finalise generation of fort.3
            submitCreateFinalFort3DA
            
            # final preparation of all SIXTRACK files
            # NB: for boinc, it returns workunitName
            submitCreateFinalInputs
	    if [ $? -ne 0 ] ; then
		sixdeskmess  1 "Carrying on with next WU"
		return
	    fi
            
            # submission file
            sed -e 's?SIXJOBNAME?'"$Runnam"'?g' \
                -e 's?SIXTRACKDAEXE?'$SIXTRACKDAEXE'?g' \
                -e 's?SIXJOBDIR?'$Rundir'?g' \
                -e 's?SIXTRACKDIR?'$sixdesktrack'?g' \
                -e 's?SIXJUNKTMP?'$sixdeskjobs_logs'?g' $sixdeskhome/utilities/${lsfjobtype}.sh > $sixdeskjobs_logs/$Runnam.sh
            chmod 755 $sixdeskjobs_logs/$Runnam.sh
	    let NsuccessGen+=1
        fi
        if ${lsubmit} ; then
            # clean, in case
	    dot_clean
	    touch $RundirFullPath/JOB_NOT_YET_STARTED
            # actually submit
            dot_bsub
	    local __subSuccess=$?
	    if [ ${__subSuccess} -eq 0 ] ; then
		let NsuccessSub+=1
	    fi
        fi

    # ----------------------------------------------------------------------
    fi
    # ----------------------------------------------------------------------
}

function printSummary(){
    if ${lfix} ; then
	sixdeskmess -1 "FIXED          ${NsuccessFix} directories"
    fi
    if ${lgenerate} ; then
	sixdeskmess -1 "GENERATED      ${NsuccessGen} directories"
    fi
    if ${lcheck} ; then
	sixdeskmess -1 "CHECKED        ${NsuccessChk} directories"
    fi
    if ${lsubmit} ; then
	sixdeskmess -1 "SUBMITTED      ${NsuccessSub} jobs"
    fi
    if ${lstatus} ; then
	sixdeskmess -1 "STATUS LISTED  ${NsuccessSts} jobs"
    fi
    sixdeskmess -1 "CONSIDERED     ${nConsidered} jobs"
}

# ==============================================================================
# main
# ==============================================================================

# ------------------------------------------------------------------------------
# preliminary to any action
# ------------------------------------------------------------------------------
# - get path to scripts (normalised)
if [ -z "${SCRIPTDIR}" ] ; then
    SCRIPTDIR=`dirname $0`
    SCRIPTDIR="`cd ${SCRIPTDIR};pwd`"
    export SCRIPTDIR=`dirname ${SCRIPTDIR}`
fi
# ------------------------------------------------------------------------------

# actions and options
lgenerate=false
lcheck=false
lsubmit=false
lstatus=false
lfix=false
lcleanzip=false
lselected=false
lmegazip=false
loutform=false
lbackcomp=true
lverbose=false
lrestart=false
lrestartLast=false
lincomplete=false
lunlockRun6T=false
lFinaliseHTCondor=false
unlockSetEnv=""
restartPoint=""
currPlatform=""
currStudy=""
optArgCurrStudy="-s"
optArgCurrPlatForm=""
doNotOverwrite=""
verbose=""
sixdeskplatformDefIncomplete="htcondor"
currPythonPath=""
NrenewKerberosDef=10000
NrenewKerberos=${NrenewKerberosDef}
nMaxJobsSubmitHTCondorDef=15000
nMaxJobsSubmitHTCondor=${nMaxJobsSubmitHTCondorDef}

# get options (heading ':' to disable the verbose error handling)
while getopts  ":hgo:sctakfvBSCMid:p:R:P:n:N:wU" opt ; do
    case $opt in
	a)
	    # do everything
	    lgenerate=true
	    lcheck=true
	    lsubmit=true
	    lcleanzip=true
	    ;;
	c)
	    # check only
	    lcheck=true
	    ;;
	o)
	    # output option
	    check_output_option
	    ;;	
	h)
	    how_to_use
	    exit 1
	    ;;
	g)
	    # generate simulation files
	    lgenerate=true
	    # check
	    lcheck=true
	    ;;
	s)
	    # check
	    lcheck=true
	    # submit
	    lsubmit=true
	    # clean .zip/.desc
	    lcleanzip=true
	    ;;
	S)
	    # selected points of scan only
	    lselected=true
	    ;;
	R)
	    # restart from point in scan
	    lrestart=true
	    restartPoint="${OPTARG}"
	    ;;
	f)
	    # fix directories
	    lfix=true
	    ;;
	C)
	    # the user requests to delete .zip/.desc files
	    #   after submission with boinc
	    lcleanzip=true
	    ;;
	M)
	    # submission to boinc through MegaZip
	    lmegazip=true
	    ;;
	i)
	    # submit incomplete cases only
	    lincomplete=true
	    # disable generation
	    lgenerate=false
	    # disable check
	    lcheck=false
	    # submit
	    lsubmit=true
	    ;;
	B)
	    # use whatever breaks backward compatibility
	    lbackcomp=false
	    ;;
	d)
	    # the user is requesting a specific study
	    currStudy="${OPTARG}"
	    ;;
	p)
	    # the user is requesting a specific platform
	    currPlatform="${OPTARG}"
	    ;;
	t)
	    # status
	    lstatus=true
	    ;;
	P)
	    # the user is requesting a specific path to python
	    currPythonPath="-P ${OPTARG}"
	    ;;
	n)
	    # renew kerberos token every N jobs
	    NrenewKerberos=${OPTARG}
	    # check it is actually a number
	    let NrenewKerberos+=0
	    if [ $? -ne 0 ] 2>/dev/null; then
		how_to_use
		echo "-n argument option is not a number!"
		exit 1
	    fi
	    ;;
	N)
	    # max number of jobs per HTCondor cluster
	    nMaxJobsSubmitHTCondor=${OPTARG}
	    # check it is actually a number
	    let nMaxJobsSubmitHTCondor+=0
	    if [ $? -ne 0 ] 2>/dev/null; then
		how_to_use
		echo "-N argument option is not a number!"
		exit 1
	    fi
	    ;;
	v) 
	    # verbose
	    lverbose=true
	    ;;
	w)
	    # submit any .list left behind
	    lFinaliseHTCondor=true
	    ;;
	U)
	    # unlock currently locked folder
	    lunlockRun6T=true
	    unlockSetEnv="-U"
	    ;;
	:)
	    how_to_use
	    echo "Option -$OPTARG requires an argument."
	    exit 1
	    ;;
	\?)
	    how_to_use
	    echo "Invalid option: -$OPTARG"
	    exit 1
	    ;;
    esac
done
shift "$(($OPTIND - 1))"
# user's request
# - actions
if ! ${lgenerate} && ! ${lsubmit} && ! ${lcheck} && ! ${lstatus} && ! ${lcleanzip} && ! ${lfix} && ! ${lincomplete} && ! ${lunlockRun6T} && ! ${lFinaliseHTCondor} ; then
    how_to_use
    echo "No action specified!!! aborting..."
    exit 1
fi
if ${lunlockRun6T} && ! ${lgenerate} && ! ${lsubmit} && ! ${lcheck} && ! ${lstatus} && ! ${lcleanzip} && ! ${lfix} && ! ${lincomplete} && ! ${lFinaliseHTCondor} ; then
    # only unlocking -> set_env.sh should not overwrite sixdeskenv/sysenv anyway
    doNotOverwrite="-e"
fi
# - options
if [ -n "${currStudy}" ] ; then
    optArgCurrStudy="-d ${currStudy}"
    doNotOverwrite="-e"
fi
if [ -n "${currPlatform}" ] ; then
    optArgCurrPlatForm="-p ${currPlatform}"
fi
if ${lverbose} ; then
    verbose="-v"
fi
if ${lincomplete} ; then
    optArgCurrPlatForm="-p ${sixdeskplatformDefIncomplete}"
    echo "-i action forces platform to ${sixdeskplatformDefIncomplete}"
fi
if ${lFinaliseHTCondor} ; then
    optArgCurrPlatForm="-p ${sixdeskplatformDefIncomplete}"
    echo "-w action forces platform to ${sixdeskplatformDefIncomplete}"
fi
if ${lincomplete} && ${lselected} ; then
    echo "-S option and -i action are incompatible!"
    exit 1
fi

# ------------------------------------------------------------------------------
# preparatory steps
# ------------------------------------------------------------------------------

# - load environment
#   NB: workaround to get getopts working properly in sourced script
OPTIND=1
echo ""
printf "=%.0s" {1..80}
echo ""
echo "--> sourcing set_env.sh"
printf '.%.0s' {1..80}
echo ""
source ${SCRIPTDIR}/bash/set_env.sh ${optArgCurrStudy} ${optArgCurrPlatForm} ${verbose} ${currPythonPath} ${unlockSetEnv} ${doNotOverwrite}
printf "=%.0s" {1..80}
echo ""
echo ""
# - settings for sixdeskmessages
if ${loutform} ; then
    sixdesklevel=${sixdesklevel_option}
fi

# - action-dependent stuff
echo ""
if ${lfix} ; then
    #
    sixdeskmess -1 "Fixing sixtrack input files for study $LHCDescrip"
    #
    lockingDirs=( "$sixdeskstudy" "$sixdeskjobs_logs" )
    #
    sixdeskmess  2 "Using sixtrack_input ${sixtrack_input}"
    sixdeskmess  2 "Using ${sixdeskjobs_logs}"
fi
if ${lgenerate} ; then
    #
    sixdeskmess -1 "Preparing sixtrack input files for study $LHCDescrip"
    #
    lockingDirs=( "$sixdeskstudy" "$sixdeskjobs_logs" )
    #
    sixdeskmess  2 "Using sixtrack_input ${sixtrack_input}"
    sixdeskmess  2 "Using ${sixdeskjobs_logs}"
fi
if ${lcheck} ; then
    #
    sixdeskmess  1 "Checking that all sixtrack input files for study $LHCDescrip are there"
    #
    lockingDirs=( "$sixdeskstudy" "$sixdeskjobs_logs" )
    #
    sixdeskmess  2 "Using sixtrack_input ${sixtrack_input}"
    sixdeskmess  2 "Using ${sixdeskjobs_logs}"
fi
if ${lsubmit} ; then
    #
    sixdeskmess  1 "Submitting sixtrack input files for study $LHCDescrip"
    #
    lockingDirs=( "$sixdeskstudy" "$sixdeskjobs_logs" )
    #
    sixdeskmess  2 "Using sixtrack_input ${sixtrack_input}"
    sixdeskmess  2 "Using ${sixdeskjobs_logs}"
    #
    # verify queue type
    sixdeskSetQueue lsfq HTCq
fi
if ${lstatus} ; then
    #
    sixdeskmess -1 "Checking status of study $LHCDescrip"
    #
    lockingDirs=( "$sixdeskstudy" )
    #
    # initialise some counters:
    # - actually found:
    nFound=( 0 0 0 0 0 0 )
    foundNames=( 'dirs' 'fort.2.gz' 'fort.3.gz' 'fort.8.gz' 'fort.16.gz' 'fort.10.gz' )
fi

# - unlocking
if ${lunlockRun6T} ; then
    sixdeskunlockAll
    if ! ${lgenerate} && ! ${lsubmit} && ! ${lcheck} && ! ${lstatus} && ! ${lcleanzip} && ! ${lfix} && ! ${lincomplete} && ! ${lFinaliseHTCondor} ; then
	sixdeskmess -1 "requested only unlocking. Exiting..."
	exit 0
    fi
fi

nQueued=0 # for limiting number of jobs in HTCondor cluster
nConsidered=0
NsuccessFix=0
NsuccessGen=0
NsuccessChk=0
NsuccessSub=0
NsuccessSts=0
echo ""

# - temporary trap
trap "sixdeskexit 199" EXIT

# - option specific stuff
#   . megaZip available only in case of boinc:
if ${lmegazip} && [ "$sixdeskplatform" != "boinc" ] ; then
    lmegazip=false
fi
#   . clean up of zip files only in case of boinc:
if ${lcleanzip} && [ "$sixdeskplatform" != "boinc" ] ; then
    lcleanzip=false
fi
#   . break backward compatibility
if ! ${lbackcomp} ; then
    sixdeskmess  2 " --> flag for backward compatibility de-activated, as requested by user!"
fi
#   . restart action
lrestartTune=false
lrestartAmpli=false
lrestartAngle=false

# - define user tree
sixdeskDefineUserTree $basedir $scratchdir $workspace

# - boinc variables
sixDeskSetBOINCVars

# - preliminary checks
preliminaryChecksRS
if [ $? -gt 0 ] ; then
    exit
fi

# - square hard-coded?!
square=0

# - status error
__lerr=0

# ------------------------------------------------------------------------------
# actual operations
# ------------------------------------------------------------------------------

# lock dirs
sixdesklockAll

# actual traps
trap "printSummary; sixdeskexit  199" EXIT
trap "printSummary; sixdeskexit  1" SIGINT
trap "printSummary; sixdeskeedt  2" SIGQUIT
trap "printSummary; sixdeskexit 11" SIGSEGV
trap "printSummary; sixdeskexit  8" SIGFPE

# submit any .list left behind
if ${lFinaliseHTCondor} ; then
    condor_sub
    if ! ${lgenerate} && ! ${lsubmit} && ! ${lcheck} && ! ${lstatus} && ! ${lcleanzip} && ! ${lfix} && ! ${lincomplete} ; then
	# only finalise submission
	sixdeskmess -1 "only finalisation of submission"
	trap "" SIGINT SIGQUIT SIGSEGV SIGFPE
	trap "printSummary; sixdeskexit 0" EXIT
	exit
    fi
fi

# preparation to main loop
if ${lgenerate} || ${lfix} ; then
    # - check that all the necessary MadX input is ready
    #   NB: -e option, to skip set_env.sh another time
    echo ""
    printf "=%.0s" {1..80}
    echo ""
    echo "--> local mad6t.sh run"
    printf '.%.0s' {1..80}
    echo ""
    if [ -n "${currStudy}" ] ; then
	${SCRIPTDIR}/bash/mad6t.sh -c -e ${currPythonPath} ${optArgCurrStudy}
    else
	${SCRIPTDIR}/bash/mad6t.sh -c -e ${currPythonPath} 
    fi
    printf "=%.0s" {1..80}
    echo ""
    let __lerr+=$?
    # - these dirs should already exist...
    for tmpDir in $sixdesktrack $sixdeskjobs $sixdeskjobs_logs $sixdesktrackStudy ; do
	[ -d $tmpDir ] || mkdir -p $tmpDir
	sixdeskInspectPrerequisites true $tmpDir -d
	let __lerr+=$?
    done
    # - save emittance and gamma
    echo "$emit  $gamma" > $sixdesktrackStudy/general_input
    let __lerr+=$?
    # - set up of fort.3
    for tmpFile in fort.3.mad fort.3.mother1 fort.3.mother2 ; do
	cp ${sixtrack_input}/${tmpFile} $sixdeskjobs_logs
	if [ $? -ne 0 ] ; then
	    sixdeskmess -1 "unable to copy ${sixtrack_input}/${tmpFile} to $sixdeskjobs_logs"
	    let __lerr+=1
	fi
    done
    # - set CHROVAL and TUNEVAL
    if [ $chrom -eq 0 ] ; then
        CHROVAL='/'
    else
        CHROVAL=''
    fi
    if [ $tune -eq 0 ] ; then
	TUNEVAL='/'
    else
	TUNEVAL=''
    fi
    preProcessFort3
    let __lerr+=$?
    # - specific to type of run
    if [ $short -eq 1 ] ; then
	preProcessShort
	let __lerr+=$?
    elif [ $da -eq 1 ] ; then
	preProcessDA
	let __lerr+=$?
    fi
    # - specific to running platform
    if [ "$sixdeskplatform" == "boinc" ] ; then
	preProcessBoinc
	let __lerr+=$?
    fi
    # - in case of errors, interrupt execution
    if [ $__lerr -gt 0 ] ; then
        sixdeskmess -1 "Preparatory step failed - error: ${__lerr}."
	exit
    fi
fi
if ${lcheck} ; then
    # - general_input
    sixdeskInspectPrerequisites true $sixdesktrackStudy -s general_input
    let __lerr+=$?
    # - preProcessFort3
    sixdeskInspectPrerequisites true ${sixdeskjobs_logs} -s fort0.3.mask forts.3.mask fortl.3.mask fortda.3.mask
    let __lerr+=$?
    if [ $short -eq 1 ] ; then
	if [ $sussix -eq 1 ] ; then
	    sixdeskInspectPrerequisites true ${sixdeskjobs_logs} -s sussix.tmp.1 sussix.tmp.2 sussix.tmp.3
	    let __lerr+=$?
	    echo $__lerr
	fi
	sixdeskInspectPrerequisites true ${sixdeskjobs_logs} -s ${lsfjobtype}.sh ${lsfjobtype}0.sh
	let __lerr+=$?
    elif [ $da -eq 1 ] ; then
	sixdeskInspectPrerequisites true ${sixdeskjobs_logs} -s dalie.data dalie.input dalie reson.data readda
	let __lerr+=$?
    fi
    if [ "$sixdeskplatform" == "boinc" ] ; then
	# - existence of dirs
	sixdeskInspectPrerequisites true $sixdeskboincdir -d
	if [ $? -gt 0 ] ; then
	    let __lerr+=1
	else
	    for tmpDir in $sixdeskboincdir/work $sixdeskboincdir/results ; do
		sixdeskInspectPrerequisites true $tmpDir -d
		let __lerr+=$?
	    done
	    # - check of ownership
	    sixdeskInspectPrerequisites true $sixdeskboincdir -s owner
	    if [ $? -gt 0 ] ; then
		let __lerr+=1
	    else
		tmpOwner=`cat $sixdeskboincdir/owner`
		if [ "${tmpOwner}" != "$LOGNAME" ] ; then
		    sixdeskmess -1 "Err of ownership of $sixdeskboincdir: ${tmpOwner} (expected: $LOGNAME)"
		    let __lerr+=1
		else
		    # - check acl rights
		    aclRights=`fs listacl $sixdeskboincdir | grep $LOGNAME 2> /dev/null | awk '{print ($2)}'`
		    if [ "$aclRights" != "rlidwka" ] ; then
			sixdeskmess -1 "Err of acl rights on $sixdeskboincdir for $LOGNAME: ${aclRights} (expected: rlidwka)"
			let __lerr+=1
		    fi
		    aclRights=`fs listacl $sixdeskboincdir | grep boinc:users 2> /dev/null | awk '{print ($2)}'`
		    if [ "$aclRights" != "rl" ] ; then
			sixdeskmess -1 "Err of acl rights on $sixdeskboincdir for boinc:users ${aclRights} (expected: rl)"
			let __lerr+=1
		    fi
		fi
	    fi
	fi
	# - MegaZip:
	if ${lmegazip} ; then
	    sixdeskInspectPrerequisites true ${sixdeskjobs_logs} -s megaZipName.txt
	    if [ $? -gt 0 ] ; then
		let __lerr+=1
	    fi
	fi
    fi
    if [ ${__lerr} -gt 0 ] ; then
        sixdeskmess -1 "Preparation incomplete - error:  ${__lerr}."
	exit
    fi
fi
# - echo emittance and dimsus
factor=`gawk 'END{fac=sqrt('$emit'/'$gamma');print fac}' /dev/null`
dimsus=`gawk 'END{dimsus='$dimen'/2;print dimsus}' /dev/null` 
sixdeskmess  1 "factor $factor - dimsus $dimsus"
# - touch some files related to monitoring of submission of jobs
if ${lsubmit} ; then
    touch $sixdeskwork/completed_cases
    touch $sixdeskwork/mycompleted_cases
    touch $sixdeskwork/incomplete_cases
    touch $sixdeskwork/myincomplete_cases
    touch $sixdeskwork/taskids
    if [ "$sixdeskplatform" == "lsf" ] || [ "$sixdeskplatform" == "htcondor" ] ; then
	touch $sixdeskjobs/jobs
	touch $sixdeskjobs/incomplete_jobs
    elif [ "$sixdeskplatform" == "boinc" ] ; then
	touch $sixdeskjobs/tasks
	touch $sixdeskjobs/incomplete_tasks
    fi
fi
# - preparatory steps for submission to htcondor:
if ${lsubmit} ; then
    if [ "$sixdeskplatform" == "htcondor" ] ; then
	# clean away any existing .list, to avoid double submissions
	if [ -e ${sixdeskjobs}/${LHCDesName}.list ] ; then
	    sixdeskmess -1 "cleaning away existing ${sixdeskjobs}/${LHCDesName}.list to avoid double submissions!"
	    rm -f ${sixdeskjobs}/${LHCDesName}.list
	fi
	cp ${SCRIPTDIR}/templates/htcondor/htcondor_job.sh ${sixdeskjobs}/htcondor_job.sh
	cp ${SCRIPTDIR}/templates/htcondor/htcondor_run_six.sub ${sixdeskjobs}/htcondor_run_six.sub
	# some set up of htcondor submission scripts
 	sed -i "s#^exe=.*#exe=${SIXTRACKEXE}#g" ${sixdeskjobs}/htcondor_job.sh
	sed -i "s#^runDirBaseName=.*#runDirBaseName=${sixdesktrack}#g" ${sixdeskjobs}/htcondor_job.sh
	chmod +x ${sixdeskjobs}/htcondor_job.sh
	sed -i "s#^executable = .*#executable = ${sixdeskjobs}/htcondor_job.sh#g" ${sixdeskjobs}/htcondor_run_six.sub
	sed -i "s#^queue dirname from.*#queue dirname from ${sixdeskjobs}/${LHCDesName}.list#g" ${sixdeskjobs}/htcondor_run_six.sub
	sed -i "s#^+JobFlavour =.*#+JobFlavour = \"${HTCq}\"#g" ${sixdeskjobs}/htcondor_run_six.sub
    fi
fi
# - MegaZip: get file name
if ${lmegazip} ; then
    # get name of zip as from initialisation
    megaZipName=`cat ${sixdeskjobs_logs}/megaZipName.txt`
fi
# - restart action
if ${lrestart} ; then
    if [ `echo "${restartPoint}" | tr [a-z] [A-Z]` == "LAST" ] ; then
	restartPoint=`tail -1 $sixdeskwork/taskids 2> /dev/null | awk '{print ($1)}'`
	if [ -z "${restartPoint}" ] ; then
	    sixdeskmess -1 "file $sixdeskwork/taskids not present or empty"
	fi
	lrestartLast=true
	sixdeskmess 1 "Last point with successful submission: ${restartPoint}"
	sixdeskmess 1 " as from $sixdeskwork/taskids"
    fi
    sixdeskCheckNFieldsFromJobName "${restartPoint}"
    exitStatus=$?
    if [ ${exitStatus} -ne 0 ] ; then
	sixdeskmess 1 "error: ${exitStatus}"
	exit
    fi
    # get infos of starting point
    sixdeskSmashJobName "${restartPoint}"
    lrestartTune=true
    lrestartAmpli=true
    lrestartAngle=true
fi

# - final set-ups and echo
if ${lincomplete} ; then
    sixdeskmess -1 "re-submitting `cat $sixdeskwork/incomplete_cases | wc -l` incomplete cases"
else
    echo ""
    sixdeskmess -1 "Infos about loop (as from input):"
    let iTotalMad=${iend}-${ista}+1
    sixdeskmess -1 "- MadX seeds: from ${ista} to ${iend} - total: ${iTotalMad} seeds;"
    # - prepare tune scans (including integer part of tune)
    #   it returns tunesXX/YY and inttunesXX/YY as arrays
    sixdeskAllTunes
    sixdeskmess -1 "- Tune values:"
    tunesXString="${tunesXX[@]}"
    sixdeskmess -1 "  . Qx: ${tunesXString}"
    tunesYString="${tunesYY[@]}"
    sixdeskmess -1 "  . Qy: ${tunesYString}"
    if [ -n "${squaredTuneScan}" ] ; then
	lSquaredTuneScan=true
	let iTotalTunes=${#tunesXX[@]}*${#tunesYY[@]}
	sixdeskmess -1 "  --> over a squared domain in (Qx,Qy) - total: ${iTotalTunes} pairs;"
    else
	lSquaredTuneScan=false
	if [ ${#tunesXX[@]} -eq ${#tunesYY[@]} ] ;  then
	    iTotalTunes=${#tunesXX[@]}
	    sixdeskmess -1 "  --> along a line in (Qx,Qy) - total: ${iTotalTunes} pairs;"
	elif [ ${#tunesXX[@]} -lt ${#tunesYY[@]} ] ;  then
	    iTotalTunes=${#tunesXX[@]}
	    sixdeskmess -1 "  --> along a line in (Qx,Qy) - total: ${iTotalTunes} pairs;"
	else
	    iTotalTunes=${#tunesYY[@]}
	    sixdeskmess -1 "  --> along a line in (Qx,Qy) - total: ${iTotalTunes} pairs;"
	fi
    fi
    if [ $long -eq 1 ] ; then
	# generate array of amplitudes (it returns allAmplitudeSteps, fAmpStarts, fAmpEnds, ampstart, ampfinish)
	sixdeskAllAmplitudes
	iTotalAmplitudeSteps=${#allAmplitudeSteps[@]}
	sixdeskmess -1 "- Amplitudes: from $ns1l to $ns2l by $nsincl - total: ${iTotalAmplitudeSteps} amplitude steps;"
	sixdeskAllAngles $kinil $kendl $kmaxl $kstep $ampstart $ampfinish $lbackcomp ${lReduceAngsWithAmplitude} ${totAngle} ${ampFactor}
	iTotalAngles=${#KKs[@]}
	sixdeskmess -1 "- Angles: $kinil, $kendl, $kmaxl by $kstep - total: ${iTotalAngles} angles"
    elif [ $short -eq 1 ] || [ $da -eq 1 ] ; then
	iTotalAmplitudeSteps=1
	sixdeskmess -1 "- Amplitudes: from $ns1s to $ns2s by $nss - total: ${iTotalAmplitudeSteps} amplitude steps;"
	sixdeskAllAngles $kini $kend $kmax $kstep $ampstart $ampfinish $lbackcomp ${lReduceAngsWithAmplitude} ${totAngle} ${ampFactor}
	iTotalAngles=${#KKs[@]}
	sixdeskmess -1 "- Angles: $kini, $kend, $kmax by $kstep - total: ${iTotalAngles} angles"
    fi
    let iTotal=${iTotalMad}*${iTotalTunes}*${iTotalAmplitudeSteps}*${iTotalAngles}
    sixdeskmess -1 "for a total of ${iTotal} points."
fi

# main loop
if ${lincomplete} ; then
    # fill in the list of points to be submitted from $sixdeskwork/incomplete_cases
    while read runnamename ; do
	sixdeskrundir true
	sixdeskSanitizeString "${rundirname}" Rundir
	dot_htcondor
	let nConsidered+=1
	let nQueued+=1
	if  [ $((${nQueued}%${nMaxJobsSubmitHTCondor})) -eq 0 ] ; then
	    condor_sub
	fi
    done < $sixdeskwork/incomplete_cases
else
    if ${lrestart} ; then
        iMadStart=${MADseedFromName}
    else
        iMadStart=${ista}
    fi
    for (( iMad=${iMadStart}; iMad<=$iend; iMad++ )) ; do
        echo ""
        echo ""
        echo ""
        sixdeskmess -1 "MADX seed $iMad"
        if ${lgenerate} || ${lfix} ; then
    	    iForts="2 8 16"
    	    if [ "$fort_34" != "" ] ; then
    		iForts="${iForts} 34"
    	    fi
    	    # required not only by boinc, but also by chroma/beta jobs
    	    for iFort in ${iForts} ; do
    		gunzip -c $sixtrack_input/fort.${iFort}_$iMad.gz > $sixtrack_input/fort.${iFort}
    	    done
        fi
    
	for (( iTuneY=0 ; iTuneY<${#tunesYY[@]} ; iTuneY++ )) ; do
    	    if ${lSquaredTuneScan} ; then
    	        # squared scan: for a value of Qy, explore all values of Qx
    		jmin=0
    		jmax=${#tunesXX[@]}
    	    else
    	        # linear scan: for a value of Qy, run only one value of Qx
    		jmin=$iTuneY
    		let jmax=$jmin+1
    	    fi
	    for (( iTuneX=$jmin; iTuneX<$jmax ; iTuneX++ )) ; do
    		tunexx=${tunesXX[$iTuneX]}
    		tuneyy=${tunesYY[$iTuneY]}
		# generate tune string (dir/job name)
		sixdeskPrepareTunes new
		exitStatus=$?
    		if ${lrestart} && ${lrestartTune} ; then
    		    if [ "${tunesFromName}" == "${sixdesktunes}" ] ; then
    			lrestartTune=false
    		    else
    			continue
    		    fi
    		fi
		if [ $exitStatus -ne 0 ] ; then
		    # go to next tune couple (sixdeskmess already printed out and email sent to user/admins)
		    continue
		fi
		# - int tunes (used in fort.3 for post-processing)
		inttunexx=${inttunesXX[$iTuneX]}
		inttuneyy=${inttunesYY[$iTuneY]}
                #   ...notify user
    		echo ""
    		echo ""
    		sixdeskmess -1 "Tunescan $sixdesktunes"
      	        # - get simul path (storage of beta values), stored in $Rundir (returns Runnam, Rundir, actualDirName)...
    		sixdeskDefinePointTree $LHCDesName $iMad "s" $sixdesktunes "" "" "" "" $sixdesktrack
    		if [ $? -gt 0 ] ; then
    		    # go to next tune values (sixdeskmess already printed out and email sent to user/admins)
    		    continue
    		fi
    	        # - beta values?
    		if [ $short -eq 1 ] || [ $long -eq 1 ] ; then
    	            if ${lgenerate} || ${lfix} ; then
    	    		if [ ! -s ${RundirFullPath}/betavalues ] ; then
    	    		    [ -d $RundirFullPath ] || mkdir -p $RundirFullPath
    	    		    cd $sixdeskjobs_logs
    	    		    if [ $chrom -eq 0 ] ; then
    	    			sixdeskmess  1 "Running two `basename $SIXTRACKEXE` (one turn) jobs to compute chromaticity"
    	    			submitChromaJobs $RundirFullPath
    	    		    else
    	    			sixdeskmess -1 "Using Chromaticity specified as $chromx $chromy"
    	    		    fi
    	    		    sixdeskmess  1 "Running `basename $SIXTRACKEXE` (one turn) to get beta values"
    	    		    submitBetaJob $RundirFullPath
    	    		    cd $sixdeskhome
    	    		fi
    	            fi
    	            if ${lcheck} ; then
    	    	        # checks
    	    		sixdeskInspectPrerequisites ${lverbose} $RundirFullPath -d
    	    		let __lerr+=$?
    	    		if [ $chrom -eq 0 ] ; then
    	    		    sixdeskInspectPrerequisites ${lverbose} $RundirFullPath -s mychrom
    	    		    let __lerr+=$?
    	    		fi
    	    		sixdeskInspectPrerequisites ${lverbose} $RundirFullPath -s betavalues
    	    		let __lerr+=$?
    	    		if [ ${__lerr} -gt 0 ] ; then
    	    		    sixdeskmess -1 "Failure in preparation - error: ${__lerr}}."
    	    		    exit
    	    		fi
    	            fi
    	            parseBetaValues $RundirFullPath
    		fi	    
    		
    	        # Resonance Calculation only
    		N1=0
    		if [ $N1 -gt 0 ] ; then
    	            N2=9
    	            Qx=63.28
    	            Qy=59.31
    	            nsr=10.
    	            Ax=`gawk 'END{Ax='$nsr'*sqrt('$emit'/'$gamma'*'$beta_x');print Ax}' /dev/null`
    	            Ay=`gawk 'END{Ay='$nsr'*sqrt('$emit'/'$gamma'*'$beta_y');print Ay}' /dev/null`
    	            echo "$Qx $Qy $Ax $Ay $N1 $N2" > $sixdeskjobs_logs/resonance
    		fi
    		
    	        # further actions depend on type of job
    		if [ $short -eq 1 ] ; then
    	            treatShort
    		elif [ $long -eq 1 ] ; then
    	            treatLong
    		elif [ $da -eq 1 ] ; then
    	            treatDA
    		fi
    	    done
        done
        if ${lgenerate} || ${lfix} ; then
    	    iForts="2 8 16"
    	    if [ "$fort_34" != "" ] ; then
    		iForts="${iForts} 34"
    	    fi
    	    # required not only by boinc, but also by chroma/beta jobs
    	    for iFort in ${iForts} ; do
    		rm -f $sixtrack_input/fort.${iFort}
    	    done
        fi	    
    done
fi

# restart check
if ${lrestart} ; then
    if ${lrestartTune} || ${lrestartAmpli} || ${lrestartAngle} ; then
	sixdeskmess -1 "Something wrong with restarting the scan from point ${restartPoint}"
	sixdeskmess -1 "Scan was not restarted correctly"
	if ${lrestartTune} ; then
	    sixdeskmess -1 "Starting tune ${tunesFromName} was not properly recognised!"
	fi
	if ${lrestartAmpli} ; then
	    sixdeskmess -1 "Starting amplitude range ${amplisFromName} was not properly recognised!"
	fi
	if ${lrestartAngle} ; then
	    sixdeskmess -1 "Starting angle ${angleFromName} was not properly recognised!"
	fi
	if ${lselected} ; then
	    sixdeskmess -1 "This might be due to the fact that, with -S option, all jobs have been recognised"
	    sixdeskmess -1 "  as not being in the need of submission."
	fi
    fi
fi

# HTCondor: run the actual command
if ${lsubmit} && [ "$sixdeskplatform" == "htcondor" ] && [ $((${nQueued}%${nMaxJobsSubmitHTCondor})) -ne 0 ] ; then
    # submit the remaining jobs
    condor_sub
fi

# megaZip, in case of boinc
if ${lmegazip} ; then
    
    sixdeskInspectPrerequisites ${lverbose} ${sixdeskjobs_logs} -s megaZipList.txt
    let __lerr+=$?
    if [ $__lerr -ne 0 ] ; then
	sixdeskmess -1 "${sixdeskjobs_logs}/megaZipList.txt not generated - error: ${__lerr}."
	exit
    fi
	
    # loop: in case of generation and checking, be nice, and re-generate megaZip file,
    #       if errors are found
    if ${lgenerate} || ${lcheck} ; then
	gotit=false
	for (( mytries=1 ; mytries<=10; mytries++ )) ; do
	    __llerr=0
	    # - generate megaZip file
	    if ${lgenerate} ; then
		# loop until megaZip file is generated
		while true ; do
		    dot_megaZip ${megaZipName} ${sixdeskjobs_logs}/megaZipList.txt
		    if [ $? -ne 0 ] ; then
			sixdeskmess -1 "problems in creating ${megaZipName} - regenerating it..."
		    else
			break
		    fi
		done
	    fi
	    # - check megaZip file
	    if ${lcheck} ; then
		# . check existence of megaZip file
		sixdeskInspectPrerequisites ${lverbose} . -s ${megaZipName}
		let __llerr+=$?
		if [ $__llerr -ne 0 ] ; then
		    sixdeskmess -1 "./${megaZipName} not generated!"
		else
		    sixdeskmess  1 "checking megaZip file..."
		    # . check that all the expected files are in megaZip
		    while read tmpFileName ; do
			tmpTmpFileName=`basename ${tmpFileName}`
			zipinfo -1 ${megaZipName} "${tmpTmpFileName}" >/dev/null 2>&1
			let __llerr+=$?
			if [ $__llerr -ne 0 ] ; then
			    sixdeskmess -1 "${tmpFileName} corrupted or not in ${megaZipName}"
			fi
		    done < ${sixdeskjobs_logs}/megaZipList.txt
		    if [ $__llerr -eq 0 ] ; then
			# . check integrity of megaZip file
			unzip -t ${megaZipName} > integrity.txt 2>&1
			let __llerr+=$?
			if [ $__llerr -ne 0 ] ; then
			    sixdeskmess -1 "...integrity problem with megaZip file ${__megaZipFileName}!"
			fi
		    fi
		fi
		# . summary of checks
		if [ $__llerr -eq 0 ] ; then
		    gotit=true
		else
		    if ${lgenerate} ; then
			# regenerate it!
			sixdeskmess -1 "...regenerating ${__megaZipFileName}!"
			continue
		    else
			break
		    fi
		fi
	    fi
	    # for safety, since lcheck comes always with lgenerate
	    if [ $__llerr -eq 0 ] ; then
		break
	    fi
	done
	if ${lgenerate} && ${lcheck} ; then
	    if ! ${gotit} ; then
		sixdeskmess -1 "failed to regenerate MegaZip file ${megaZipName} ${mytries} times!!!"
		exit
	    fi
	fi
    fi

    # . check existence of megaZip file
    sixdeskInspectPrerequisites ${lverbose} . -s ${megaZipName}
    let __lerr+=$?
    if [ $__lerr -ne 0 ] ; then
	sixdeskmess -1 "./${megaZipName} not generated! - error: ${__lerr}"
	exit
    fi

    # - upload megaZip file
    if ${lsubmit} ; then
	sixdeskmess  1 "submitting megaZip file ${__megaZipFileName}"
	multipleTrials "cp ${megaZipName} ${megaZipPath} ; local __exit_status=\$?" "[ \$__exit_status -eq 0 ]" "MegaZip - problem at upload"
	if [ $? -ne 0 ] ; then
	    sixdeskmess -1 "failed to submit ${megaZipName} !!!"
	    exit
	fi
	tmpZipFiles=`cat ${sixdeskjobs_logs}/megaZipList.txt | grep 'zip$'`
	tmpZipFiles=( ${tmpZipFiles} )
	for tmpZipFile in ${tmpZipFiles[@]} ; do
	    tmpPath=`dirname ${tmpZipFile}`
	    touch $tmpPath/JOB_NOT_YET_COMPLETED
	    rm -f $tmpPath/JOB_NOT_YET_STARTED
	done
	rm -f ${sixdeskjobs_logs}/megaZipName.txt
    fi
    # - clean megaZip and .zip/.desc
    if ${lcleanzip} ; then
	tmpZipFiles=`cat ${sixdeskjobs_logs}/megaZipList.txt | grep 'zip$'`
	tmpZipFiles=( ${tmpZipFiles} )
	for tmpZipFile in ${tmpZipFiles[@]} ; do
	    tmpPath=`dirname ${tmpZipFile}`
	    zipFileName=`basename ${tmpZipFile}`
	    descFileName="${zipFileName%.zip}.desc"
	    dot_cleanZips ${tmpPath} ${zipFileName} ${descFileName}
	done
	sixdeskmess  1 "Removing ${megaZipName}"
	rm -f ${megaZipName}
    fi
fi

# summary of status
if ${lstatus} ; then
    echo ""
    echo ""
    sixdeskmess -1 "Summary of status of study $LHCDescrip:"
    sixdeskmess -1 "- number of EXPECTED points in scan (main loop): ${nConsidered};"
    for (( iFound=0; iFound<${#foundNames[@]}; iFound++ )) ; do
	if [ ${nFound[$iFound]} == ${nConsidered} ] ; then
	    expectation="AS EXPECTED!"
	else
	    expectation="NOT as expected: MIMATCH!"
	fi
	sixdeskmess -1 "- number of ${foundNames[$iFound]} FOUND: ${nFound[$iFound]} - ${expectation}"
    done
fi

# ------------------------------------------------------------------------------
# go home, man
# ------------------------------------------------------------------------------

# redefine traps
trap "" SIGINT SIGQUIT SIGSEGV SIGFPE
trap "printSummary; sixdeskexit 0" EXIT

# echo that everything went fine
echo ""
sixdeskmess -1 "done."
