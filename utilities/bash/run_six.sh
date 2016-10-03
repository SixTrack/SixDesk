#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [action] [option]
   to manage the submission of sixtrack jobs

   actions (mandatory, one of the following):
   -g      generate simulation files 
           NB: this includes also preliminary SixTrakc jobs for computing
               chromas and beta functions
   -s      actually submit
   -c      check that all the input files have been created and job is ready
           for submission
           NB: this is done by default after preparation or before submission,
               but this action can be triggered on its own
   -t      report the current status of simulations (not yet available)
   -k      run a kinit before doing any action

   By default, all actions are performed no matter if jobs are 
      partially prepared/run.

   options (optional)
   -S      selected points of scan only
           in case of preparation of files, regenerate only those directories
              with an incomplete set of input files (unless a fort.10.gz of non-zero
              length is there)
           in case of check, check the correct input is generated only in those
              directories that will be submitted, ie those without a fort.10.gz of
              non-zero length
           in case of submission, submit those directories without a fort.10.gz
              or zero-length fort.10.gz
           NB: this option is NOT active in case of -c only!
   -C      clean .zip/.desc after submission in boinc
   -M      MegaZip: in case of boinc, WUs all zipped in one file.
             (.zip/.desc files of each WU will be put in a big .zip)
           file, to be the
   -d      study name (when running many jobs in parallel)
   -p      platform name (when running many jobs in parallel)

EOF
}

function preliminaryChecks(){
    local __lerr=0
    
    # - check run requests (to be moved to set_env)
    let tmpTot=$da+$short+$long
    if [ $tmpTot -gt 1 ] ; then
	sixdeskmess="Please select only one among short/long/da run"
	sixdeskmess
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
	sixdeskmess="Ampl not defined. Please check ns1s/ns2s or ns1l/ns2l or dimda..."
	sixdeskmess
	let __lerr+=1
    fi

    # - check platforms (to be moved to set_env)
    if [ $short -eq 1 ] ; then
	if [ "$sixdeskplatform" != "lsf" ] ; then
	    sixdeskmess="Only LSF platform for short runs!"
	    sixdeskmess 1
	    let __lerr+=1
	fi
    elif [ $long -eq 1 ] ; then
	if [ "$sixdeskplatform" == "grid" ] ; then
	    sixdeskmess="Running on GRID not yet implemented!!!"
	    sixdeskmess 1
	    let __lerr+=1
	elif [ "$sixdeskplatform" != "lsf" ] && [ "$sixdeskplatform" != "cpss" ] && [ "$sixdeskplatform" != "boinc" ] ; then
	    sixdeskmess="Platform not recognised: $sixdeskplatform!!!"
	    sixdeskmess 1
	    let __lerr+=1
	fi
    fi

    return $__lerr
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
    sixdeskmess="Maximum relative energy deviation for momentum scan $dpmax"
    sixdeskmess

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
    sixdeskmess="Initial relative energy deviation $dpini"
    sixdeskmess

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
	    sixdeskmess="Err of ownership of $sixdeskboincdir: ${tmpOwner} (expected: $LOGNAME)"
	    sixdeskmess
	    let __lerr+=1
	    return $__lerr
	fi
    fi	
    
    # acl rights, to modify default settings (inherited by work.boinc volume),
    #   so that all the daughter dirs/files inherit the same acl rights
    fs setacl -dir $sixdeskboincdir -acl $LOGNAME rlidwka -acl boinc:users rl
    if [ $? -gt 0 ] ; then
	sixdeskmess="error while setting acl rights for dir $sixdeskboincdir !!!"
	sixdeskmess
	let __lerr+=1
    fi
	
    [ -e $sixdeskboincdir/owner ] || echo "$LOGNAME" > $sixdeskboincdir/owner
    let __lerr+=$?
    [ -d $sixdeskboincdir/work ] || mkdir $sixdeskboincdir/work
    let __lerr+=$?
    [ -d $sixdeskboincdir/results ] || mkdir $sixdeskboincdir/results
    let __lerr+=$?

    # counter of workunits
    [ -d $sixdeskhome/sixdeskTaskIds/$LHCDescrip ] || mkdir -p $sixdeskhome/sixdeskTaskIds/$LHCDescrip
    let __lerr+=$?
    echo "0" > $sixdeskhome/sixdeskTaskIds/$LHCDescrip/sixdeskTaskId
    let __lerr+=$?

    # megaZip
    if ${lmegazip} ; then
	# generate name of megaZip file
	sixdeskDefineMegaZipName "$workspace" "$LHCDescrip" megaZipName
	# ...and keep it until submission takes place
	echo "${megaZipName}" > ${sixdeskjobs_logs}/megaZipName.txt
	sixdeskmess="Requested submission to boinc through megaZip option - filename: ${megaZipName}"
	sixdeskmess
    fi
}

function __inspectPrerequisite(){
    local __test=$1
    local __entry=$2
    local __lerr=0
    
    test $__test ${__entry}
    if [ $? -ne 0 ] ; then
	sixdeskmess="${__entry} NOT there!"
	sixdeskmess
	let __lerr+=1
    else
	sixdeskmess="${__entry} EXISTs!"
	sixdeskmess
    fi
    return $__lerr
}

