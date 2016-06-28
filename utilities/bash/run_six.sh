#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [action] [option]
   to manage the submission of sixtrack jobs

   actions (mandatory, one of the following):
   -p      prepare simulation input files
           NB: this includes also preliminary SixTrakc jobs for computing
               chromas and beta functions
   -s      actually submit

EOF
}

function preliminaryChecks(){
    lerr=-1
    # - check run requests
    let tmpTot=$da+$short+$long
    if [ $tmpTot -gt 1 ] ; then
	sixdeskmess="Please select only one among short/long/da run"
	sixdeskmess
	lerr=1
    fi

    # - check definition of amplitude range
    if [ $short -eq 1 ] ; then
	Ampl=$ns1s"_"$ns2s
    elif [ $long -eq 1 ] ;then
	Ampl=$ns1l"_"$ns2l
    elif [ $da -eq 1 ] ;then
	Ampl="0$dimda"
    fi
    if [ -z "$Ampl" ] ;then
	sixdeskmess="Ampl not defined. Please check ns1s/ns2s or ns1l/ns2l or dimda..."
	sixdeskmess
	lerr=2
    fi
 
    # - check paths
    if [ ! -d ${sixtrack_input} ] ; then
	sixdeskmesslevel=1
	sixdeskmess="The directory ${sixtrack_input} does not exist!!!"
	sixdeskmess
	lerr=1
    fi
    ${SCRIPTDIR}/bash/mad6t.sh -c $newLHCDescrip
    if [ $? -ne 0 ] ; then
	sixdeskmesslevel=1
	sixdeskmess="sixtrack_input appears incomplete!!!"
	sixdeskmess
	lerr=2
    fi

    # raise and error message
    if [ $lerr -gt -1 ] ; then
	sixdeskexit $lerr
    fi
}

function prepareTree(){
    # these dirs should already exist...
    mkdir -p $sixdesktrack
    mkdir -p $sixdeskjobs_logs
    mkdir -p $sixdesktrackStudy

    # - save emittance and gamma
    echo "$emit  $gamma" > $sixdesktrackStudy/general_input
    factor=`gawk 'END{fac=sqrt('$emit'/'$gamma');print fac}' /dev/null`
    dimsus=`gawk 'END{dimsus='$dimen'/2;print dimsus}' /dev/null` 
    sixdeskmess="factor $factor - dimsus $dimsus"
    sixdeskmess

    # - da post-processing
    if [ $da -eq 1 ] ; then
	if [ $dimda -eq 6 ] ; then
	    cp $sixdeskhome/inc/dalie6.data $sixdeskjobs_logs/dalie.data
	    sed -e 's/%NO/'$NO1'/g' \
		-e 's/%NV/'$NV'/g' $sixdeskhome/inc/dalie6.mask > $sixdeskjobs_logs/dalie.input
	    cp $sixdeskhome/bin/dalie6 $sixdeskjobs_logs/dalie
	else
	    sed -e 's/%NO/'$NO'/g' $sixdeskhome/inc/dalie4.data.mask > $sixdeskjobs_logs/dalie.data
	    sed -e 's/%NO/'$NO1'/g' \
		-e 's/%NV/'$NV'/g' $sixdeskhome/inc/dalie4.mask > $sixdeskjobs_logs/dalie.input
	    cp $sixdeskhome/bin/dalie4 $sixdeskjobs_logs/dalie
	fi
	cp $sixdeskhome/inc/reson.data $sixdeskjobs_logs
	cp $sixdeskhome/bin/readda $sixdeskjobs_logs
    fi

    # - set up of fort.3
    for tmpFile in fort.3.mad fort.3.mother1 fort.3.mother2 ; do
	cp ${sixtrack_input}/${tmpFile} $sixdeskjobs_logs
    done
    preProcessFort3 $dimen $chrom $dimda $reson $dpini $dpmax $tunex $tuney $e0 $chromx $chromy $tune $bunch_charge

    # user tree
    for (( iMad=$ista; iMad<=$iend; iMad++ )) ; do
	itunexx=$itunex
	ituneyy=$ituney
	if test "$ideltax" -eq 0 -a "$ideltay" -eq 0 ; then
	    ideltax=1000000
	    ideltay=1000000
	fi
	while test "$itunexx" -le "$itunex1" -o "$ituneyy" -le "$ituney1" ; do
	    # get $sixdesktunes
	    sixdesklooptunes
	    # get $simulPath
	    sixDeskDefineRunSixTree $__tree $LHCDesHome $iMad $sixdesktunes
	    mkdir -p $simulPath
	done
    done
}

function checkTree(){
}

