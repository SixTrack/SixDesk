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
   -f      fix compromised directory structure
           similar to -g, but it fixes folders which miss any of the input files
              (i.e. the fort.*.gz) - BOINC .zip/.desc files are not re-generated;
   -C      clean .zip/.desc after submission in boinc
           NB: this is done by default in case of submission to boinc
   -t      report the current status of simulations
           for the time being, it reports the number of input and output files

   options (optional)
   -S      selected points of scan only
           in case of preparation of files, regenerate only those directories
              with an incomplete set of input files, unless a fort.10.gz of non-zero
              length or the JOB_NOT_YET_COMPLETED file are there;
           in case of check, check the correct input is generated only in those
              directories that will be submitted (see previous point)
           in case of submission, submit those directories requiring actual submission
              (see previous point)
           NB: this option is NOT active in case of -c only!
   -R      restart action from the specified point in scan (e.g.
           -R lhc_coll%1%s%65_64%3_4%5%37.5)
           NB: cannot be used with -S!
   -M      MegaZip: in case of boinc, WUs all zipped in one file.
              (.zip/.desc files of each WU will be put in a big .zip)
           this option shall be used with both -g and -s actions, and in case
              of explicitely requiring -c
   -B      break backward-compatibility
           for the moment, this sticks only to expressions affecting ratio of
              emittances, amplitude scans and job names in fort.3
   -v      verbose (OFF by default)
   -d      study name (when running many jobs in parallel)
   -p      platform name (when running many jobs in parallel)
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
	Ampl="${ns1s}_${ns2s}"
    elif [ $long -eq 1 ] ; then
	Ampl="${ns1l}_${ns2l}"
    elif [ $da -eq 1 ] ; then
	Ampl="0$dimda"
    fi
    if [ -z "$Ampl" ] ; then
	sixdeskmess -1 "Ampl not defined. Please check ns1s/ns2s or ns1l/ns2l or dimda..."
	let __lerr+=1
    fi

    # - check platforms (to be moved to set_env)
    if [ $short -eq 1 ] ; then
	if [ "$sixdeskplatform" != "lsf" ] ; then
	    sixdeskmess -1 "Only LSF platform for short runs!"
	    let __lerr+=1
	fi
    elif [ $long -eq 1 ] ; then
	if [ "$sixdeskplatform" == "grid" ] ; then
	    sixdeskmess -1 "Running on GRID not yet implemented!!!"
	    let __lerr+=1
	elif [ "$sixdeskplatform" != "lsf" ] && [ "$sixdeskplatform" != "cpss" ] && [ "$sixdeskplatform" != "boinc" ] ; then
	    sixdeskmess -1 "Platform not recognised: $sixdeskplatform!!!"
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
	exit
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
	    ${SCRIPTDIR}/templates/lsf/${lsfjobtype}.job > $sixdeskjobs_logs/${lsfjobtype}.job
    else
	sed -e 's/%suss/'#'/g' \
            ${SCRIPTDIR}/templates/lsf/${lsfjobtype}.job > $sixdeskjobs_logs/${lsfjobtype}.job
    fi
    let __lerr+=$?
    sed -i -e 's?SIXTRACKEXE?'$SIXTRACKEXE'?g' \
           -e 's?SIXDESKHOME?'$sixdeskhome'?g' $sixdeskjobs_logs/${lsfjobtype}.job
    let __lerr+=$?
    chmod 755 $sixdeskjobs_logs/${lsfjobtype}.job
    let __lerr+=$?
    sed -e 's/%suss/'#'/g' \
        -e 's?SIXTRACKEXE?'$SIXTRACKEXE'?g' \
	-e 's?SIXDESKHOME?'$sixdeskhome'?g' \
        ${SCRIPTDIR}/templates/lsf/${lsfjobtype}.job > $sixdeskjobs_logs/${lsfjobtype}0.job
    let __lerr+=$?
    chmod 755 $sixdeskjobs_logs/${lsfjobtype}0.job
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
    ln -sf ${sixtrack_input}/fort.16_$iMad fort.16
    ln -sf ${sixtrack_input}/fort.2_$iMad fort.2
    if [ -e ${sixtrack_input}/fort.8_$iMad ] ; then
        ln -sf ${sixtrack_input}/fort.8_$iMad fort.8
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
	if [ ${sixdesklevel} -lt 1 ]; then
	    sixdeskmess -1 "Running the first one turn job for chromaticity"
	fi
        sixdeskmess -1 "The first turn Sixtrack for chromaticity FAILED!!!"
        sixdeskmess -1 "Look in $sixdeskjobs_logs to see SixTrack input and output."
        sixdeskmess -1 "Check the file first_oneturn which contains the SixTrack fort.6 output."
	exit
    fi
    mv fort.10 fort.10_first_oneturn

    # - second job
    sixdeskmess  1 "Running the second one turn job for chromaticity"
    cat fort.3.t2 fort.3.mad fort.3.m2 > fort.3
    rm -f fort.10
    $SIXTRACKEXE > second_oneturn
    if test $? -ne 0 -o ! -s fort.10 ; then
	if [ ${sixdesklevel} -lt 1 ]; then
	    sixdeskmess -1 "Running the second one turn job for chromaticity"
	fi	
        sixdeskmess -1 "The second turn Sixtrack for chromaticity FAILED!!!"
        sixdeskmess -1 "Look in $sixdeskjobs_logs to see SixTrack input and output."
        sixdeskmess -1 "Check the file second_oneturn which contains the SixTrack fort.6 output."
	exit
    fi
    mv fort.10 fort.10_second_oneturn

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
    ln -sf ${sixtrack_input}/fort.16_$iMad fort.16
    ln -sf ${sixtrack_input}/fort.2_$iMad fort.2
    if [ -e ${sixtrack_input}/fort.8_$iMad ] ; then
        ln -sf ${sixtrack_input}/fort.8_$iMad fort.8
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
    mv lin lin_old
    cp fort.10 fort.10_old

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