function inspectPrerequisites(){
    local __path=$1
    local __test=$2
    shift 2
    local __entries=$@
    local __lerr=0
    if [ $# -eq 0 ] ; then
	__inspectPrerequisite ${__test} ${__path}
	let __lerr+=$?
    else
	for tmpEntry in ${__entries} ; do
	    __inspectPrerequisite ${__test} ${__path}/${tmpEntry}
	    let __lerr+=$?
	done
    fi
    return $__lerr
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
    sixdeskmess="Running the first one turn job for chromaticity"
    sixdeskmess
    cat fort.3.t1 fort.3.mad fort.3.m2 > fort.3
    rm -f fort.10
    $SIXTRACKEXE > first_oneturn
    if test $? -ne 0 -o ! -s fort.10 ; then
        sixdeskmess="The first turn Sixtrack for chromaticity FAILED!!!"
        sixdeskmess
        sixdeskmess="Look in $sixdeskjobs_logs to see SixTrack input and output."
        sixdeskmess
        sixdeskmess="Check the file first_oneturn which contains the SixTrack fort.6 output."
        sixdeskmess
	cleanExit 77
    fi
    mv fort.10 fort.10_first_oneturn

    # - second job
    sixdeskmess="Running the second one turn job for chromaticity"
    sixdeskmess
    cat fort.3.t2 fort.3.mad fort.3.m2 > fort.3
    rm -f fort.10
    $SIXTRACKEXE > second_oneturn
    if test $? -ne 0 -o ! -s fort.10 ; then
        sixdeskmess="The second turn Sixtrack for chromaticity FAILED!!!"
        sixdeskmess
        sixdeskmess="Look in $sixdeskjobs_logs to see SixTrack input and output."
        sixdeskmess
        sixdeskmess="Check the file second_oneturn which contains the SixTrack fort.6 output."
        sixdeskmess
	cleanExit 78
    fi
    mv fort.10 fort.10_second_oneturn

    # --------------------------------------------------------------------------
    # a bit of arithmetic
    echo "$chrom_eps" > $__destination/sixdesktunes
    gawk 'FNR==1{print $3, $4}' < fort.10_first_oneturn >> $__destination/sixdesktunes
    gawk 'FNR==1{print $3, $4}' < fort.10_second_oneturn >> $__destination/sixdesktunes
    mychrom=`gawk 'FNR==1{E=$1}FNR==2{A=$1;B=$2}FNR==3{C=$1;D=$2}END{print (C-A)/E,(D-B)/E}' < $__destination/sixdesktunes`
    echo "$mychrom" > $__destination/mychrom          
    sixdeskmess="Chromaticity computed as $mychrom"
    sixdeskmess
    
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
        sixdeskmess="The one turn Sixtrack for betavalues FAILED!!!"
        sixdeskmess
        sixdeskmess="Look in $sixdeskjobs_logs to see SixTrack input and output."
        sixdeskmess
        sixdeskmess="Check the file lin which contains the SixTrack fort.6 output."
        sixdeskmess
	cleanExit 99
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
        sixdeskmess="betavalues has $nBetas words!!! Should be 14!"
        sixdeskmess
        rm -f $__betaWhere/betavalues
	cleanExit 98
    fi

    # check that the beta values are not NULL and notify user
    beta_x=`gawk '{print $1}' $__betaWhere/betavalues`
    beta_x2=`gawk '{print $2}' $__betaWhere/betavalues`
    beta_y=`gawk '{print $3}' $__betaWhere/betavalues`
    beta_y2=`gawk '{print $4}' $__betaWhere/betavalues`
    if test "$beta_x" = "" -o "$beta_y" = "" -o "$beta_x2" = "" -o "beta_y2" = "" ; then
        # clean up for a retry by removing old betavalues
	# anyway, this run was not ok...
        rm -f $__betaWhere/betavalues
        sixdeskmess="One or more betavalues are NULL !!!"
        sixdeskmess
        sixdeskmess="Look in $sixdeskjobs_logs to see SixTrack input and output."
        sixdeskmess
        sixdeskmess="Check the file lin_old which contains the SixTrack fort.6 output."
        sixdeskmess
	cleanExit 98
    fi
    sixdeskmess="Finally all betavalues:"
    sixdeskmess
    sixdeskmess="beta_x[2] $beta_x $beta_x2 - beta_y[2] $beta_y $beta_y2"
    sixdeskmess

    # notify user other variables
    fhtune=`gawk '{print $5}' $__betaWhere/betavalues`
    fvtune=`gawk '{print $6}' $__betaWhere/betavalues`
    fchromx=`gawk '{print $7}' $__betaWhere/betavalues`
    fchromy=`gawk '{print $8}' $__betaWhere/betavalues`
    fclosed_orbit=`gawk '{print $9" "$10" "$11" "$12" "$13" "$14}' $__betaWhere/betavalues`
    sixdeskmess="Chromaticity: $fchromx $fchromy"
    sixdeskmess
    sixdeskmess="Tunes: $fhtune $fvtune"
    sixdeskmess
    sixdeskmess="Closed orbit: $fclosed_orbit"
    sixdeskmess

}

function submitCreateRundir(){
    local __RunDirFullPath=$1
    local __actualDirNameFullPath=$2
    sixdeskmess="Taking care of running dir $__RunDirFullPath (and linking to $__actualDirNameFullPath)"
    sixdeskmess
    [ ! -d $__RunDirFullPath ] || rm -rf $__RunDirFullPath
    mkdir -p $__RunDirFullPath
    [ ! -e $__actualDirNameFullPath ] || rm -rf $__actualDirNameFullPath
    ln -fs $__RunDirFullPath $__actualDirNameFullPath
}

function submitCreateFinalInputs(){
    sixdeskmess="Taking care of SIXTRACK fort.2/fort.3/fort.8/fort.16 in $RundirFullPath"
    sixdeskmess

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
	sixdeskmess="sixdesktaskid: $sixdesktaskid - $sixdeskTaskId"
	sixdeskmess
	# - return sixdeskTaskName and workunitName
	sixdeskDefineWorkUnitName $workspace $Runnam $sixdesktaskid
	# - generate zip file
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
	    # -j option, to store only the files, and not the source paths
	    zip -j ${megaZipName} $RundirFullPath/$workunitName.desc $RundirFullPath/$workunitName.zip >/dev/null 2>&1
	    if [ $? -ne 0 ] ; then
		sixdeskmess="Failing to zip .desc/.zip files!!!"
		sixdeskmess
		cleanExit 22
	    fi
	fi
	
	# clean
	for iFort in 2 3 8 16 ; do
	    rm -f $RundirFullPath/fort.$iFort
	done

    fi
}

function checkDirReadyForSubmission(){
    local __lerr=0

    inspectPrerequisites $RundirFullPath -d
    let __lerr+=$?
    inspectPrerequisites $RundirFullPath -s fort.2.gz fort.3.gz fort.8.gz fort.16.gz
    let __lerr+=$?
    inspectPrerequisites $RundirFullPath -s $Runnam.job
    let __lerr+=$?
    if [ "$sixdeskplatform" == "boinc" ] ; then
	# - there should be only 1 .desc/.zip files
	fileNames=""
	for extension in .desc .zip ; do
	    tmpFileNames=`ls -1 $RundirFullPath/*${extension} 2> /dev/null`
	    if [ -z "${tmpFileNames}" ] ; then
		sixdeskmess="no ${extension} file in $RundirFullPath!!!"
		sixdeskmess
		let __lerr+=1
	    else
		nFiles=`echo "${tmpFileNames}" 2> /dev/null | wc -l`
		if [ $nFiles -gt 1 ] ; then
		    sixdeskmess="found ${nFiles} ${extension} files in $RundirFullPath (expected 1)!"
		    sixdeskmess
		    let __lerr+=1
		else
		    sixdeskGetFileName "${tmpFileNames}" tmpName
		    fileNames="${fileNames} ${tmpName}"
		fi
	    fi
	done
	fileNames=( ${fileNames} )
	# - the two files should have the same name
	if [ "${fileNames[0]}" != "${fileNames[1]}" ] ; then
	    sixdeskmess="mismatch between .desc and .zip file names in $RundirFullPath: ${fileNames[0]} and ${fileNames[1]}!"
	    sixdeskmess
	    let __lerr+=$?
	else
	    workunitName="${fileNames[0]}"
	    sixdeskmess=".desc and .zip files present in $RundirFullPath!"
	    sixdeskmess
	    # - MegaZip: check that the .desc and .zip are in MegaZip file
	    #   (zipinfo, to check just infos about zipped files)
	    if ${lmegazip} ; then
		local __llerr=$__lerr
		for extension in .desc .zip ; do
		    zipinfo -1 ${megaZipName} "${workunitName}${extension}" >/dev/null 2>&1
		    if [ $? -ne 0 ] ; then
			sixdeskmess="${workunitName}${extension} not in ${megaZipName}"
			sixdeskmess
			let __lerr+=1
		    fi
		done
		if [ $__llerr -eq $__lerr ] ; then
		    sixdeskmess="...and in ${megaZipName}!"
		    sixdeskmess
		fi
	    fi
	fi
    fi
    if [ $sussix -eq 1 ] ; then
	inspectPrerequisites $RundirFullPath -s sussix.inp.1.gz sussix.inp.2.gz sussix.inp.3.gz
	let __lerr+=$?
    fi

    return $__lerr
}

function checkDirAlreadyRun(){

    local __lstatus=0
    # allow re-submission in case of a change in platform (eg previously boinc, now lsf)
    local __sixdeskoldtaskid=`grep "$Runnam " $sixdeskwork/taskids 2> /dev/null | cut -d " " -f2- | grep $sixdeskplatform`

    if [ -s $RundirFullPath/fort.10.gz ] ; then
	sixdeskmess="fort.10.gz already generated in $RundirFullPath!"
	sixdeskmess
	let __lstatus+=1
    elif [ "$__sixdeskoldtaskid" != "" ] ; then
        sixdeskmess="Task $Runnam already submitted as taskid(s) $__sixdeskoldtaskid; skipping it"
        sixdeskmess 1
	let __lstatus+=1
    fi

    return $__lstatus

}

function dot_bsub(){

    touch $RundirFullPath/JOB_NOT_YET_STARTED
    
    # clean, in case
    if [ -s $RundirFullPath/fort.10.gz ] ; then
	dot_clean
    fi
    
    # actually submit
    bsub -q $lsfq $sixdeskM -o $RundirFullPath/$Runnam.log < $RundirFullPath/$Runnam.job > tmp 2>&1

    # verify that submission was successfull
    if  [ $? -eq 0 ] ; then
	local __taskno=`tail -1 tmp | sed -e's/Job <\([0-9]*\)> is submitted to queue.*/\1/'`
	if [ "$__taskno" == "" ] ; then
	    sixdeskmess="bsub did NOT return a taskno !!!"
	    sixdeskmess
	    cleanExit 21
	fi
	local __taskid=lsf$__taskno
    else
	rm -f $RundirFullPath/JOB_NOT_YET_STARTED 
	sixdeskmess="bsub of $RundirFullPath/$Runnam.job to Queue ${lsfq} failed !!!"
	sixdeskmess
	cleanExit 10
    fi

    # keep track of the $Runnam-taskid couple
    updateTaskIdsCases $sixdeskjobs/jobs $sixdeskjobs/incomplete_jobs $__taskid
    rm -f tmp
    
}

function dot_task(){
    return
}

function dot_boinc(){

    local __taskid
    
    touch $RundirFullPath/JOB_NOT_YET_STARTED

    # clean, in case
    if [ -s $RundirFullPath/fort.10.gz ] ; then
	dot_clean
    fi
    
    # actually submit
    descFileNames=`ls -1 $RundirFullPath/*.desc 2> /dev/null`
    sixdeskGetFileName "${descFileNames}" workunitname
    sixdeskGetTaskIDfromWorkUnitName $workunitname
    if ! ${lmegazip} ; then
	gotit=false
	for (( mytries=1 ; mytries<=10; mytries++ )) ; do
	    cp $RundirFullPath/$workunitname.desc $RundirFullPath/$workunitname.zip $sixdeskboincdir/work
	    if [ $? -ne 0 ] ; then
		sixdeskmess="Failing to upload .desc/.zip files - trial $mytries!!!"
		sixdeskmess
	    else
		gotit=true
		break
	    fi
	done 
	if ! ${gotit} ; then
	    sixdeskmess="failed to submit boinc job 10 times!!!"
	    sixdeskmess
	    cleanExit 22
	fi
    fi

    # remove .zip/.desc after successful submission
    if ${lcleanzip} ; then
	sixdeskmess="Removing .desc/.zip files in $RundirFullPath"
	sixdeskmess
	rm $RundirFullPath/$workunitname.desc $RundirFullPath/$workunitname.zip
    fi

    # the job has just started
    touch $RundirFullPath/JOB_NOT_YET_COMPLETED
    rm $RundirFullPath/JOB_NOT_YET_STARTED

    # keep track of the $Runnam-taskid couple
    updateTaskIdsCases $sixdeskjobs/tasks $sixdeskjobs/incomplete_tasks $sixdesktaskid
}

function dot_clean(){
    rm -f $RundirFullPath/fort.10.gz
    sed -i -e '/^'$Runnam'$/d' $sixdeskwork/completed_cases
    sed -i -e '/^'$Runnam'$/d' $sixdeskwork/mycompleted_cases
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
	sixdeskmess="Job $Runnam re-submitted with JobId/taskid $__taskid; old JobId/taskid(s) $__oldtaskid"
	sixdeskmess 1
    else
	__taskids=$__taskid
	echo $Runnam >> $sixdeskwork/incomplete_cases
	echo $Runnam >> $sixdeskwork/myincomplete_cases
	sixdeskmess="Job $Runnam submitted with LSF JobId/taskid $__taskid"
	sixdeskmess 1
    fi
    echo "$Runnam $__taskids " >> $sixdeskwork/taskids
    echo "$Runnam $__taskid " >> $__outFile1
    echo "$Runnam $__taskid " >> $__outFile2
    
}

function treatShort(){

    if ${lgenerate} ; then
	if [ $sussix -eq 1 ] ; then
	    # and now we get fractional tunes to plug in qx/qy
            qx=`gawk 'END{qx='$fhtune'-int('$fhtune');print qx}' /dev/null`
            qy=`gawk 'END{qy='$fvtune'-int('$fvtune');print qy}' /dev/null`
            sixdeskmess="Sussix tunes set to $qx, $qy from $fhtune, $fvtune"
            sixdeskmess
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
	    inspectPrerequisites $sixdeskjobs_logs -e sussix.inp.1.gz sussix.inp.2.gz sussix.inp.3.gz
	    if [ $? -gt 0 ] ; then
		sixdeskmess="Error in creating sussix input files"
		sixdeskmess
		cleanExit 47
	    fi
	fi
    fi

    # get AngleStep
    sixdeskAngleStep 90 $kmax

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
	sixdeskkang $kk $kmax

	# get dirs for this point in scan (returns Runnam, Rundir, actualDirName)
	# ...and notify user
        if [ $kk -eq 0 ] ; then
	    sixdeskDefinePointTree $LHCDesName $iMad "m" $sixdesktunes "__" "0" $Angle $kk $sixdesktrack
            sixdeskmess="Momen $Runnam $Rundir, k=$kk"
	else
	    sixdeskDefinePointTree $LHCDesName $iMad "t" $sixdesktunes $Ampl $turnsse $Angle $kk $sixdesktrack
            sixdeskmess="Trans $Runnam $Rundir, k=$kk"
        fi
        sixdeskmess 1

	# ----------------------------------------------------------------------
	if ${lgenerate} ; then
	# ----------------------------------------------------------------------
	    if ${lselected} ; then
		checkDirAlreadyRun >/dev/null 2>&1
		if [ $? -eq 0 ] ; then
		    checkDirReadyForSubmission >/dev/null 2>&1
		    if [ $? -gt 0 ] ; then
			sixdeskmess="$RundirFullPath NOT ready for submission - regenerating the necessary input files!"
			sixdeskmess
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
		if [ $kk -eq 0 ] ; then
		    sed -e 's/%Runnam/'$Runnam'/g' \
			-e 's/%tunex/'$tunexx'/g' \
			-e 's/%tuney/'$tuneyy'/g' \
			-e 's/%inttunex/'$inttunexx'/g' \
			-e 's/%inttuney/'$inttuneyy'/g' $sixdeskjobs_logs/fort0.3.mask > $sixdeskjobs_logs/fort.3
		else
		    # returns ratio
		    sixdeskRatio $kang
		    # returns ax0 and ax1
		    sixdeskax0 $factor $beta_x $beta_x2 $beta_y $beta_y2 $ratio $kk $square $ns1s $ns2s
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
		
		# final preparation of all SIXTRACK files
		# NB: for boinc, it returns workunitName
		submitCreateFinalInputs
		
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
	    fi
	fi

	# ----------------------------------------------------------------------
	if ${lcheck} ; then
        # ----------------------------------------------------------------------
	    if ${lselected} && ! ${__lGenerate} ; then
		checkDirAlreadyRun
		__eCheckDirAlreadyRun=$?
	    fi
	    if ! ${lselected} || [ $__eCheckDirAlreadyRun -eq 0 ] ; then
		checkDirReadyForSubmission
		__eCheckDirReadyForSubmission=$?
	    fi
	    if [ $__eCheckDirReadyForSubmission -gt 0 ] ; then
		sixdeskmess="$RundirFullPath NOT ready for submission!"
		sixdeskmess
	    elif [ $__eCheckDirAlreadyRun -gt 0 ] ; then
		# sensitive to jobs already run/submitted
		sixdeskmess="-> no need to submit: already submitted/finished!"
		sixdeskmess
	    else
		__lSubmit=true
		sixdeskmess="$RundirFullPath ready to submit!"
		sixdeskmess
	    fi
	fi

	# ----------------------------------------------------------------------
	if ${lsubmit} ; then
	# ----------------------------------------------------------------------
	    if ${__lSubmit} ; then
		dot_bsub
	    else
		sixdeskmess="No submission!"
		sixdeskmess
	    fi
	fi
	
    done

}

function treatLong(){

    sixdeskamps

    amp0=$ampstart

    # ==========================================================================
    for (( ampstart=$amp0; ampstart<$ampfinish; ampstart+=$ampincl )) ; do
    # ==========================================================================

	# separate output for current case from previous one
	echo ""
	echo ""
	
        fampstart=`gawk 'END{fnn='$ampstart'/1000.;printf ("%.3f\n",fnn)}' /dev/null`
        fampstart=`echo $fampstart | sed -e's/0*$//'`
        fampstart=`echo $fampstart | sed -e's/\.$//'`
        ampend=`expr "$ampstart" + "$ampincl"`
        fampend=`gawk 'END{fnn='$ampend'/1000.;printf ("%.3f\n",fnn)}' /dev/null`
        fampend=`echo $fampend | sed -e's/0*$//'`
        fampend=`echo $fampend | sed -e's/\.$//'`
        Ampl="${fampstart}_${fampend}"

        sixdeskmess="Loop over amplitudes: $Ampl $ns1l $ns2l $nsincl"
        sixdeskmess
        sixdeskmess="$ampstart $ampfinish $ampincl $fampstart $fampend"
        sixdeskmess

	# get AngleStep
	sixdeskAngleStep 90 $kmaxl

	# ======================================================================
	for (( kk=$kinil; kk<=$kendl; kk+=$kstep )) ; do
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

	    # get Angle and kang
	    sixdeskAngle $AngleStep $kk
	    sixdeskkang $kk $kmaxl

	    # get dirs for this point in scan (returns Runnam, Rundir, actualDirName)
	    sixdeskDefinePointTree $LHCDesName $iMad "s" $sixdesktunes $Ampl $turnsle $Angle $kk $sixdesktrack
	    sixdeskmess="Point in scan $Runnam $Rundir, k=$kk"
	    
	    # ------------------------------------------------------------------
	    if ${lgenerate} ; then
	    # ------------------------------------------------------------------
		if ${lselected} ; then
		    checkDirAlreadyRun >/dev/null 2>&1
		    if [ $? -eq 0 ] ; then
			checkDirReadyForSubmission >/dev/null 2>&1
			if [ $? -gt 0 ] ; then
			    sixdeskmess="$RundirFullPath NOT ready for submission - regenerating the necessary input files!"
			    sixdeskmess
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
		    # returns ratio
		    sixdeskRatio $kang
		    # returns ax0 and ax1
		    sixdeskax0 $factor $beta_x $beta_x2 $beta_y $beta_y2 $ratio $kk $square $fampstart $fampend
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
	    
		    # final preparation of all SIXTRACK files
		    # NB: for boinc, it returns workunitName
		    submitCreateFinalInputs
		    
		    # submission file
		    if [ "$sixdeskplatform" == "lsf" ] ; then
			sed -e 's?SIXJOBNAME?'$Runnam'?g' \
			    -e 's?SIXJOBDIR?'$Rundir'?g' \
			    -e 's?SIXTRACKDIR?'$sixdesktrack'?g' \
			    -e 's?SIXTRACKEXE?'$SIXTRACKEXE'?g' \
			    -e 's?SIXCASTOR?'$sixdeskcastor'?g' ${SCRIPTDIR}/templates/lsf/${lsfjobtype}.job > $RundirFullPath/$Runnam.job
			chmod 755 $RundirFullPath/$Runnam.job
		    fi
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
		    sixdeskmess="$RundirFullPath NOT ready for submission!"
		    sixdeskmess
		elif [ $__eCheckDirAlreadyRun -gt 0 ] ; then
		    # sensitive to jobs already run/submitted
		    sixdeskmess="-> no need to submit: already submitted/finished!"
		    sixdeskmess
		else
		    __lSubmit=true
		    sixdeskmess="$RundirFullPath ready to submit!"
		    sixdeskmess
		fi
	    fi

	    # ------------------------------------------------------------------
	    if ${lsubmit} ; then
	    # ------------------------------------------------------------------
		if ${__lSubmit} ; then
		    if [ "$sixdeskplatform" == "lsf" ] ; then
			dot_bsub
		    elif [ "$sixdeskplatform" == "cpss" ] ; then
			dot_task
		    elif [ "$sixdeskplatform" == "boinc" ] ; then
			dot_boinc
		    fi
		else
		    sixdeskmess="No submission!"
		    sixdeskmess
		fi
	    fi
	    
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

    if ${lgenerate} ; then
	# does rundir exist?
	submitCreateRundir $RundirFullPath $actualDirNameFullPath

	# finalise generation of fort.3
	sed -e 's/%NO/'$NO'/g' \
            -e 's/%tunex/'$tunexx'/g' \
            -e 's/%tuney/'$tuneyy'/g' \
            -e 's/%inttunex/'$inttunexx'/g' \
            -e 's/%inttuney/'$inttuneyy'/g' \
            -e 's/%Runnam/'$Runnam'/g' \
            -e 's/%NV/'$NV'/g' $sixdeskjobs_logs/fortda.3.mask > $sixdeskjobs_logs/fort.3

	# final preparation of all SIXTRACK files
	# NB: for boinc, it returns workunitName
	submitCreateFinalInputs
	
	# submission file
	sed -e 's?SIXJOBNAME?'"$Runnam"'?g' \
            -e 's?SIXTRACKDAEXE?'$SIXTRACKDAEXE'?g' \
            -e 's?SIXJOBDIR?'$Rundir'?g' \
            -e 's?SIXTRACKDIR?'$sixdesktrack'?g' \
            -e 's?SIXJUNKTMP?'$sixdeskjobs_logs'?g' $sixdeskhome/utilities/${lsfjobtype}.job > $sixdeskjobs_logs/$Runnam.job
	chmod 755 $sixdeskjobs_logs/$Runnam.job
    else
	# actually submit
	source ${SCRIPTDIR}/bash/dot_bsub $Runnam $Rundir
    fi

}

function cleanExit(){
    local __exitLevel=0
    if [ $# -eq 1 ] ; then
	__exitLevel=$1
    fi
    for tmpDir in ${lockingDirs[@]} ; do
	sixdesklockdir=$tmpDir
	sixdeskunlock
    done
    sixdeskexit $__exitLevel
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
lkinit=false
lselected=false
lcleanzip=false
lmegazip=false
currPlatform=""
currStudy=""

# get options (heading ':' to disable the verbose error handling)
while getopts  ":hgsctakSCMd:p:" opt ; do
    case $opt in
	a)
	    # do everything
	    lgenerate=true
	    lcheck=true
	    lsubmit=true
	    # run kinit beforehand
	    lkinit=true
	    ;;
	c)
	    # check only
	    lcheck=true
	    ;;
	k)
	    # run kinit beforehand
	    lkinit=true
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
	    ;;
	S)
	    # selected points of scan only
	    lselected=true
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
if ! ${lgenerate} && ! ${lsubmit} && ! ${lcheck} && ! ${lstatus} ; then
    how_to_use
    echo "No action specified!!! aborting..."
    exit