function preProcessFort3(){
    local __POST=POST
    local __DIFF=DIFF
    local __dimen=$1
    local __chrom=$2
    local __dimda=$3
    local __reson=$5
    local __tune=$12
    local __bunch_charge=$13
    if [ $__chrom -eq 1 ] ; then
	local __CHROVAL=''
    else
	local __CHROVAL='/'
    fi
    if [ $tune -ne 0 ] ; then
	local __TUNEVAL=''
    else
	local __TUNEVAL='/'
    fi

    # --------------------------------------------------------------------------
    # build fort.3 for momentum scan
    # - first part
    local __turnss=1
    local __nss=1
    local __ax0s=0.
    local __ax1s=0.
    local __imc=31
    local __iclo6=0
    local __writebins=1
    local __ratios=0.
    local __dp1=$6
    local __dp2=$6
    local __chromx=$10
    local __chromy=$11
    local __e0=$9
    local __ition=0
    sed -e 's/%turnss/'$__turnss'/g' \
	-e 's/%nss/'$__nss'/g' \
	-e 's/%ax0s/'$__ax0s'/g' \
	-e 's/%ax1s/'$__ax1s'/g' \
	-e 's/%imc/'$__imc'/g' \
	-e 's/%iclo6/'$__iclo6'/g' \
	-e 's/%writebins/'$__writebins'/g' \
	-e 's/%ratios/'$__ratios'/g' \
	-e 's/%dp1/'$__dp1'/g' \
	-e 's/%dp2/'$__dp2'/g' \
	-e 's/%e0/'$__e0'/g' \
	-e 's/%ition/'$__ition'/g' \
	-e 's/%idfor/'$__idfor'/g' \
	-e 's/%ibtype/'$__ibtype'/g' \
	-e 's/%bunch_charge/'$__bunch_charge'/g' \
	-e 's?%Runnam?%Runnam '"$sixdeskTitle"'?g' \
        $sixdeskjobs_logs/fort.3.mother1 > $sixdeskjobs_logs/fort0.3.mask
    # - multipole blocks
    cat $sixdeskjobs_logs/fort.3.mad >> $sixdeskjobs_logs/fort0.3.mask 
    # - second  part
    if [ $__reson -eq 1 ] ;then
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
	    -e 's/%chromx/'$__chromx'/g' \
	    -e 's/%chromy/'$__chromy'/g' \
	    -e 's/%N1/'$__N1'/g' \
	    -e 's/%N2/'$__N2'/g' -i $sixdeskjobs_logs/fort.3.mother2
    else
	sed -i -e 's/%SUB/\//g' $sixdeskjobs_logs/fort.3.mother2
    fi  
    local __ndafi="$__imc"
    sed -e 's?%CHRO?'$__CHROVAL'?g' \
	-e 's?%TUNE?'$__TUNEVAL'?g' \
	-e 's/%POST/'$__POST'/g' \
	-e 's/%POS1/''/g' \
	-e 's/%ndafi/'$__ndafi'/g' \
	-e 's/%chromx/'$__chromx'/g' \
	-e 's/%chromy/'$__chromy'/g' \
	-e 's/%DIFF/\/'$__DIFF'/g' \
	-e 's/%DIF1/\//g' $sixdeskjobs_logs/fort.3.mother2 >> $sixdeskjobs_logs/fort0.3.mask 
    sixdeskmess="Maximum relative energy deviation for momentum scan $__dp1"
    sixdeskmess

    # --------------------------------------------------------------------------
    # build fort.3 for detuning run
    # - first part
    if [ $__dimen -eq 6 ] ;then
	local __imc=1
	local __iclo6=2
	local __ition=1
	local __dp1=$5
	local __dp2=$5
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
	-e 's/%e0/'$__e0'/g' \
	-e 's/%ition/'$__ition'/g' \
	-e 's/%idfor/'$__idfor'/g' \
	-e 's/%ibtype/'$__ibtype'/g' \
	-e 's/%bunch_charge/'$__bunch_charge'/g' \
	-e 's?%Runnam?%Runnam '"$sixdeskTitle"'?g' \
        $sixdeskjobs_logs/fort.3.mother1 > $sixdeskjobs_logs/forts.3.mask
    # - multipole blocks
    cat $sixdeskjobs_logs/fort.3.mad >> $sixdeskjobs_logs/forts.3.mask 
    # - second  part
    sed -e 's?%CHRO?'$__CHROVAL'?g' \
	-e 's?%TUNE?'$__TUNEVAL'?g' \
	-e 's/%POST/'$__POST'/g' \
	-e 's/%POS1/''/g' \
	-e 's/%ndafi/%nss/g' \
	-e 's/%chromx/'$__chromx'/g' \
	-e 's/%chromy/'$__chromy'/g' \
	-e 's/%DIFF/\/'$__DIFF'/g' \
	-e 's/%DIF1/\//g' $sixdeskjobs_logs/fort.3.mother2 >> $sixdeskjobs_logs/forts.3.mask 
    
    # --------------------------------------------------------------------------
    # build fort.3 for long term run
    # - first part
    local __nss=$sixdeskpairs
    local __imc=1
    if [ $__dimen -eq 6 ] ;then
	local __iclo6=2
	local __ition=1
	local __dp1=$5
	local __dp2=$5
    else
	local __iclo6=0
	local __ition=0
	local __dp1=.0
	local __dp2=.0
    fi
    sed -e 's/%turnss/%turnsl/g' \
	-e 's/%nss/'$__nss'/g' \
	-e 's/%imc/'$__imc'/g' \
	-e 's/%iclo6/'$__iclo6'/g' \
	-e 's/%ax0s/%ax0l/g' \
	-e 's/%ax1s/%ax1l/g' \
	-e 's/%writebins/%writebinl/g' \
	-e 's/%ratios/%ratiol/g' \
	-e 's/%dp1/'$__dp1'/g' \
	-e 's/%dp2/'$__dp2'/g' \
	-e 's/%e0/'$__e0'/g' \
	-e 's/%ition/'$__ition'/g' \
	-e 's/%idfor/'$__idfor'/g' \
	-e 's/%ibtype/'$__ibtype'/g' \
	-e 's/%bunch_charge/'$__bunch_charge'/g' \
	-e 's?%Runnam?%Runnam '"$sixdeskTitle"'?g' \
        $sixdeskjobs_logs/fort.3.mother1 > $sixdeskjobs_logs/fortl.3.mask
    # - multipole blocks
    cat $sixdeskjobs_logs/fort.3.mad >> $sixdeskjobs_logs/fortl.3.mask 
    # - second  part
    local __ndafi="$nss"
    sed -e 's?%CHRO?'$__CHROVAL'?g' \
	-e 's?%TUNE?'$__TUNEVAL'?g' \
	-e 's/%POST/'$__POST'/g' \
	-e 's/%POS1/''/g' \
	-e 's/%ndafi/'$__ndafi'/g' \
	-e 's/%chromx/'$__chromx'/g' \
	-e 's/%chromy/'$__chromy'/g' \
	-e 's/%DIFF/\/'$__DIFF'/g' \
	-e 's/%DIF1/\//g' $sixdeskjobs_logs/fort.3.mother2 >> $sixdeskjobs_logs/fortl.3.mask 
    sixdeskmess="Initial relative energy deviation $__dp1"
    sixdeskmess

    # --------------------------------------------------------------------------
    # build fort.3 for DA run
    # - first part
    local __turnss=1
    local __nss=1
    local __ax0s=0.
    local __ax1s=0.
    local __imc=1
    local __writebins=0
    local __ratios=0.
    local __dp1=.000
    local __dp2=.000
    if [ $__dimda -eq 6 ] ;then
	iclo6=2
	ition=1
	nsix=0
    else
	iclo6=0
	ition=0
	nsix=0
    fi
    sed -e 's/%turnss/'$__turnss'/g' \
	-e 's/%nss/'$__nss'/g' \
	-e 's/%ax0s/'$__ax0s'/g' \
	-e 's/%ax1s/'$__ax1s'/g' \
	-e 's/%imc/'$__imc'/g' \
	-e 's/%iclo6/'$__iclo6'/g' \
	-e 's/%writebins/'$__writebins'/g' \
	-e 's/%ratios/'$__ratios'/g' \
	-e 's/%dp1/'$__dp1'/g' \
	-e 's/%dp2/'$__dp2'/g' \
	-e 's/%e0/'$__e0'/g' \
	-e 's/%ition/'$__ition'/g' \
	-e 's/%idfor/'$__idfor'/g' \
	-e 's/%ibtype/'$__ibtype'/g' \
	-e 's/%bunch_charge/'$__bunch_charge'/g' \
	-e 's?%Runnam?%Runnam '"$sixdeskTitle"'?g' \
        $sixdeskjobs_logs/fort.3.mother1 > $sixdeskjobs_logs/fortda.3.mask
    # - multipole blocks
    cat $sixdeskjobs_logs/fort.3.mad >> $sixdeskjobs_logs/fortda.3.mask 
    # - second  part
    sed -e 's?%CHRO?'$__CHROVAL'?g' \
	-e 's?%TUNE?'$__TUNEVAL'?g' \
	-e 's/%POST/\/'$__POST'/g' \
	-e 's/%POS1/\//g' \
	-e 's/%DIFF/'$__DIFF'/g' \
	-e 's/%chromx/'$__chromx'/g' \
	-e 's/%chromy/'$__chromy'/g' \
	-e 's/%nsix/'$__nsix'/g' \
	-e 's/%DIF1//g' $sixdeskjobs_logs/fort.3.mother2 >> $sixdeskjobs_logs/fortda.3.mask 
}