function parseBetaValues(){

    local __betaWhere=$1

    # check that the betavalues file contains all the necessary values
    nBetas=`cat $__betaWhere/betavalues | wc -w`
    if [ $nBetas -ne 14 ] ; then
        sixdeskmess -1 "betavalues has $nBetas words!!! Should be 14!"
	exit
    fi

    # check that the beta values are not NULL and notify user
    beta_x=`gawk '{print $1}' $__betaWhere/betavalues`
    beta_x2=`gawk '{print $2}' $__betaWhere/betavalues`
    beta_y=`gawk '{print $3}' $__betaWhere/betavalues`
    beta_y2=`gawk '{print $4}' $__betaWhere/betavalues`
    if test "$beta_x" = "" -o "$beta_y" = "" -o "$beta_x2" = "" -o "beta_y2" = "" ; then
        # clean up for a retry by removing old betavalues
	# anyway, this run was not ok...
        sixdeskmess -1 "One or more betavalues are NULL !!!"
        sixdeskmess -1 "Look in $sixdeskjobs_logs to see SixTrack input and output."
        sixdeskmess -1 "Check the file lin_old which contains the SixTrack fort.6 output."
	exit
    fi
    sixdeskmess  1 "Betavalues:"
    sixdeskmess  1 "beta_x[2] $beta_x $beta_x2 - beta_y[2] $beta_y $beta_y2"

    # notify user other variables
    fhtune=`gawk '{print $5}' $__betaWhere/betavalues`
    fvtune=`gawk '{print $6}' $__betaWhere/betavalues`
    fchromx=`gawk '{print $7}' $__betaWhere/betavalues`
    fchromy=`gawk '{print $8}' $__betaWhere/betavalues`
    fclosed_orbit=`gawk '{print $9" "$10" "$11" "$12" "$13" "$14}' $__betaWhere/betavalues`
    sixdeskmess  1 "Chromaticity: $fchromx $fchromy"
    sixdeskmess  1 "Tunes: $fhtune $fvtune"
    sixdeskmess  1 "Closed orbit: $fclosed_orbit"

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

    # returns ratio
    sixdeskRatio $kang $lbackcomp
    # returns ax0 and ax1
    sixdeskax0 $factor $beta_x $beta_x2 $beta_y $beta_y2 $ratio $kang $square $fampstart $fampend $lbackcomp
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
	
	# fort.3
	ln -s $sixdeskjobs_logs/fort.3 $RundirFullPath/fort.3
		
	# input from MADX: fort.2/.8/.16
	for iFort in 2 8 16 ; do
	    [ ! -e $RundirFullPath/fort.${iFort} ] || rm -f $RundirFullPath/fort.${iFort}
	    ln -s $sixtrack_input/fort.${iFort}_$iMad $RundirFullPath/fort.${iFort}
	done

	# generate zip/description file
	# - generate new taskid
	sixdeskTaskId=`awk '{print ($1+1)}' $sixdeskhome/sixdeskTaskIds/$LHCDescrip/sixdeskTaskId`
	echo $sixdeskTaskId > $sixdeskhome/sixdeskTaskIds/$LHCDescrip/sixdeskTaskId
	sixdesktaskid=boinc$sixdeskTaskId
	sixdeskmess  1 "sixdesktaskid: $sixdesktaskid - $sixdeskTaskId"
	# - return sixdeskTaskName and workunitName
	sixdeskDefineWorkUnitName $workspace $Runnam $sixdesktaskid
	let __lerr+=$?
	if [ $__lerr -eq 0 ] ; then
   	    # - generate zip file
	    #   NB: -j option, to store only the files, and not the source paths
	    zip -j $RundirFullPath/$workunitName.zip $RundirFullPath/fort.2 $RundirFullPath/fort.3 $RundirFullPath/fort.8 $RundirFullPath/fort.16 >/dev/null 2>&1
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

	    # - update MegaZip file:
	    if ${lmegazip} ; then
		echo "$RundirFullPath/$workunitName.desc" >> ${sixdeskjobs_logs}/megaZipList.txt
		echo "$RundirFullPath/$workunitName.zip" >> ${sixdeskjobs_logs}/megaZipList.txt
	    fi
	fi

	# clean
	for iFort in 2 3 8 16 ; do
	    rm -f $RundirFullPath/fort.$iFort
	done

    fi

    return $__lerr
}