elif ${lgenerate} && ${lsubmit} && ${lstatus} ; then
    how_to_use
    echo "Please choose only one action!!! aborting..."
    exit
fi
# - options
if [ -n "${currStudy}" ] ; then
    echo ""
    echo "--> User required a specific study: ${currStudy}"
    echo ""
fi
if [ -n "${currPlatform}" ] ; then
    echo ""
    echo "--> User required a specific platform: ${currPlatform}"
    echo ""
fi

# ------------------------------------------------------------------------------
# preparatory steps
# ------------------------------------------------------------------------------

# - load environment
source ${SCRIPTDIR}/bash/dot_env ${currStudy} ${currPlatform}
# - settings for sixdeskmessages
sixdeskmessleveldef=0
sixdeskmesslevel=$sixdeskmessleveldef

# - kinit, to renew kerberos ticket
if ${lkinit} ; then
    sixdeskmess=" --> kinit beforehand:"
    sixdeskmess
    kinit
fi

# - action-dependet stuff
echo ""
if ${lgenerate} ; then
    #
    sixdeskmess="Preparing sixtrack input files for study $LHCDescrip"
    sixdeskmess
    #
    lockingDirs=( "$sixdeskstudy" "$sixdeskjobs_logs" )
    #
    sixdeskmess="Using sixtrack_input ${sixtrack_input}"
    sixdeskmess 2
    sixdeskmess="Using ${sixdeskjobs_logs}"
    sixdeskmess 2
