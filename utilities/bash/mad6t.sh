#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [action] [option]
   to manage madx jobs for generating input files for sixtrack

   actions (mandatory, one of the following):
   -c      check
   -s      submit
              in this case, madx jobs are submitted to lsf

   options (optional):
   -i      madx is run interactively (ie on the node you are locally
              connected to, no submission to lsf at all)
           option available only for submission to lsf

EOF
}

function submit(){
    # sanity checks
    if [ ! -s $maskFilesPath/$LHCDescrip.mask ] ; then
	# error: mask file not present
	sixdeskmess="$LHCDescrip.mask is required in sixjobs/mask !!! "
	sixdeskmess
	sixdeskexit 3
    fi
    if [ ! -d "$sixtrack_input" ] ; then
	# error: $sixtrack_input directory does not exist
	sixdeskmess="The $sixtrack_input directory does not exist!!!"
	sixdeskmess
	sixdeskexit 3
    fi
    if test "$beam" = "" -o "$beam" = "b1" -o "$beam" = "B1" ; then
	appendbeam=''
    elif test "$beam" = "b2" -o "$beam" = "B2" ; then
	appendbeam='_b2'
    else
	# error: unrecognised beam option
	sixdeskmess="Unrecognised beam option $beam : must be null, b1, B1, b2 or B2!!!"
	sixdeskmess
	sixdeskexit 6
    fi

    # useful echo
    # - madx version and path
    sixdeskmess="Using madx Version $MADX in $MADX_PATH"
    sixdeskmess
    # - Study, Runtype, Seeds
    sixdeskmess="Study: $LHCDescrip - Runtype: $runtype - Seeds: [$istamad:$iendmad]"
    sixdeskmess
    # - interactive madx
    if ${linter}  ; then
	sixdeskmess="Interactive MADX runs"
	sixdeskmess
    fi

    # lock study and sixtrack_input before doing any action
    sixdesklock $sixdeskstudy
    sixdesklock $sixtrack_input
    
    # Make sure we set the optional value for the proton mass
    # and get temporary copies of the fort.3.mother1/2.
    sed -e 's?%pmass?'$pmass'?g' \
	-e 's?%emit_beam?'$emit_beam'?g' \
	$controlFilesPath/fort.3.mother1_${runtype} > $sixtrack_input/fort.3.mother1.tmp
    
    cp $controlFilesPath/fort.3.mother2_${runtype}${appendbeam} $sixtrack_input/fort.3.mother2.tmp
    # Clear flags for checking
    for tmpFile in CORR_TEST ERRORS WARNINGS ; do
	rm -f $sixtrack_input/$tmpFile
    done

    sixdesktmpdirname=mad
    sixdesktmpdirarg=$sixtrack_input
    sixdeskmktmpdir
    junktmp=$sixdesktmpdir
    export junktmp
    sixdeskmess="Using junktmp: $junktmp"
    sixdeskmess 1
    
    cd $junktmp
    mad6tjob=$lsfFilesPath/mad6t1.lsf
    filejob=$LHCDescrip
    cp $maskFilesPath/$filejob.mask .

    # Loop over seeds
    for (( iMad=$istamad ; iMad<=$iendmad ; iMad++ )) ; do
	
	# clean away any existing results for this seed
	echo " Case : " $iMad
	for f in 2 8 16 34 ; do
	    rm -rf $sixtrack_input/fort.$f"_"$iMad.gz
	done
    
	sed -e 's?%NPART?'$bunch_charge'?g' \
	    -e 's?%EMIT_BEAM?'$emit_beam'?g' \
	    -e 's?%SEEDSYS?'$iMad'?g' \
	    -e 's?%SEEDRAN?'$iMad'?g' $filejob.mask > $filejob."$iMad"
	sed -e 's?%SIXJUNKTMP%?'$junktmp'?g' \
	    -e 's?%SIXI%?'$iMad'?g' \
	    -e 's?%SIXFILEJOB%?'$filejob'?g' \
	    -e 's?%CORR_TEST%?'$CORR_TEST'?g' \
	    -e 's?%FORT_34%?'$fort_34'?g' \
	    -e 's?%MADX_PATH%?'$MADX_PATH'?g' \
	    -e 's?%MADX%?'$MADX'?g' \
	    -e 's?%SIXTRACK_INPUT%?'$sixtrack_input'?g' $mad6tjob > mad6t_"$iMad".lsf
	sleep 2
	chmod 755 mad6t_"$iMad".lsf
	
	if ${linter} ; then
	    sixdesktmpdirname=batch
	    sixdesktmpdirarg=
	    sixdeskmktmpdir
	    batch=$sixdesktmpdir
	    cd $batch
	    ../mad6t_"$iMad".lsf | tee $junktmp/"${LHCDescrip}_mad6t_$iMad".log 2>&1
	    cd ../
	    rm -rf $batch
	else
	    bsub -q $madlsfq -o $junktmp/"${LHCDescrip}_mad6t_$iMad".log -J ${workspace}_${LHCDescrip}_mad6t_$iMad mad6t_"$iMad".lsf
	fi
	mad6tjob=$lsfFilesPath/mad6t.lsf
    done

    # End loop over seeds
    cd $sixdeskhome
    
    # clean locks
    sixdeskunlock $sixtrack_input
    sixdeskunlock $sixdeskstudy
}