function prepareShort(){
  if [ "$sussix" -eq 1 ] ;then
      IANA=1
      LR=1
      MR=0
      KR=0
      dimline=1
      sed -e 's/%nss/'$nss'/g' \
          -e 's/%IANA/'$IANA'/g' \
          -e 's/%turnss/'$turnss'/g' \
          -e 's/%dimsus/'$dimsus'/g' \
          -e 's/%LR/'$LR'/g' \
          -e 's/%MR/'$MR'/g' \
          -e 's/%KR/'$KR'/g' \
          -e 's/%dimline/'$dimline'/g' inc/sussix.inp.mask > \
                $sixdeskjobs_logs/sussix.tmp.1
      IANA=0
      LR=0
      MR=1
      dimline=2
      sed -e 's/%nss/'$nss'/g' \
          -e 's/%IANA/'$IANA'/g' \
          -e 's/%turnss/'$turnss'/g' \
          -e 's/%dimsus/'$dimsus'/g' \
          -e 's/%LR/'$LR'/g' \
          -e 's/%MR/'$MR'/g' \
          -e 's/%KR/'$KR'/g' \
          -e 's/%dimline/'$dimline'/g' inc/sussix.inp.mask > \
                $sixdeskjobs_logs/sussix.tmp.2
      MR=0
      KR=1
      dimline=3
      sed -e 's/%nss/'$nss'/g' \
          -e 's/%IANA/'$IANA'/g' \
          -e 's/%turnss/'$turnss'/g' \
          -e 's/%dimsus/'$dimsus'/g' \
          -e 's/%LR/'$LR'/g' \
          -e 's/%MR/'$MR'/g' \
          -e 's/%KR/'$KR'/g' \
          -e 's/%dimline/'$dimline'/g' inc/sussix.inp.mask > \
                $sixdeskjobs_logs/sussix.tmp.3
      sed -e 's/%suss//g' \
          -e 's?SIXTRACKEXE?'$SIXTRACKEXE'?g' \
          -e 's?SIXDESKHOME?'$sixdeskhome'?g' \
               "$sixdeskhome"/utilities/"${lsfjobtype}".lsf.mask > $sixdeskjobs_logs/"${lsfjobtype}".lsf
      chmod 755 $sixdeskjobs_logs/"${lsfjobtype}".lsf
  else
      sed -e 's/%suss/'#'/g' \
          -e 's?SIXTRACKEXE?'$SIXTRACKEXE'?g' \
          -e 's?SIXDESKHOME?'$sixdeskhome'?g' \
             "$sixdeskhome"/utilities/"${lsfjobtype}".lsf.mask > $sixdeskjobs_logs/"${lsfjobtype}".lsf
      chmod 755 $sixdeskjobs_logs/"${lsfjobtype}".lsf 
  fi
  sed -e 's/%suss/'#'/g' \
      -e 's?SIXTRACKEXE?'$SIXTRACKEXE'?g' \
      -e 's?SIXDESKHOME?'$sixdeskhome'?g' \
           "$sixdeskhome"/utilities/"${lsfjobtype}".lsf.mask > $sixdeskjobs_logs/"${lsfjobtype}"0.lsf
  chmod 755 $sixdeskjobs_logs/"${lsfjobtype}"0.lsf
}