function fixDir(){
    # this function is called after a sixdeskDefinePointTree, with the check
    #    that RunDirFullPath and actualDirNameFullPath are non-zero length strings
    local __RunDirFullPath=$1
    local __actualDirNameFullPath=$2
    if [ ! -d $__RunDirFullPath ] ; then
	sixdeskmess -1 "...directory path has problems: recreating it!!!"
	rm -rf $__RunDirFullPath
	mkdir -p $__RunDirFullPath
    fi
    if [ ! -L $__actualDirNameFullPath ] ; then
	sixdeskmess -1 "...directory link has problems: recreating it!!!"
	rm -rf $__actualDirNameFullPath
	ln -fs $__RunDirFullPath $__actualDirNameFullPath
    fi
}

function fixInputFiles(){
    local __RunDirFullPath=$1
    
    # fort.3
    if [ ! -f $RundirFullPath/fort.3.gz ] ; then
	sixdeskmess -1 "...fort.3.gz has problems: recreating it!!!"
	gzip -c $sixdeskjobs_logs/fort.3 > $RundirFullPath/fort.3.gz
    fi
	
    # input from MADX: fort.2/.8/.16
    for iFort in 2 8 16 ; do
	if [ ! -f $RundirFullPath/fort.${iFort}.gz ] ; then
	    sixdeskmess -1 "...fort.${iFort}.gz has problems: recreating it!!!"
	    ln -s $sixtrack_input/fort.${iFort}_$iMad.gz $RundirFullPath/fort.${iFort}.gz
	fi
    done
}