fi
if ${lcheck} ; then
    #
    sixdeskmess="Checking that all sixtrack input files for study $LHCDescrip are there"
    sixdeskmess
    #
    lockingDirs=( "$sixdeskstudy" "$sixdeskjobs_logs" )
    #
    sixdeskmess="Using sixtrack_input ${sixtrack_input}"
    sixdeskmess 2
    sixdeskmess="Using ${sixdeskjobs_logs}"
    sixdeskmess 2
fi
if ${lsubmit} ; then
    #
    sixdeskmess="Submitting sixtrack input files for study $LHCDescrip"
    sixdeskmess
    #
    lockingDirs=( "$sixdeskstudy" "$sixdeskjobs_logs" )
    #
    sixdeskmess="Using sixtrack_input ${sixtrack_input}"
    sixdeskmess 2
    sixdeskmess="Using ${sixdeskjobs_logs}"
    sixdeskmess 2
fi
if ${lstatus} ; then
    #
    sixdeskmess="Checking running sixtrack simulations of study $LHCDescrip"
    sixdeskmess 2
    #
    lockingDirs=( "$sixdeskstudy" )
    #
fi
echo ""

# - define user tree
sixdeskDefineUserTree $basedir $scratchdir $workspace

# - boinc variables
sixDeskSetBOINCVars


