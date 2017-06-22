#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [action] [option]
   to set up the SixDesk environment

   actions (mandatory, one of the following):
   -s              set up new study or update existing one according to local
                       version of input files (${necessaryInputFiles[@]})
                   NB: the local input files (${necessaryInputFiles[@]})
                       will be parsed, used and saved in studies/
   -d <study_name> load existing study.
                   NB: the input files (${necessaryInputFiles[@]})
                       in studies/<study_name> will be parsed, used and saved in sixjobs
   -n              retrieve input files (${necessaryInputFiles[@]}) from template dir
                       to prepare a brand new study. The template files will
                       OVERWRITE the local ones. The template dir is:
           ${SCRIPTDIR}/templates/input
   -U      unlock dirs necessary to the script to run
           PAY ATTENTION when using this option, as no check whether the lock
              belongs to this script or not is performed, and you may screw up
              processing of another script

   options (optional)
   -p      platform name (when running many jobs in parallel)
           recognised platforms: LSF, BOINC, HTCONDOR
   -e      just parse the concerned input files (${necessaryInputFiles[@]}),
               without overwriting
   -P      python path
   -v      verbose (OFF by default)

EOF
}

function basicChecks(){

    # - running dir
    if [ "$sixdeskroot" != "sixjobs" ] ; then
	sixdeskmess -1 "This script must be run in the directory sixjobs!!!"
	sixdeskexit 1
    fi

    # - make sure we have a studies directory
    if ${lset} ; then
	[ -d studies ] || mkdir studies
    elif ${lload} ; then
	sixdeskInspectPrerequisites ${lverbose} studies -d
    fi
    if [ $? -gt 0 ] ; then
	sixdeskexit 2
    fi

    # - make sure that, in case of loading, we have the concerned directory in studies:
    if ${lload} ; then
	sixdeskInspectPrerequisites ${lverbose} ${envFilesPath} -d
	if [ $? -gt 0 ] ; then
	    sixdeskmess -1 "Dir containing input files for study $currStudy not found!!!"
	    sixdeskmess -1 "Expected: ${envFilesPath}"
	    sixdeskexit 3
	fi
    fi

    return 0
}

function consistencyChecks(){

    # - make sure we are in the correct workspace
    if [ -z "${workspace}" ] ; then
	sixdeskmess -1 "Workspace not declared in $envFilesPath/sixdeskenv!!!"
	sixdeskexit 5
    fi
    local __cworkspace=`basename $sixdeskwhere`
    if [ "${workspace}" != "${__cworkspace}" ] ; then
	sixdeskmess -1 "Workspace mismatch: ${workspace} (from sixdeskenv) different from ${__cworkspace} (from current path)!!!"
	sixdeskmess -1 "Check the workspace definition in $envFilesPath/sixdeskenv."
	sixdeskexit 6
    fi

    # - study:
    #   . make sure we have one in sixdeskenv
    if [ -z "${LHCDescrip}" ] ; then
	sixdeskmess -1 "LHCDescrip not declared in $envFilesPath/sixdeskenv!!!"
	sixdeskexit 7
    fi
    #   . make sure it corresponds to the expected one
    if ${lload} ; then
	if [ "${LHCDescrip}" != "${currStudy}" ] ; then
	    sixdeskmess -1 "Study mismatch: ${LHCDescrip} (from sixdeskenv) different from $currStudy (command-line argument)!!!"
	    sixdeskexit 8
	fi
    fi

    return 0
}