function checkDirStatus(){
    let nExpected+=1
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
    
    sixdeskInspectPrerequisites ${lverbose} $RundirFullPath -d
    let __lerr+=$?
    sixdeskInspectPrerequisites ${lverbose} $RundirFullPath -s fort.2.gz fort.3.gz fort.8.gz fort.16.gz
    let __lerr+=$?
    if [ "$sixdeskplatform" == "lsf" ] ; then
	sixdeskInspectPrerequisites ${lverbose} $RundirFullPath -s $Runnam.job
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
	else
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

    touch $RundirFullPath/JOB_NOT_YET_STARTED
    
    # clean, in case
    dot_clean
    
    # actually submit
    multipleTrials "tmpLines=\"`bsub -q $lsfq -o $RundirFullPath/$Runnam.log $RundirFullPath/$Runnam.job 2>&1`\" ; local __exit_status=\$?" "[ \$__exit_status -eq 0 ]" "Problem at bsub"
    let __lerr+=$?

    # verify that submission was successfull
    if  [ ${__lerr} -eq 0 ] ; then
	# typical message returned by bsub:
	#   Job <864248893> is submitted to queue <8nm>.
	multipleTrials "taskno=\"`echo \"${tmpLines}\" | grep submitted | cut -d\< -f2 | cut -d\> -f1`\"" "[ -n \"\${taskno}\" ]" "Problem at taskno"
	let __lerr+=$?
	if [ ${__lerr} -eq 0 ] ; then
	    local __taskid="lsf${taskno}"
	    sixdeskmess  1 "`echo \"${tmpLines}\" | grep submitted`"
	else
	    local __taskid="lsf_unknown"
	    sixdeskmess -1 "bsub did NOT return a taskno !!! - assigning a default one"
	fi

    else
	sixdeskmess -1 "bsub of $RundirFullPath/$Runnam.job to Queue ${lsfq} failed !!! - going to next WU!"
    fi

    if [ ${__lerr} -eq 0 ] ; then
        # keep track of the $Runnam-taskid couple
	updateTaskIdsCases $sixdeskjobs/jobs $sixdeskjobs/incomplete_jobs $__taskid
    else
	rm -f $RundirFullPath/JOB_NOT_YET_STARTED 
    fi

    return $__lerr
}

function dot_task(){
    return
}