# - preliminary checks
preliminaryChecks
if [ $? -gt 0 ] ; then
    sixdeskexit
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
    sixdesklockdir=$tmpDir
    sixdesklock
done

# - tunes
echo ""
sixdeskmess="Main loop, MadX seeds $ista to $iend"
sixdeskmess
sixdesktunes
if [ $long -eq 1 ] ; then
    sixdeskmess="Amplitudes $ns1l to $ns2l by $nsincl, Angles $kinil, $kendl, $kmaxl by $kstep"
    sixdeskmess
elif [ $short -eq 1 ] || [ $da -eq 1 ] ; then
    sixdeskmess="Amplitudes $ns1s to $ns2s by $nss, Angles $kini, $kend, $kmax by $kstep"
    sixdeskmess
fi

# preparation to main loop
if ${lgenerate} ; then
    # - check that all the necessary MadX input is ready
    if [ -n "${currStudy}" ] ; then
	${SCRIPTDIR}/bash/mad6t.sh -c -d ${currStudy}
    else
	${SCRIPTDIR}/bash/mad6t.sh -c
    fi
    let __lerr+=$?
    # - these dirs should already exist...
    for tmpDir in $sixdesktrack $sixdeskjobs $sixdeskjobs_logs $sixdesktrackStudy ; do
	[ -d $tmpDir ] || mkdir -p $tmpDir
	inspectPrerequisites $tmpDir -d
	let __lerr+=$?
    done
    # - save emittance and gamma
    echo "$emit  $gamma" > $sixdesktrackStudy/general_input
    let __lerr+=$?
    # - set up of fort.3
    for tmpFile in fort.3.mad fort.3.mother1 fort.3.mother2 ; do
	cp ${sixtrack_input}/${tmpFile} $sixdeskjobs_logs
	if [ $? -ne 0 ] ; then
	    sixdeskmess="unable to copy ${sixtrack_input}/${tmpFile} to $sixdeskjobs_logs"
	    sixdeskmess
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
        sixdeskmess="Preparatory step failed."
        sixdeskmess
	cleanExit $__lerr
    fi