function submitChromaJobs(){
    
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
        -e 's/%Runnam/First Turn/g' \
        -e 's/%idfor/0/g' \
        -e 's/%ibtype/0/g' \
        -e 's/%bunch_charge/'$bunch_charge'/g' \
        -e 's/%ition/'0'/g' ${sixtrack_input}/fort.3.mother1 > fort.3.t2
    # - fort.3.m2 (from .mother2)
    CHROVAL='/'
    if [ $tune -eq 0 ] ; then
        TUNEVAL='/'
    else
        TUNEVAL=''
    fi
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

    # --------------------------------------------------------------------------
    # prepare the other input files
    gunzip -c ${sixtrack_input}/fort.16_$i.gz > fort.16
    gunzip -c ${sixtrack_input}/fort.2_$i.gz > fort.2
    if [ -a ${sixtrack_input}/fort.8_$i.gz ] ;then
        gunzip -c ${sixtrack_input}/fort.8_$i.gz > fort.8
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
        sixdesklockdir=$sixdeskstudy
        sixdeskunlock
        sixdeskexit 77
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
        sixdesklockdir=$sixdeskstudy
        sixdeskunlock
        sixdeskexit 78
    fi
    mv fort.10 fort.10_second_oneturn

    # --------------------------------------------------------------------------
    # a bit of arithmetic
    echo "$chrom_eps" > $simulPath/sixdesktunes
    gawk 'FNR==1{print $3, $4}' < fort.10_first_oneturn >> $simulPath/sixdesktunes
    gawk 'FNR==1{print $3, $4}' < fort.10_second_oneturn >> $simulPath/sixdesktunes
    mychrom=`gawk 'FNR==1{E=$1}FNR==2{A=$1;B=$2}FNR==3{C=$1;D=$2}END{print (C-A)/E,(D-B)/E}' < $simulPath/sixdesktunes`
    echo "$mychrom" > $simulPath/mychrom          
    sixdeskmess="Chromaticity computed as $mychrom"
    sixdeskmess
    
}