function dot_boinc(){

    local __lerr=0
    
    touch $RundirFullPath/JOB_NOT_YET_STARTED

    # clean, in case
    dot_clean
    
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
	updateTaskIdsCases $sixdeskjobs/tasks $sixdeskjobs/incomplete_tasks $sixdesktaskid
    fi

    rm -f $RundirFullPath/JOB_NOT_YET_STARTED

    return $__lerr
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
    local __taskids
    local __oldtaskid

    __oldtaskid=`grep "$Runnam " $sixdeskwork/taskids`
    if [ -n "$__oldtaskid" ] ; then
	__oldtaskid=`echo $__oldtaskid | cut -d " " -f2-`
	sed -i -e '/'$Runnam' /d' $sixdeskwork/taskids
	__taskids=$__oldtaskid" "$__taskid" "
	sixdeskmess  1 "Job $Runnam re-submitted with JobId/taskid $__taskid; old JobId/taskid(s) $__oldtaskid"
    else
	__taskids=$__taskid
	echo $Runnam >> $sixdeskwork/incomplete_cases
	echo $Runnam >> $sixdeskwork/myincomplete_cases
	sixdeskmess  1 "Job $Runnam submitted with JobId/taskid $__taskid"
    fi
    echo "$Runnam $__taskids " >> $sixdeskwork/taskids
    echo "$Runnam $__taskid " >> $__outFile1
    echo "$Runnam $__taskid " >> $__outFile2
    
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

    # get AngleStep
    sixdeskAngleStep 90 $kmax $lbackcomp

    # ==========================================================================
    for (( kk=$kini; kk<=$kend; kk+=$kstep )) ; do
    # ==========================================================================

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

	# get Angle and kang
	sixdeskAngle $AngleStep $kk
	sixdeskkang $kk $kmax $lbackcomp

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
	    # finalise generation of fort.3
	    submitCreateFinalFort3Short $kk
	    # fix input files
	    fixInputFiles $RundirFullPath
	    let NsuccessFix+=1
	    
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
	    		    $sixdeskjobs_logs/${lsfjobtype}0.job > $RundirFullPath/$Runnam.job
	    	    else
	    		sed -e 's?SIXJOBNAME?'$Runnam'?g' \
	    		    -e 's?SIXJOBDIR?'$Rundir'?g' \
	    		    -e 's?SIXTRACKDIR?'$sixdesktrack'?g' \
	    		    $sixdeskjobs_logs/${lsfjobtype}.job > $RundirFullPath/$Runnam.job
	    	    fi
	    	    chmod 755 $RundirFullPath/$Runnam.job

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
	    	    dot_bsub
		    local __exStatus=$?
		    if [ ${__exStatus} -eq 0 ] ; then
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

    sixdeskamps

    amp0=$ampstart

    # ==========================================================================
    for (( ampstart=$amp0; ampstart<$ampfinish; ampstart+=$ampincl )) ; do
    # ==========================================================================

        fampstart=`gawk 'END{fnn='$ampstart'/1000.;printf ("%.3f\n",fnn)}' /dev/null`
        fampstart=`echo $fampstart | sed -e's/0*$//'`
        fampstart=`echo $fampstart | sed -e's/\.$//'`
        ampend=`expr "$ampstart" + "$ampincl"`
        fampend=`gawk 'END{fnn='$ampend'/1000.;printf ("%.3f\n",fnn)}' /dev/null`
        fampend=`echo $fampend | sed -e's/0*$//'`
        fampend=`echo $fampend | sed -e's/\.$//'`
        Ampl="${fampstart}_${fampend}"

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
	
        sixdeskmess -1 "Considering amplitudes: $Ampl"

	# get AngleStep
	sixdeskAngleStep 90 $kmaxl $lbackcomp
	# get scaled_kstep
	sixdeskScaledKstep $kstep "${reduce_angs_with_aplitude}" $ampstart $ampfinish

	# ======================================================================
	for (( kk=$kinil; kk<=$kendl; kk+=$scaled_kstep )) ; do
	# ======================================================================

	    # trigger for preparation
	    local __lGenerate=false
	    # trigger for submission
	    local __lSubmit=false
	    # exit status: dir ready for submission
	    local __eCheckDirReadyForSubmission=0
	    # exit status: dir already run
	    local __eCheckDirAlreadyRun=0

	    # get Angle and kang
	    sixdeskAngle $AngleStep $kk
	    sixdeskkang $kk $kmaxl $lbackcomp

	    if ${lrestart} && ${lrestartAngle} ; then
		if [ "${angleFromName}" == "${Angle}" ] ; then
		    lrestartAngle=false
		else
		    continue
		fi
	    fi

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
	    sixdeskmess  1 "Point in scan $Runnam $Rundir, k"
	    sixdeskmess -1 "Submitting - ${LHCDescrip} - Job: ${NsuccessSub} - Seed: $iMad/$iend - Ampl: $Ampl - Angle: $Angle"
	    
	    # ----------------------------------------------------------------------
	    if ${lfix} ; then
            # ----------------------------------------------------------------------

		# fix dir
		fixDir $RundirFullPath $actualDirNameFullPath
		# finalise generation of fort.3
		submitCreateFinalFort3Long
		# fix input files
		fixInputFiles $RundirFullPath
		let NsuccessFix+=1
	    
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
	        	submitCreateFinalFort3Long
			
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
	        		-e 's?SIXCASTOR?'$sixdeskcastor'?g' ${SCRIPTDIR}/templates/lsf/${lsfjobtype}.job > $RundirFullPath/$Runnam.job
	        	    chmod 755 $RundirFullPath/$Runnam.job
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
	        	if [ "$sixdeskplatform" == "lsf" ] ; then
	        	    dot_bsub
			    local __exStatus=$?
	        	elif [ "$sixdeskplatform" == "cpss" ] ; then
	        	    dot_task
			    local __exStatus=$?
	        	elif [ "$sixdeskplatform" == "boinc" ] ; then
	        	    dot_boinc
			    local __exStatus=$?
	        	fi
			if [ ${__exStatus} -eq 0 ] ; then
			    let NsuccessSub+=1
			fi
	            else
	        	sixdeskmess -1 "No submission!"
			echo
	            fi
	        fi
	        
	        # ------------------------------------------------------------------
	        if ${lcleanzip} ; then
	        # ------------------------------------------------------------------
		    if ! ${lmegazip} ; then
			dot_cleanZips $RundirFullPath $workunitname.zip $workunitname.desc
		    fi
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
	# finalise generation of fort.3
	submitCreateFinalFort3DA
	# fix input files
	fixInputFiles $RundirFullPath
	let NsuccessFix+=1
	    
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
                -e 's?SIXJUNKTMP?'$sixdeskjobs_logs'?g' $sixdeskhome/utilities/${lsfjobtype}.job > $sixdeskjobs_logs/$Runnam.job
            chmod 755 $sixdeskjobs_logs/$Runnam.job
	    let NsuccessGen+=1
        fi
        if ${lsubmit} ; then
            # actually submit
            dot_bsub
	    local __exStatus=$?
	    if [ ${__exStatus} -eq 0 ] ; then
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
	sixdeskmess -1 "STATUS LISTED  ${NsuccessSub} jobs"			
    fi
    if [ $1 -eq 0 ] ; then
	sixdeskmess -1 "Completed normally."
    else
	sixdeskmess -1 "Premature end."
	if [ $1 -eq 11 ] ; then
	    sixdeskEchoEnvVars /tmp/envs_SIGSEGV.txt
	    sixdeskSendNotifMail "FATAL - SIGSEGV"
	elif [ $1 -eq 8 ] ; then
	    sixdeskEchoEnvVars /tmp/envs_SIGFPE.txt
	    sixdeskSendNotifMail "FATAL - SIGFPE"
	fi
    fi
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
restartPoint=""
currPlatform=""
currStudy=""
optArgCurrStudy="-s"
optArgCurrPlatForm=""
verbose=""

# get options (heading ':' to disable the verbose error handling)
while getopts  ":hgo:sctakfvBSCMd:p:R:" opt ; do
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
	v) 
	    # verbose
	    lverbose=true
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
if ! ${lgenerate} && ! ${lsubmit} && ! ${lcheck} && ! ${lstatus} && ! ${lcleanzip} && ! ${lfix} ; then
    how_to_use
    echo "No action specified!!! aborting..."
    exit 1