fi
if ${lcheck} ; then
    # - general_input
    inspectPrerequisites $sixdesktrackStudy -s general_input
    let __lerr+=$?
    # - preProcessFort3
    inspectPrerequisites ${sixdeskjobs_logs} -s fort0.3.mask forts.3.mask fortl.3.mask fortda.3.mask
    let __lerr+=$?
    if [ $short -eq 1 ] ; then
	if [ $sussix -eq 1 ] ; then
	    inspectPrerequisites ${sixdeskjobs_logs} -s sussix.tmp.1 sussix.tmp.2 sussix.tmp.3
	    let __lerr+=$?
	    echo $__lerr
	fi
	inspectPrerequisites ${sixdeskjobs_logs} -s ${lsfjobtype}.job ${lsfjobtype}0.job
	let __lerr+=$?
    elif [ $da -eq 1 ] ; then
	inspectPrerequisites ${sixdeskjobs_logs} -s dalie.data dalie.input dalie reson.data readda
	let __lerr+=$?
    fi
    if [ "$sixdeskplatform" == "boinc" ] ; then
	# - existence of dirs
	inspectPrerequisites $sixdeskboincdir -d
	if [ $? -gt 0 ] ; then
	    let __lerr+=1
	else
	    for tmpDir in $sixdeskboincdir/work $sixdeskboincdir/results ; do
		inspectPrerequisites $tmpDir -d
		let __lerr+=$?
	    done
	    # - check of ownership
	    inspectPrerequisites $sixdeskboincdir -s owner
	    if [ $? -gt 0 ] ; then
		let __lerr+=1
	    else
		tmpOwner=`cat $sixdeskboincdir/owner`
		if [ "${tmpOwner}" != "$LOGNAME" ] ; then
		    sixdeskmess="Err of ownership of $sixdeskboincdir: ${tmpOwner} (expected: $LOGNAME)"
		    sixdeskmess
		    let __lerr+=1
		else
		    # - check acl rights
		    aclRights=`fs listacl $sixdeskboincdir | grep $LOGNAME 2> /dev/null | awk '{print ($2)}'`
		    if [ "$aclRights" != "rlidwka" ] ; then
			sixdeskmess="Err of acl rights on $sixdeskboincdir for $LOGNAME: ${aclRights} (expected: rlidwka)"
			sixdeskmess
			let __lerr+=1
		    fi
		    aclRights=`fs listacl $sixdeskboincdir | grep boinc:users 2> /dev/null | awk '{print ($2)}'`
		    if [ "$aclRights" != "rl" ] ; then
			sixdeskmess="Err of acl rights on $sixdeskboincdir for boinc:users ${aclRights} (expected: rl)"
			sixdeskmess
			let __lerr+=1
		    fi
		fi
	    fi
	fi
	# - MegaZip:
	if ${lmegazip} ; then
	    inspectPrerequisites ${sixdeskjobs_logs} -s megaZipName.txt
	    if [ $? -gt 0 ] ; then
		let __lerr+=1
	    fi
	fi
    fi
    if [ ${__lerr} -gt 0 ] ; then
        sixdeskmess="Preparation incomplete."
        sixdeskmess
	cleanExit ${__lerr}
    fi