function submitBetaJob(){
    
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
        -e 's/%ition/'1'/g' ${sixtrack_input}/fort.3.mother1 > $sixdeskjobs_logs/fort.3.m1
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
        -e 's/%DIF1/\//g' $sixdeskjobs_logs/fort.3.mother2 > $sixdeskjobs_logs/fort.3.m2
    cat fort.3.m1 fort.3.mad fort.3.m2 > fort.3
    
    # --------------------------------------------------------------------------
    # prepare the other input filesactually run
    gunzip -c ${sixtrack_input}/fort.16_$i.gz > fort.16
    gunzip -c ${sixtrack_input}/fort.2_$i.gz > fort.2
    if [ -a ${sixtrack_input}/fort.8_$i.gz ] ;then
        gunzip -c ${sixtrack_input}/fort.8_$i.gz > fort.8
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
        sixdesklockdir=$sixdeskstudy
        sixdeskunlock
        sixdeskexit 99
    fi
    mv lin lin_old
    cp fort.10 fort.10_old

    # --------------------------------------------------------------------------
    # regenerate betavalues file
    echo `gawk 'FNR==1{print $5, $48, $6, $49, $3, $4, $50, $51, $53, $54, $55, $56, $57, $58}' $sixdeskjobs_logs/fort.10` > $simulPath/betavalues
    # but if chrom=0 we need to update chromx, chromy
    if [ $chrom -eq 0 ] ; then
        beta_x=`gawk '{print $1}' $simulPath/betavalues`
        beta_x2=`gawk '{print $2}' $simulPath/betavalues`
        beta_y=`gawk '{print $3}' $simulPath/betavalues`
        beta_y2=`gawk '{print $4}' $simulPath/betavalues`
        mychromx=`gawk '{print $1}' $simulPath/mychrom`
        mychromy=`gawk '{print $2}' $simulPath/mychrom`
        htune=`gawk '{print $5}' $simulPath/betavalues`
        vtune=`gawk '{print $6}' $simulPath/betavalues`
        closed_orbit=`gawk '{print $9" "$10" "$11" "$12" "$13" "$14}' $simulPath/betavalues`
        echo "$beta_x $beta_x2 $beta_y $beta_y2 $htune $vtune $mychromx $mychromy $closed_orbit" \
             > $simulPath/betavalues
    fi
    
}

function checkBetaValues(){

    # check that the betavalues file contains all the necessary values
    nBetas=`cat $simulPath/betavalues | wc -w`
    if [ $nBetas -ne 14 ] ; then
        sixdeskmess="betavalues has $nBetas words!!! Should be 14!"
        sixdeskmess
        rm -f $simulPath/betavalues
        sixdesklockdir=$sixdeskstudy
        sixdeskunlock
        sixdeskexit 98
    fi

    # check that the beta values are not NULL and notify user
    beta_x=`gawk '{print $1}' $simulPath/betavalues`
    beta_x2=`gawk '{print $2}' $simulPath/betavalues`
    beta_y=`gawk '{print $3}' $simulPath/betavalues`
    beta_y2=`gawk '{print $4}' $simulPath/betavalues`
    if test "$beta_x" = "" -o "$beta_y" = "" -o "$beta_x2" = "" -o "beta_y2" = "" ; then
        # clean up for a retry by removing old betavalues
	# anyway, this run was not ok...
        rm -f $simulPath/betavalues

        sixdeskmess="One or more betavalues are NULL !!!"
        sixdeskmess
        sixdeskmess="Look in $sixdeskjobs_logs to see SixTrack input and output."
        sixdeskmess
        sixdeskmess="Check the file lin_old which contains the SixTrack fort.6 output."
        sixdeskmess
        sixdesklockdir=$sixdeskstudy
        sixdeskunlock
        sixdeskexit 98
    fi
    sixdeskmess=" Finally all betavalues:"
    sixdeskmess
    sixdeskmess="beta_x[2] $beta_x $beta_x2 - beta_y[2] $beta_y $beta_y2"
    sixdeskmess

    # notify user other variables
    fhtune=`gawk '{print $5}' $simulPath/betavalues`
    fvtune=`gawk '{print $6}' $simulPath/betavalues`
    fchromx=`gawk '{print $7}' $simulPath/betavalues`
    fchromy=`gawk '{print $8}' $simulPath/betavalues`
    fclosed_orbit=`gawk '{print $9" "$10" "$11" "$12" "$13" "$14}' $simulPath/betavalues`
    sixdeskmess="Chromaticity: $fchromx $fchromy"
    sixdeskmess
    sixdeskmess="Tunes: $fhtune $fvtune"
    sixdeskmess
    sixdeskmess="Closed orbit: $fclosed_orbit"
    sixdeskmess

}

function submitRundirExist(){
    if [ ! -d $tree/$Rundir ] ; then
        mkdir -p $tree/$Rundir
    else
	if [ -s $tree/$Rundir/fort.10.gz ] && [ $sixdeskforce -ne 2 ] ; then
	    # relink
	    rm -f $tree/$actualDirName
	    ln -fs $tree/$Rundir $tree/$actualDirName
	    sixdeskmesslevel=1
	    sixdeskmess="$tree/$Rundir relinked to $tree/$actualDirName"
	    sixdeskmess
	else
	    rm -rf "$tree"/"$Rundir"
	    sixdeskmesslevel=1
	    sixdeskmess="$tree/$Rundir removed contained no or zerolength fort.10"
	    sixdeskmess
	fi
    fi
}