fi
# - options
if [ -n "${currStudy}" ] ; then
    optArgCurrStudy="-d ${currStudy}"
fi
if [ -n "${currPlatform}" ] ; then
    optArgCurrPlatForm="-p ${currPlatform}"
fi
if ${lverbose} ; then
    verbose="-v"
fi

# ------------------------------------------------------------------------------
# preparatory steps
# ------------------------------------------------------------------------------

# - load environment
#   NB: workaround to get getopts working properly in sourced script
OPTIND=1
source ${SCRIPTDIR}/bash/set_env.sh ${optArgCurrStudy} ${optArgCurrPlatForm} ${verbose} -e
# - settings for sixdeskmessages
#sixdeskmessleveldef=0
#sixdeskmesslevel=$sixdeskmessleveldef
# - temporary trap
trap "sixdeskexit 1" EXIT

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
fi
if ${lstatus} ; then
    #
    sixdeskmess -1 "Checking status of study $LHCDescrip"
    #
    lockingDirs=( "$sixdeskstudy" )
    #
    # initialise some counters:
    # - expected number of points in scan
    nExpected=0
    # - actually found:
    nFound=( 0 0 0 0 0 0 )
    foundNames=( 'dirs' 'fort.2.gz' 'fort.3.gz' 'fort.8.gz' 'fort.16.gz' 'fort.10.gz' )
fi
NsuccessFix=0
NsuccessGen=0
NsuccessChk=0
NsuccessSub=0
NsuccessSts=0
echo ""

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
if ${lrestart} ; then
    if ${lselected} ; then
	sixdeskmess -1 "flags -R and -S are incompatible!"
	exit
    fi
    sixdeskCheckNFieldsFromJobName "${restartPoint}"
    if [ $? -ne 0 ] ; then
	exit
    fi
    # get infos of starting point
    sixdeskSmashJobName
    lrestartTune=true
    lrestartAmpli=true
    lrestartAngle=true