function setFurtherEnvs(){
    # scan angles:
    export totAngle=90
    export ampFactor=0.3
    lReduceAngsWithAmplitude=false
    # - reduce angles with amplitude
    if [ -n "${reduce_angs_with_aplitude}" ] ; then
	if [ ${reduce_angs_with_aplitude} -eq 1 ] ; then
	    if [ ${long} -eq 1 ] ; then
		lReduceAngsWithAmplitude=true
	    else
		sixdeskmess -1 "reduced angles with amplitudes available only for long simulations!"
	    fi
	fi
    elif [ -n "${reduce_angs_with_amplitude}" ] ; then
	if [ ${reduce_angs_with_amplitude} -eq 1 ] ; then
	    if [ ${long} -eq 1 ] ; then
		lReduceAngsWithAmplitude=true
	    else
		sixdeskmess -1 "reduced angles with amplitudes available only for long simulations!"
	    fi
	fi
    fi
    export ${lReduceAngsWithAmplitude}
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

# - necessary input files
necessaryInputFiles=( sixdeskenv sysenv )

# actions and options
lset=false
lload=false
lcptemplate=false
loverwrite=true
lverbose=false
lunlock=false
currPlatform=""
currStudy=""
tmpPythonPath=""

# get options (heading ':' to disable the verbose error handling)
while getopts  ":hsvd:ep:P:nU" opt ; do
    case $opt in
	h)
	    how_to_use
	    exit 1
	    ;;
	s)
	    # set study (new/update/switch)
	    lset=true
	    ;;
	d)
	    # load existing study
	    lload=true
	    currStudy="${OPTARG}"
	    ;;
	n) 
	    # copy input files from template dir
	    lcptemplate=true
	    ;;
	e)
	    # do not overwrite
	    loverwrite=false
	    ;;
	p)
	    # the user is requesting a specific platform
	    currPlatform="${OPTARG}"
	    ;;
	P)
	    # the user is requesting a specific path to python
	    tmpPythonPath="${OPTARG}"
	    ;;
	U)
	    # unlock currently locked folder
	    lunlock=true
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
if ! ${lset} && ! ${lload} && ! ${lcptemplate} && ! ${lunlock} ; then
    how_to_use
    echo "No action specified!!! aborting..."
    exit
elif ( ${lset} && ${lload} ) || ( ${lset} && ${lcptemplate} ) || ( ${lcptemplate} && ${lload} ) ; then
    how_to_use
    echo "Please choose only one action!!! aborting..."
    exit
fi
# - clean options in case of brand new study
if ${lcptemplate} ; then
    if [ -n "${currPlatform}" ] ; then
	echo "--> brand new study: -p option with argument ${currPlatform} is switched off."
	currPlatform=""
    fi
fi
# - options
if [ -n "${currStudy}" ] ; then
    echo "--> User required a specific study: ${currStudy}"
fi
if [ -n "${currPlatform}" ] ; then
    echo "--> User required a specific platform: ${currPlatform}"
fi

# ------------------------------------------------------------------------------
# preparatory steps
# ------------------------------------------------------------------------------

export sixdeskhostname=`hostname`
export sixdeskname=`basename $0`
export sixdesknameshort=`echo "${sixdeskname}" | cut -b 1-15`
export sixdeskroot=`basename $PWD`
export sixdeskwhere=`dirname $PWD`
# Set up some temporary values until we execute sixdeskenv/sysenv
# Don't issue lock/unlock debug text (use 2 for that)
export sixdesklogdir=""
export sixdeskhome="."
export sixdeskecho="yes!"
export sixdesklevel=-1
if [ ! -s ${SCRIPTDIR}/bash/dot_profile ] ; then
    echo "dot_profile is missing!!!"
    exit 1
fi
# - load environment
source ${SCRIPTDIR}/bash/dot_profile

# - locking dirs
if ${lcptemplate} ; then
    lockingDirs=( . )
else
    lockingDirs=( . studies )
fi

# - unlocking
if ${lunlock} ; then
    for tmpDir in ${lockingDirs[@]} ; do
	sixdeskunlock $tmpDir
    done
fi
if ! ${lset} && ! ${lload} && ! ${lcptemplate} ; then
   sixdeskmess -1 "requested only unlocking. Exiting..."
   exit 0
fi
   
# - path to active sixdeskenv/sysenv
if ${lset} ; then
    envFilesPath="."
elif ${lload} ; then
    envFilesPath="studies/${currStudy}"
fi

# - basic checks (i.e. dir structure)
basicChecks
if [ $? -gt 0 ] ; then
    sixdeskexit 4
fi

# ------------------------------------------------------------------------------
# actual operations
# ------------------------------------------------------------------------------

# - lock dirs
for tmpDir in ${lockingDirs[@]} ; do
    [ -d $tmpDir ] || mkdir -p $tmpDir
    sixdesklock $tmpDir
done

if ${lcptemplate} ; then

    sixdeskmess -1 "copying here template files for brand new study"
    sixdeskmess -1 "template input files from ${SCRIPTDIR}/templates/input"

    for tmpFile in ${necessaryInputFiles[@]} ; do
	# preserve original time stamps
	cp -p ${SCRIPTDIR}/templates/input/${tmpFile} .
    done