function submitCreateLinks(){
    if [ -a ${sixtrack_input}/fort.2_$iMad.gz ] ; then
        ln -s ${sixtrack_input}/fort.2_$iMad.gz  $tree/$Rundir/fort.2.gz
    else
        sixdeskmesslevel=0
        sixdeskmess="No SIXTRACK geometry file (fort.2): Run stopped"
        sixdeskmess
        sixdesklockdir=$sixdeskstudy
        sixdeskunlock
        sixdeskexit 4
    fi
    if [ -a fort.3 ] ; then
        gzip -c fort.3 > $tree/$Rundir/fort.3.gz
    else
        sixdeskmesslevel=0
        sixdeskmess="No SIXTRACK control file (fort.3): Run stopped"
        sixdeskmess
        sixdesklockdir=$sixdeskstudy
        sixdeskunlock
        sixdeskexit 5
    fi
    if [ -a ${sixtrack_input}/fort.8_$iMad.gz ] ; then
        ln -s ${sixtrack_input}/fort.8_$iMad.gz  $tree/$Rundir/fort.8.gz
    else
        sixdeskmesslevel=0
        sixdeskmess="No SIXTRACK misalignment file (fort.8): dummy file created"
        sixdeskmess
        touch $tree/$Rundir/fort.8
        gzip $tree/$Rundir/fort.8
    fi
    if [ -a ${sixtrack_input}/fort.16_$iMad.gz ] ;then
        ln -s "${sixtrack_input}"/fort.16_"$iMad".gz  "$tree"/"$Rundir"/fort.16.gz
    else
        sixdeskmesslevel=0
        sixdeskmess="No SIXTRACK error file (fort.16): dummy file created"
        sixdeskmess
        touch $tree/$Rundir/fort.16
        gzip $tree/$Rundir/fort.16
    fi
}

function submitShort(){

    if [ "$sussix" -eq 1 ] ;then
	# and now we get fractional tunes to plug in qx/qy
        qx=`gawk 'END{qx='$fhtune'-int('$fhtune');print qx}' /dev/null`
        qy=`gawk 'END{qy='$fvtune'-int('$fvtune');print qy}' /dev/null`
        sixdeskmess="Sussix tunes set to $qx, $qy from $fhtune, $fvtune"
        sixdeskmess
        sed -e 's/%qx/'$qx'/g' \
            -e 's/%qy/'$qy'/g' sussix.tmp.1 > sussix.inp.1
        sed -e 's/%qx/'$qx'/g' \
            -e 's/%qy/'$qy'/g' sussix.tmp.2 > sussix.inp.2
        sed -e 's/%qx/'$qx'/g' \
            -e 's/%qy/'$qy'/g' sussix.tmp.3 > sussix.inp.3
    fi

    # get AngleStep
    sixdeskAngleStep 90 $kmax
    # loop over angles
    for (( kk=$kini; kk<=$kend; kk+$kstep )) ; do

	# get Angle and kang
	sixdeskAngle $AngleStep $kk
	sixdeskkang $kk $kmax
        echo $kk, $kini, $kmax, $kend, $Angle, $AngleStep

	# get dirs for this point in scan (returns Runnam, Rundir, actualDirName)
	# ...and notify user
        sixdeskmesslevel=1
        if [ $kk -eq 0 ] ; then
	    sixdeskDefinePointTree $LHCDesName $iMad "m" $sixdesktunes "__" "0" $Angle $kk
            sixdeskmess="Momen $Runnam $Rundir, k=$kk"
	else
	    sixdeskDefinePointTree $LHCDesName $iMad "t" $sixdesktunes $Ampl $turnsse $Angle $kk
            sixdeskmess="Trans $Runnam $Rundir, k=$kk"
        fi
        sixdeskmess

	# does rundir exist?
	submitRundirExist
	
	# finalise generation of fort.3
        if [ $kk -eq 0 ] ; then
	    sed -e 's/%Runnam/'$Runnam'/g' \
                -e 's/%tunex/'$tunexx'/g' \
                -e 's/%tuney/'$tuneyy'/g' \
                -e 's/%inttunex/'$inttunexx'/g' \
                -e 's/%inttuney/'$inttuneyy'/g' fort0.3.mask > fort.3
	else
	    # returns ratio
	    sixdeskRatio $kk
	    # returns ax0 and ax1
	    sixdeskax0 $factor $beta_x $beta_x2 $ratio $kk $square $ns1s $ns2s
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
                -e 's/%writebins/'$writebins'/g' forts.3.mask > fort.3
        fi
	    
        # final preparation of all SIXTRACK files
	submitCreateLinks
	
	# actual submission to lsf
        if [ $k -eq 0 ] ; then
            sed -e 's?SIXJOBNAME?'$Runnam'?g' \
                -e 's?SIXJOBDIR?'$Rundir'?g' \
                -e 's?SIXTRACKDIR?'$sixdesktrack'?g' \
                -e 's?SIXJUNKTMP?'$sixdeskjobs_logs'?g' "${lsfjobtype}"0.lsf > "$Runnam".lsf
        else
            sed -e 's?SIXJOBNAME?'$Runnam'?g' \
                -e 's?SIXJOBDIR?'$Rundir'?g' \
                -e 's?SIXTRACKDIR?'$sixdesktrack'?g' \
                -e 's?SIXJUNKTMP?'$sixdeskjobs_logs'?g' "${lsfjobtype}".lsf > "$Runnam".lsf
        fi
        chmod 755 "$Runnam".lsf
        sixdeskRunnam="$Runnam"
        sixdeskRundir="$Rundir"
        source ${SCRIPTDIR}/bash/dot_bsub $Runnam $Rundir
	
    done

}

