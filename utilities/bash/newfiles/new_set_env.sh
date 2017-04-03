#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [action] [option]
   to set up the SixDesk environment

   actions (mandatory, one of the following):
   -s              set up new study or update existing one according to local
                       version of input files (sixdeskenv/sysenv)
                   NB: the local sixdeskenv and sysenv will be parsed, used and
                       saved in studies/
   -d <study_name> load existing study.
                   NB: the sixdeskenv and sysenv in studies/<study_name> will
                       be parsed, used and saved in sixjobs
   -n              retrieve input files (sixdeskenv/sysenv) from template dir
                       to prepare a brand new study. The template files will
                       OVERWRITE the local ones. The template dir is:
           ${SCRIPTDIR}/templates/input

   options (optional)
   -p      platform name (when running many jobs in parallel)
   -e      just parse the concerned sixdeskenv/sysenv files, without
               overwriting
   -v      verbose (OFF by default)

EOF
}

function basicChecks(){

    # - running dir
    if [ "$sixdeskroot" != "sixjobs" ] ; then
	sixdeskmess -1 "This script must be run in the directory sixjobs!!!"
	sixdeskmess -1
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
	    sixdeskmess -1
	    sixdeskmess -1 "Expected: ${envFilesPath}"
	    sixdeskmess -1
	    sixdeskexit 3
	fi
    fi

    return 0
}