else

    # - make sure we have sixdeskenv/sysenv files
    sixdeskInspectPrerequisites ${lverbose} $envFilesPath -s ${necessaryInputFiles[@]}
    if [ $? -gt 0 ] ; then
        sixdeskmess -1 "not all necessary files are in $envFilesPath dir:"
        for tmpFile in ${necessaryInputFiles[@]} ; do
            sixdeskmess -1 "file ${tmpFile} : `\ls -ltrh $envFilesPath`"
        done
	sixdeskexit 4
    fi

    # - source active sixdeskenv/sysenv
    source ${envFilesPath}/sixdeskenv
    source ${envFilesPath}/sysenv

    # - perform some consistency checks on parsed info
    consistencyChecks

    # - set further envs
    setFurtherEnvs

    # - save sixdeskenv/sysenv
    if ${loverwrite} ; then
	__lnew=false
	if ${lset} ; then
	    if ! [ -d studies/${LHCDescrip} ] ; then
		__lnew=true
		mkdir studies/${LHCDescrip}
	    fi
	fi

        # We now call update_sixjobs in case there were changes
        #    and to create for example the logfile directories
	source ${SCRIPTDIR}/bash/update_sixjobs
	if ! ${__lnew} ; then
            # and now we can check 
	    source ${SCRIPTDIR}/bash/check_envs
	fi
	
	if ${lset} ; then
	    cp ${envFilesPath}/sixdeskenv studies/${LHCDescrip}
	    cp ${envFilesPath}/sysenv studies/${LHCDescrip}
	    if ${__lnew} ; then
  	        # new study
		sixdeskmess -1 "Created a NEW study $LHCDescrip"
	    else
 	        # updating an existing study
		sixdeskmess -1 "Updated sixdeskenv/sysenv for $LHCDescrip"
	    fi
	elif ${lload} ; then
	    cp ${envFilesPath}/sixdeskenv .
	    cp ${envFilesPath}/sysenv .
	    sixdeskmess -1 "Switched to study $LHCDescrip"
	fi
    fi

    # - overwrite platform
    if [ -n "${currPlatform}" ] ; then
	platform=$currPlatform
    fi
    sixdeskSetPlatForm $platform
    if [ $? -ne 0 ] ; then
	sixdeskexit 10
    fi

    # - set python path
    if [ -n "${tmpPythonPath}" ] ; then
	# overwrite what was stated in sixdeskenv/sysenv
	pythonPath=${tmpPythonPath}
    fi
    sixdeskDefinePythonPath ${pythonPath}

    # - useful output
    PTEXT="[${sixdeskplatform}]"
    STEXT="[${LHCDescrip}]"
    WTEXT="[${workspace}]"
    BTEXT="no BNL flag"
    if [ "$BNL" != "" ] ; then
	BTEXT="BNL flag active"
    fi
    NTEXT="["$sixdeskhostname"]"

    echo
    sixdeskmess -1 "STUDY          ${STEXT}"
    sixdeskmess -1 "WSPACE         ${WTEXT}"
    sixdeskmess -1 "PLATFORM       ${PTEXT}"
    sixdeskmess -1 "HOSTNAME       ${NTEXT} - ${BTEXT}"
    echo
    
    if [ -e "$sixdeskstudy"/deleted ] ; then
	if ${loverwrite} ; then
	    rm -f "$sixdeskstudy"/deleted
	else
	    sixdeskmess -1 "Warning! Study `basename $sixdeskstudy` has been deleted!!! Please restore it explicitely"
	fi
    fi

fi

# - unlock dirs
for tmpDir in ${lockingDirs[@]} ; do
    sixdeskunlock $tmpDir
done

if ! ${lcptemplate} ; then
    
    # - kinit, to renew kerberos ticket
    sixdeskRenewKerberosToken
    
    # - fs listquota
    echo ""
    if [ `echo "${sixdesktrack}" | cut -c-4` == "/afs" ] ; then
	sixdeskmess -1 " --> fs listquota ${sixdesktrack}:"
	tmpLines=`fs listquota ${sixdesktrack}`
	echo "${tmpLines}"
	#   check, and in case raise a warning
	fraction=`echo "${tmpLines}" | tail -1 | awk '{frac=$3/$2*100; ifrac=int(frac); if (frac-ifrac>0.5) {ifrac+=1} print (ifrac)}'`
	if [ ${fraction} -gt 90 ] ; then
	    sixdeskmess -1 "WARNING: your quota is above 90%!! pay attention to occupancy of the current study, in case of submission..."
	fi
    else
	sixdeskmess -1 " --> df -Th:"
	\df -Th
	sixdeskmess -1 " the above output is at your convenience, for you to check disk space"
    fi

fi