function check(){
    sixdeskmess="Checking $LHCDescrip"
    sixdeskmess

    sixdeskmesslevel=0
    
    # check jobs still running
    nJobs=`bjobs -w | grep ${workspace}_${LHCDescrip}_mad6t | wc -l`
    if [ ${nJobs} -gt 0 ] ; then
	bjobs -w | grep ${workspace}_${LHCDescrip}_mad6t
	echo "There appear to be some mad6t jobs still not finished"
	sixdeskexit 1
    fi
    
    # check errors/warnings
    if [ -s $sixtrack_input/ERRORS ] ; then
	sixdeskmess="There appear to be some MADX errors!"
	sixdeskmess
	sixdeskmess="If these messages are annoying you and you have checked them carefully then"
	sixdeskmess
	sixdeskmess="just remove sixtrack_input/ERRORS or rm sixtrack_input/* and rerun `basname $0` -s!"
	sixdeskmess
	echo "ERRORS"
	cat $sixtrack_input/ERRORS
	sixdeskexit 999
    elif [ -s $sixtrack_input/WARNINGS ] ; then
	sixdeskmess="There appear to be some MADX result warnings!"
	sixdeskmess
	sixdeskmess="Some files are being changed; details in sixtrack_input/WARNINGS"
	sixdeskmess
	sixdeskmess="If these messages are annoying you and you have checked them carefully then"
	sixdeskmess
	sixdeskmess="just remove sixtrack_input/WARNINGS"
	sixdeskmess
	echo "WARNINGS"
	cat $sixtrack_input/WARNINGS
	sixdeskexit 998
    fi

    # check that the expected number of files have been generated
    let njobs=$iendmad-$istamad+1
    iForts="2 8 16"
    if [ "$fort_34" != "" ] ; then
	iForts="${iForts} 34"
    fi
    lerr=false
    for iFort in ${iForts} ; do
	nFort=`ls -1 $sixtrack_input/fort.2_[$istamad-$iendmad].gz | wc -l`
	if [ ${nFort} -ne ${njobs} ] ; then
	    sixdeskmess="Discrepancy!!! Expected $njobs - found $nFort fort.${iFort}s in $sixtrack_input"
	    sixdeskmess
	    lerr=True
	fi
    done
    if ${lerr} ; then
	sixdeskexit 2
    fi

    # check mother files
    if test ! -s $sixtrack_input/fort.3.mother1 \
	    -o ! -s $sixtrack_input/fort.3.mother2
    then
	sixdeskmess="Could not find fort.3.mother1/2 in $sixtrack_input"
	sixdeskmess
	sixdeskexit 3
    else
	sixdeskmess="all mother files are there"
	sixdeskmess
    fi

    # multipole errors
    if test "$CORR_TEST" -ne 0 -a ! -s "$sixtrack_input/CORR_TEST"
    then
	sixdeskmiss=0
	for tmpCorr in MCSSX MCOSX MCOX MCSX MCTX ; do
	    rm -f $sixtrack_input/${tmpCorr}_errors
	    for (( iMad=$istamad; iMad<=$iendmad; iMad++ )) ; do
		ls $sixtrack_input/$tmpCorr"_errors_"$iMad
		if [ -f $sixtrack_input/$tmpCorr"_errors_"$iMad ] ; then
		    cat  $sixtrack_input/$tmpCorr"_errors_"$iMad >> $sixtrack_input/$tmpCorr"_errors"
		else
		    let sixdeskmiss+=1
		fi
	    done
	done
	if [ $sixdeskmiss -eq 0 ] ; then
	    echo "CORR_TEST MC_error files copied" > "$sixtrack_input/CORR_TEST"
	    sixdeskmess="CORR_TEST MC_error files copied"
	    sixdeskmess
	else
	    sixdeskmess="$sixdeskmiss MC_error files could not be found!!!"
	    sixdeskmess
	    sixdeskexit 5
	fi
    fi

    # final remarks
    sixdeskmess="All the mad6t jobs appear to have completed successfully using madx -X Version $MADX in $MADX_PATH"
    sixdeskmess
    sixdeskmess="Please check the sixtrack_input directory as the mad6t runs may have failed and just produced empty files!!!"
    sixdeskmess
    sixdeskmess="All jobs/logs/output are in sixtrack_input/mad.run_mad6t directories"
    sixdeskmess
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

# initialisation of local vars
linter=false
lsub=false
lcheck=false

# get options (heading ':' to disable the verbose error handling)
while getopts  ":hisc" opt ; do
    case $opt in
	h)
	    how_to_use
	    exit 1
	    ;;
	i)
	    # interactive mode of running
	    linter=true
	    ;;
	c)
	    # required checking
	    lcheck=true
	    ;;
	s)
	    # required submission
	    lsub=true
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
if ! ${lcheck} && ! ${lsub} ; then
    how_to_use
    echo "No action specified!!! aborting..."
    exit
elif ${lcheck} && ${lsub} ; then
    how_to_use
    echo "Please choose only one action!!! aborting..."
    exit
elif ${lcheck} && ${linter} ; then
    echo "Interactive mode valid only for running. Switching it off!!!"
    linter=false
fi

# in case, additional optional args $1/$2 are for dot_env
source ${SCRIPTDIR}/bash/dot_env
# build paths
sixDeskDefineMADXTree
# sixdeskmess level
sixdeskmesslevel=0

# don't use this script in case of BNL
if test "$BNL" != "" ; then
    sixdeskmess="Use prepare_bnl instead for BNL runs!!! aborting..."
    sixdeskmess
    sixdeskexit 1
fi

if ${lsub} ; then
    submit
else
    check
fi

# echo that everything went fine
sixdeskmess="Appears to have completed normally"
sixdeskmess

# bye bye
sixdeskexit 0