fi
# - echo emittance and dimsus
factor=`gawk 'END{fac=sqrt('$emit'/'$gamma');print fac}' /dev/null`
dimsus=`gawk 'END{dimsus='$dimen'/2;print dimsus}' /dev/null` 
sixdeskmess="factor $factor - dimsus $dimsus"
sixdeskmess
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
if [ "$sixdeskplatform" == "boinc" ] && ${lmegazip} ; then
    # get name of zip as from initialisation
    megaZipName=`cat ${sixdeskjobs_logs}/megaZipName.txt`
fi

# main loop
for (( iMad=$ista; iMad<=$iend; iMad++ )) ; do
    itunexx=$itunex
    ituneyy=$ituney
    if test $ideltax -eq 0 -a $ideltay -eq 0 ; then
	ideltax=1000000
	ideltay=1000000
    fi
    if ${lgenerate} ; then
	iForts="2 8 16"
	if [ "$fort_34" != "" ] ; then
	    iForts="${iForts} 34"
	fi
	# required not only by boinc, but also by chroma/beta jobs
	for iFort in ${iForts} ; do
	    gunzip -c $sixtrack_input/fort.${iFort}_$iMad.gz > $sixtrack_input/fort.${iFort}_$iMad
	done
    fi	    
    while test $itunexx -le $itunex1 -o $ituneyy -le $ituney1 ; do
	# - get $sixdesktunes
	sixdesklooptunes
	#   ...notify user
	echo ""
	echo ""
	echo ""
	sixdeskmess="Tunescan $sixdesktunes"
	sixdeskmess
	# - get simul path (storage of beta values), stored in $Rundir...
	sixdeskDefinePointTree $LHCDesName $iMad "s" $sixdesktunes "" "" "" "" $sixdesktrack
	# - int tunes
	sixdeskinttunes
	# - beta values?
	if [ $short -eq 1 ] || [ $long -eq 1 ] ; then
	    if ${lgenerate} ; then
		[ -d $RundirFullPath ] || mkdir -p $RundirFullPath
		cd $sixdeskjobs_logs
		if [ $chrom -eq 0 ] ; then
		    sixdeskmess="Running two one turn jobs to compute chromaticity"
		    sixdeskmess
		    submitChromaJobs $RundirFullPath
		else
		    sixdeskmess="Using Chromaticity specified as $chromx $chromy"
		    sixdeskmess
		fi
		sixdeskmess="Running `basename $SIXTRACKEXE` (one turn) to get beta values"
		sixdeskmess
		submitBetaJob $RundirFullPath
		cd $sixdeskhome
	    fi
	    if ${lcheck} ; then
		# checks
		inspectPrerequisites $RundirFullPath -d
		let __lerr+=$?
		if [ $chrom -eq 0 ] ; then
		    inspectPrerequisites $RundirFullPath -s mychrom
		    let __lerr+=$?
		fi
		inspectPrerequisites $RundirFullPath -s betavalues
		let __lerr+=$?
		if [ ${__lerr} -gt 0 ] ; then
		    sixdeskmess="Failure in preparation."
		    sixdeskmess
		    cleanExit ${__lerr}
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
	
	# actually submit according to type of job
	if [ $short -eq 1 ] ; then
	    treatShort
	elif [ $long -eq 1 ] ; then
	    treatLong
	elif [ $da -eq 1 ] ; then
	    treatDA
	fi
	
	# get ready for new point in tune
	itunexx=`expr $itunexx + $ideltax`
	ituneyy=`expr $ituneyy + $ideltay`
    done
    if ${lgenerate} ; then
	iForts="2 8 16"
	if [ "$fort_34" != "" ] ; then
	    iForts="${iForts} 34"
	fi
	# required not only by boinc, but also by chroma/beta jobs
	for iFort in ${iForts} ; do
	    rm $sixtrack_input/fort.${iFort}_$iMad
	done
    fi	    
done

# megaZip, in case of boinc: upload mega .zip file
if ${lsubmit} && [ "$sixdeskplatform" == "boinc" ] && ${lmegazip} ; then
    gotit=false
    for (( mytries=1 ; mytries<=10; mytries++ )) ; do
	cp ${megaZipName} ${megaZipPath}
	if [ $? -ne 0 ] ; then
	    sixdeskmess="Failing to MegaZip file ${megaZipName} to ${megaZipPath} - trial $mytries!!!"
	    sixdeskmess
	else
	    gotit=true
	    break
	fi
    done 
    if ! ${gotit} ; then
	sixdeskmess="failed to submit MegaZip file ${megaZipName} 10 times!!!"
	sixdeskmess
	cleanExit 22
    fi
    # remove MegaZip file after successful submission
    if ${lcleanzip} ; then
	sixdeskmess="Removing MegaZip file"
	sixdeskmess
	rm ${megaZipName}
    fi
    # clean
    rm ${sixdeskjobs_logs}/megaZipName.txt
fi

# ------------------------------------------------------------------------------
# go home, man
# ------------------------------------------------------------------------------

# echo that everything went fine
echo ""
sixdeskmess="Completed normally"
sixdeskmess

# bye bye
cleanExit 0