function submitLong(){

    sixdeskamps

    # loop over amplitudes
    while test "$ampstart" -lt "$ampfinish" ; do
        fampstart=`gawk 'END{fnn='$ampstart'/1000.;printf ("%.3f\n",fnn)}' /dev/null`
        fampstart=`echo $fampstart | sed -e's/0*$//'`
        fampstart=`echo $fampstart | sed -e's/\.$//'`
        ampend=`expr "$ampstart" + "$ampincl"`
        fampend=`gawk 'END{fnn='$ampend'/1000.;printf ("%.3f\n",fnn)}' /dev/null`
        fampend=`echo $fampend | sed -e's/0*$//'`
        fampend=`echo $fampend | sed -e's/\.$//'`
        Ampl="$fampstart"_"$fampend" 

        sixdeskmesslevel=0
        sixdeskmess="Loop over amplitudes: $Ampl $ns1l $ns2l $nsincl"
        sixdeskmess
        sixdeskmess="$ampstart $ampfinish $ampincl $fampstart $fampend"
        sixdeskmess

	# get AngleStep
	sixdeskAngleStep 90 $kmaxl
	# loop over angles
	for (( kk=$kinil; kk<=$kendl; kk+$kstep )) ; do

	    # get Angle and kang
	    sixdeskAngle $AngleStep $kk
	    sixdeskkang $kk $kmaxl
            echo $kk, $kinil, $kmaxl, $kendl, $Angle, $AngleStep

	    # get dirs for this point in scan (returns Runnam, Rundir, actualDirName)
	    sixdeskDefinePointTree $LHCDesName $iMad "s" $sixdesktunes $Ampl $turnsle $Angle $kk
	    
	    # does rundir exist?
	    submitRundirExist

	    # finalise generation of fort.3
	    # returns ratio
	    sixdeskRatio $kk
	    # returns ax0 and ax1
	    sixdeskax0 $factor $beta_x $beta_x2 $ratio $kk $square $fampstart $fampend
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
                -e 's/%writebinl/'$writebinl'/g' fortl.3.mask > fort.3
	    
            # final preparation of all SIXTRACK files
	    submitCreateLinks

	    # actual submission
            if [ "$sixdeskplatform" = "lsf" ] ; then
		# lsf
		sed -e 's?SIXJOBNAME?'$Runnam'?g' \
                    -e 's?SIXJOBDIR?'$Rundir'?g' \
                    -e 's?SIXTRACKDIR?'$sixdesktrack'?g' \
                    -e 's?SIXTRACKEXE?'$SIXTRACKEXE'?g' \
                    -e 's?SIXCASTOR?'$sixdeskcastor'?g' \
                    -e 's?SIXJUNKTMP?'$sixdeskjobs_logs'?g' "$sixdeskhome"/utilities/"${lsfjobtype}".lsf > \
                      "$Runnam".lsf
		chmod 755 $sixdeskjobs_logs/"$Runnam".lsf
		sixdeskRunnam="$Runnam"
		sixdeskRundir="$Rundir"
		source ${SCRIPTDIR}/bash/dot_bsub $Runnam $Rundir
            elif [ "$sixdeskplatform" = "cpss" ] ; then
		# The 3rd param 0 means only if not submitted already
		sixdeskRunnam="$Runnam"
		sixdeskRundir="$Rundir"
		source ${SCRIPTDIR}/bash/dot_task
            elif [ "$sixdeskplatform" = "grid" ] ; then
		# Create $Runnam.grid in $sixdeskwork/$Runnam
		sixdeskmesslevel=0
		sixdeskmess="Running on GRID not yet implemented!!!"
		sixdeskmess
		sixdesklockdir=$sixdeskjobs_logs
		sixdeskunlock
		sixdesklockdir=$sixdeskstudy
		sixdeskunlock
		sixdeskexit 9
            elif [ "$sixdeskplatform" = "boinc" ] ; then
		# The 3rd param 0 means only if not submitted already
		sixdeskRunnam="$Runnam"
		sixdeskRundir="$Rundir"
		source ${SCRIPTDIR}/bash/dot_boinc
            else
		# Should be impossible
		sixdeskmesslevel=0
		sixdeskmess="You have not selected a platform CPSS, LSF, BOINC or GRID!!!"
		sixdeskmess
		sixdesklockdir=$sixdeskstudy
		sixdeskunlock
		sixdeskexit 10
            fi

        done
	# end of loop over angles
    done
    # end of loop over amplitudes
}

function submitDA(){
    Angle=0
    kk=0
    
    # get dirs for this point in scan (returns Runnam, Rundir, actualDirName)
    sixdeskDefinePointTree $LHCDesName $iMad "d" $sixdesktunes $Ampl "0" $Angle $kk

    # does rundir exist?
    submitRundirExist

    # finalise generation of fort.3
    sed -e 's/%NO/'$NO'/g' \
        -e 's/%tunex/'$tunexx'/g' \
        -e 's/%tuney/'$tuneyy'/g' \
        -e 's/%inttunex/'$inttunexx'/g' \
        -e 's/%inttuney/'$inttuneyy'/g' \
        -e 's/%Runnam/'$Runnam'/g' \
        -e 's/%NV/'$NV'/g' fortda.3.mask > fort.3

    # final preparation of all SIXTRACK files
    submitCreateLinks
	
    # actual submission to lsf
    sed -e 's?SIXJOBNAME?'"$Runnam"'?g' \
        -e 's?SIXTRACKDAEXE?'$SIXTRACKDAEXE'?g' \
        -e 's?SIXJOBDIR?'$Rundir'?g' \
        -e 's?SIXTRACKDIR?'$sixdesktrack'?g' \
        -e 's?SIXJUNKTMP?'$sixdeskjobs_logs'?g' "$sixdeskhome"/utilities/"${lsfjobtype}".lsf > \
                $sixdeskjobs_logs/"$Runnam".lsf
    chmod 755 $sixdeskjobs_logs/"$Runnam".lsf
    sixdeskRunnam="$Runnam"
    sixdeskRundir="$Rundir"
    source ${SCRIPTDIR}/bash/dot_bsub $Runnam $Rundir

}