else
    lrestartTune=false
    lrestartAmpli=false
    lrestartAngle=false
fi

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

# - lock dirs
for tmpDir in ${lockingDirs[@]} ; do
    [ -d $tmpDir ] || mkdir -p $tmpDir
    sixdesklock $tmpDir
done

# - actual traps
trap "printSummary  1 ; sixdeskCleanExit 1" EXIT SIGINT SIGQUIT
trap "printSummary 11 ; sixdeskCleanExit 1" SIGSEGV
trap "printSummary  8 ; sixdeskCleanExit 1" SIGFPE

# - tunes
echo ""
sixdeskmess -1 "Main loop, MadX seeds $ista to $iend"
sixdesktunes
if [ $long -eq 1 ] ; then
    sixdeskmess  1 "Amplitudes $ns1l to $ns2l by $nsincl, Angles $kinil, $kendl, $kmaxl by $kstep"
elif [ $short -eq 1 ] || [ $da -eq 1 ] ; then
    sixdeskmess  1 "Amplitudes $ns1s to $ns2s by $nss, Angles $kini, $kend, $kmax by $kstep"
fi

# preparation to main loop
if ${lgenerate} || ${lfix} ; then
    # - check that all the necessary MadX input is ready
    if [ -n "${currStudy}" ] ; then
	${SCRIPTDIR}/bash/mad6t.sh -c ${optArgCurrStudy}
    else
	${SCRIPTDIR}/bash/mad6t.sh -c
    fi
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
        sixdeskmess -1 "Preparatory step failed."
	exit $__lerr
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
	sixdeskInspectPrerequisites true ${sixdeskjobs_logs} -s ${lsfjobtype}.job ${lsfjobtype}0.job
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
        sixdeskmess -1 "Preparation incomplete."
	exit ${__lerr}
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
    if [ "$sixdeskplatform" == "lsf" ] ; then
	touch $sixdeskjobs/jobs
	touch $sixdeskjobs/incomplete_jobs
    elif [ "$sixdeskplatform" == "boinc" ] ; then
	touch $sixdeskjobs/tasks
	touch $sixdeskjobs/incomplete_tasks
    fi
fi
# - MegaZip: get file name
if ${lmegazip} ; then
    # get name of zip as from initialisation
    megaZipName=`cat ${sixdeskjobs_logs}/megaZipName.txt`
fi
# - prepare tune scans
tunesXX=""
tunesYY=""
for (( itunexx=$itunex; itunexx<=$itunex1; itunexx+=$ideltax )) ; do
    tunesXX="${tunesXX} $(sixdeskPrepareTune $itunexx $xlen)"
done
for (( ituneyy=$ituney; ituneyy<=$ituney1; ituneyy+=$ideltay )) ; do
    tunesYY="${tunesYY} $(sixdeskPrepareTune $ituneyy $ylen)"