function consistencyChecks(){

    # - make sure we are in the correct workspace
    if [ -z "${workspace}" ] ; then
	sixdeskmess -1 "Workspace not declared in $envFilesPath/sixdeskenv!!!"
	sixdeskmess -1
	sixdeskexit 5
    fi
    local __cworkspace=`basename $sixdeskwhere`
    if [ "${workspace}" != "${__cworkspace}" ] ; then
	sixdeskmess -1 "Workspace mismatch: ${workspace} (from sixdeskenv) different from ${__cworkspace} (from current path)!!!"
	sixdeskmess -1
	sixdeskmess -1 "Check the workspace definition in $envFilesPath/sixdeskenv."
	sixdeskmess -1
	sixdeskexit 6
    fi

    # - study:
    #   . make sure we have one in sixdeskenv
    if [ -z "${LHCDescrip}" ] ; then
	sixdeskmess -1 "LHCDescrip not declared in $envFilesPath/sixdeskenv!!!"
	sixdeskmess -1 
	sixdeskexit 7
    fi
    #   . make sure it corresponds to the expected one
    if ${lload} ; then
	if [ "${LHCDescrip}" != "${currStudy}" ] ; then
	    sixdeskmess -1 "Study mismatch: ${LHCDescrip} (from sixdeskenv) different from $currStudy (command-line argument)!!!"
	    sixdeskmess -1
	    sixdeskexit 8
	fi
    fi

    return 0
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
lset=false
lload=false
lcptemplate=false
loverwrite=true
lverbose=false
currPlatform=""
currStudy=""

# get options (heading ':' to disable the verbose error handling)
while getopts  ":hsvd:ep:n" opt ; do
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
if ! ${lset} && ! ${lload} && ! ${lcptemplate} ; then
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
	echo ""
	echo "--> brand new study: -p option with argument ${currPlatform} is switched off."
	echo ""
	currPlatform=""
    fi
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

export sixdeskhostname=`hostname`
export sixdeskname=`basename $0`
export sixdeskroot=`basename $PWD`
export sixdeskwhere=`dirname $PWD`
# Set up some temporary values until we execute sixdeskenv/sysenv
# Don't issue lock/unlock debug text (use 2 for that)
export sixdesklogdir=""
#export sixdesklevel=1
export sixdeskhome="."
export sixdeskecho="yes!"
if [ ! -s ${SCRIPTDIR}/bash/dot_profile ] ; then
    echo "dot_profile is missing!!!"
    exit 1
fi
# - load environment
source ${SCRIPTDIR}/bash/dot_profile
# - settings for sixdeskmessages
sixdeskmessleveldef=0
sixdeskmesslevel=$sixdeskmessleveldef
# - locking dirs
if ${lcptemplate} ; then
    lockingDirs=( . )
else
    lockingDirs=( . studies )
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
    sixdeskexit 1
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
    sixdeskmess 1
    sixdeskmess -1 "template input files from ${SCRIPTDIR}/templates/input"
    sixdeskmess 1

    for tmpFile in sixdeskenv sysenv ; do
	sixdeskmess -1 "${tmpFile}"
	sixdeskmess 1
	# preserve original time stamps
	cp -p ${SCRIPTDIR}/templates/input/${tmpFile} .
    done

else

    # - make sure we have sixdeskenv/sysenv files
    sixdeskInspectPrerequisites ${lverbose} $envFilesPath -s sixdeskenv sysenv
    if [ $? -gt 0 ] ; then
	sixdeskexit 4
    fi

    # - source active sixdeskenv/sysenv
    source ${envFilesPath}/sixdeskenv
    source ${envFilesPath}/sysenv

    if ${loutform}; then
	sixdesklevel=${sixdesklevel_option}
    fi    

    # - perform some consistency checks on parsed info
    consistencyChecks

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
		sixdeskmess -1
	    else
 	        # updating an existing study
		sixdeskmess -1 "Updated sixdeskenv/sysenv for $LHCDescrip"
		sixdeskmess -1
	    fi
	elif ${lload} ; then
	    cp ${envFilesPath}/sixdeskenv .
	    cp ${envFilesPath}/sysenv .
	    sixdeskmess -1 "Switched to study $LHCDescrip"
	    sixdeskmess -1
	fi
    fi

    # - overwrite platform
    if [ -n "${currPlatform}" ] ; then
	platform=$currPlatform
    fi
    sixdeskSetPlatForm $platform

    # - useful output
    PTEXT="[${sixdeskplatform}]"
    STEXT="[${LHCDescrip}]"
    WTEXT="[${workspace}]"
    BTEXT="no BNL flag"
    if [ "$BNL" != "" ] ; then
	BTEXT="BNL flag active"
    fi
    NTEXT="["$sixdeskhostname"]"
    sixdeskmess -1 "Using: Study $STEXT - Worskspace $WTEXT - Platform $PTEXT - Hostname $NTEXT - $BTEXT"
    sixdeskmess -1

    if [ -e "$sixdeskstudy"/deleted ] ; then
	if ${loverwrite} ; then
	    rm -f "$sixdeskstudy"/deleted
	else
	    sixdeskmess -1 "Warning! Study `basename $sixdeskstudy` has been deleted!!! Please restore it explicitely"
	    sixdeskmess -1
	fi
    fi

fi

# - unlock dirs
for tmpDir in ${lockingDirs[@]} ; do
    sixdeskunlock $tmpDir
done

# - kinit, to renew kerberos ticket
sixdeskmess -1 " --> kinit:"
sixdeskmess 1
multipleTrials "kinit -R ; local __exit_status=\$?" "[ \$__exit_status -eq 0 ]"
if [ $? -gt 0 ] ; then
    sixdeskmess -1 "--> kinit -R failed - AFS/Kerberos credentials expired??? aborting..."
    sixdeskmess -1
    exit
else
    sixdeskmess -1 " --> klist output after kinit -R:"
    sixdeskmess 2
    tmpLines=$(klist)
    sixdeskmess -1 "${tmpLines}"
    sixdeskmess 2
fi

# - fs listquota
echo ""
sixdeskmess -1 " --> fs listquota:"
sixdeskmess 2
tmpLines=`fs listquota`
#echo "${tmpLines}"
sixdeskmess -1 "${tmpLines}"
#sixdeskmess 2
#   check, and in case raise a warning
fraction=`echo "${tmpLines}" | tail -1 | awk '{frac=$3/$2*100; ifrac=int(frac); if (frac-ifrac>0.5) {ifrac+=1} print (ifrac)}'`
if [ ${fraction} -gt 90 ] ; then
    sixdeskmess -1 "WARNING: your quota is above 90%!! pay attention to occupancy of the current study, in case of submission..."
    sixdeskmess -1
fi