function submit(){
    
    if [ "$short" -eq 1 ] ; then
	# speedy tune calculation (short)
	prepareShort
    fi
    
    # main loop
    for (( iMad=$ista; iMad<=$iend; iMad++ )) ; do
	itunexx=$itunex
	ituneyy=$ituney
	if test "$ideltax" -eq 0 -a "$ideltay" -eq 0 ; then
	    ideltax=1000000
	    ideltay=1000000
	fi
	while test "$itunexx" -le "$itunex1" -o "$ituneyy" -le "$ituney1" ; do
	    # - get $sixdesktunes
	    sixdesklooptunes
	    #   ...notify user
	    sixdeskmess="Tunescan $sixdesktunes"
	    sixdeskmess
	    # - get $simulPath
	    sixDeskDefineRunSixTree $tree $LHCDesHome $iMad $sixdesktunes
	    # - int tunes
	    sixdeskinttunes
	    if [ $da -eq 0 ] ; then
		if [ ! -s $simulPath/betavalues ]; then
		    if [ $chrom -eq 0 ] ; then
			sixdeskmess="Running two one turn jobs to compute chromaticity"
			sixdeskmess
			submitChromaJobs
		    else
			sixdeskmess="Using Chromaticity specified as $chromx $chromy"
			sixdeskmess
		    fi
		    sixdeskmess="Running `basename $SIXTRACKEXE` (one turn) to get beta values"
		    sixdeskmess
		    submitBetaJob
		fi
		checkBetaValues
	    fi
	    
	    # Resonance Calculation only
	    N1=0
	    if [ "$N1" -gt 0 ] ; then
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
		submitShort
	    elif [ $long -eq 1 ] ; then
		submitLong
	    elif [ $da -eq 1 ] ; then
		submitDA
	    fi

	    # get ready for new point in tune
	    itunexx=`expr $itunexx + $ideltax`
	    ituneyy=`expr $ituneyy + $ideltay`
	done
    done
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

# actions
lprepare=false
lsubmit=false

# get options (heading ':' to disable the verbose error handling)
while getopts  ":hps" opt ; do
    case $opt in
	h)
	    how_to_use
	    exit 1
	    ;;
	p)
	    # prepare tree
	    lprepare=true
	    ;;
	s)
	    # submit
	    lsubmit=true
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
if ! ${lprepare} && ! ${lsubmit} ; then
    how_to_use
    echo "No action specified!!! aborting..."
    exit
elif ${lprepare} && ${lsubmit} ; then
    how_to_use
    echo "Please choose only one action!!! aborting..."
    exit
fi

# ------------------------------------------------------------------------------
# preparatory steps
# ------------------------------------------------------------------------------

# - load environment
source ${SCRIPTDIR}/bash/dot_env
# - settings for sixdeskmessages
sixdeskmessleveldef=0
sixdeskmesslevel=$sixdeskmessleveldef
# - define user tree
sixdeskDefineUserTree

# - preliminary checks
preliminaryChecks

# - notify user
sixdeskmesslevel=2
sixdeskmess="Using sixtrack_input ${sixtrack_input}"
sixdeskmess
sixdeskmess="Using ${sixdeskjobs_logs}"
sixdeskmess
sixdeskmesslevel=$sixdeskmessleveldef

# - lock study dir
sixdesklockdir=$sixdeskstudy
sixdesklock

# - square hard-coded?!
square=0

# - tunes
sixdeskmess="Main loop for Study $LHCDescrip, Seeds $ista to $iend"
sixdeskmess
sixdesktunes
if test $long -eq 1 ; then
    sixdeskmess="Amplitudes $ns1l to $ns2l by $nsincl, Angles $kinil, $kendl, $kmaxl by $kstep"
    sixdeskmess
elif test $short -eq 1 -o $da -eq 1 ; then
    sixdeskmess="Amplitudes $ns1s to $ns2s by $nss, Angles $kini, $kend, $kmax by $kstep"
    sixdeskmess
fi

# cd $sixdeskjobs_logs

# ------------------------------------------------------------------------------
# actual operations
# ------------------------------------------------------------------------------

if ${lprepare} ; then
    # - prepare all the input
    prepareTree
elif ${lsubmit} ; then
    # - check that the tree has been prepared
    checkTree
    # - actually submit
    submit
fi

# cd $sixdeskhome

# ------------------------------------------------------------------------------
# go home, man
# ------------------------------------------------------------------------------

# echo that everything went fine
sixdeskmess="Completed normally"
sixdeskmess

# bye bye
sixdeskexit 0