done
tunesXX=( ${tunesXX} )
tunesYY=( ${tunesYY} )
sixdeskmess -1 "scanning the following tunes:"
sixdeskmess -1 "Qx: ${tunesXX[@]}"
sixdeskmess -1 "Qy: ${tunesYY[@]}"
if [ -n "${squaredTuneScan}" ] ; then
    lSquaredTuneScan=true
    let iTotal=${#tunesXX[@]}*${#tunesYY[@]}
    sixdeskmess -1 "over a squared domain (i.e. considering all combinations), for a total of ${iTotal} points for each MADX seed."
else
    lSquaredTuneScan=false
    if [ ${#tunesXX[@]} -eq ${#tunesYY[@]} ] ;  then
	iTotal=${#tunesXX[@]}
	sixdeskmess -1 "over a linear domain (i.e. as done so far), for a total of ${iTotal} points for each MADX seed."
    elif [ ${#tunesXX[@]} -lt ${#tunesYY[@]} ] ;  then
	iTotal=${#tunesXX[@]}
	sixdeskmess -1 "over a linear domain (i.e. as done so far), for a total of ${iTotal} points for each MADX seed (limited in H)."
    else
	iTotal=${#tunesYY[@]}
	sixdeskmess -1 "over a linear domain (i.e. as done so far), for a total of ${iTotal} points for each MADX seed (limited in V)."
    fi
fi

# main loop
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
	    gunzip -c $sixtrack_input/fort.${iFort}_$iMad.gz > $sixtrack_input/fort.${iFort}_$iMad
	done
    fi

    for (( ii=0 ; ii<${#tunesYY[@]} ; ii++ )) ; do
	if ${lSquaredTuneScan} ; then
	    # squared scan: for a value of Qy, explore all values of Qx
	    jmin=0
	    jmax=${#tunesXX[@]}
	else
	    # linear scan: for a value of Qy, run only one value of Qx
	    jmin=$ii
	    let jmax=$jmin+1
	fi
	for (( jj=$jmin; jj<$jmax ; jj++ )) ; do
	    tunexx=${tunesXX[$jj]}
	    tuneyy=${tunesYY[$ii]}
	    sixdesktunes=$tunexx"_"$tuneyy
	    if ${lrestart} && ${lrestartTune} ; then
		if [ "${tunesFromName}" == "${sixdesktunes}" ] ; then
		    lrestartTune=false
		else
		    continue
		fi
	    fi
            #   ...notify user
	    echo ""
	    echo ""
	    sixdeskmess  1 "Tunescan $sixdesktunes"
  	    # - get simul path (storage of beta values), stored in $Rundir (returns Runnam, Rundir, actualDirName)...
	    sixdeskDefinePointTree $LHCDesName $iMad "s" $sixdesktunes "" "" "" "" $sixdesktrack
	    if [ $? -gt 0 ] ; then
		# go to next tune values (sixdeskmess already printed out and email sent to user/admins)
		continue
	    fi
	    # - int tunes
	    sixdeskinttunes
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
	    		sixdeskmess -1 "Failure in preparation."
	    		exit ${__lerr}
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
	    rm -f $sixtrack_input/fort.${iFort}_$iMad
	done
    fi	    
done

# restart check
if ${lrestart} ; then
    if ! ${lrestartTune} || ! ${lrestartAmpli} || ! ${lrestartAngle} ; then
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
    fi
fi

# megaZip, in case of boinc
if ${lmegazip} ; then
    
    sixdeskInspectPrerequisites ${lverbose} ${sixdeskjobs_logs} -s megaZipList.txt
    let __lerr+=$?
    if [ $__lerr -ne 0 ] ; then
	sixdeskmess -1 "${sixdeskjobs_logs}/megaZipList.txt not generated!"
	exit ${__lerr}
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
		exit ${mytries}
	    fi
	fi
    fi

    # . check existence of megaZip file
    sixdeskInspectPrerequisites ${lverbose} . -s ${megaZipName}
    let __lerr+=$?
    if [ $__lerr -ne 0 ] ; then
	sixdeskmess -1 "./${megaZipName} not generated!"
	exit ${__lerr}
    fi

    # - upload megaZip file
    if ${lsubmit} ; then
	sixdeskmess  1 "submitting megaZip file ${__megaZipFileName}"
	multipleTrials "cp ${megaZipName} ${megaZipPath} ; local __exit_status=\$?" "[ \$__exit_status -eq 0 ]" "MegaZip - problem at upload"
	if [ $? -ne 0 ] ; then
	    sixdeskmess -1 "failed to submit ${megaZipName} !!!"
	    exit 10
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
    sixdeskmess -1 "- number of EXPECTED points in scan (dirs): ${nExpected};"
    for (( iFound=0; iFound<${#foundNames[@]}; iFound++ )) ; do
	if [ ${nFound[$iFound]} == ${nExpected} ] ; then
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
trap "printSummary 0 ; sixdeskCleanExit 0" EXIT SIGINT SIGQUIT
trap "" SIGSEGV
trap "" SIGFPE

# echo that everything went fine
echo ""
sixdeskmess -1 "done."
