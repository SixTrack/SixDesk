#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [action] [option]
   to set up the SixDesk environment

   actions (mandatory, one of the following):
   -s              set up new study or update existing one according to local
                       version of input files (sixdeskenv/sysenv/fort.3.local)
                   NB: the local input files will be parsed, used and
                       saved in studies/
   -d <study_name> load existing study.
                   NB: the input files (sixdeskenv/sysenv/fort.3.local) in
                       studies/<study_name> will be parsed, used and saved in
                       sixjobs
   -n              retrieve input files (sixdeskenv/sysenv/fort.3.local) from
                       template dir to prepare a brand new study. The template
                       files will OVERWRITE the local ones. The template dir is:
           ${SCRIPTDIR}/templates/input

   options (optional)
   -p      platform name (when running many jobs in parallel)
   -e      just parse the concerned sixdeskenv/sysenv/fort.3.local files,
               without overwriting
   -l      use fort.3.local
   -v      verbose (OFF by default)

EOF
}

function basicChecks(){

    # - running dir
    if [ "$sixdeskroot" != "sixjobs" ] ; then
	sixdeskmess="This script must be run in the directory sixjobs!!!"
	sixdeskmess
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
	    sixdeskmess="Dir containing input files for study $currStudy not found!!!"
	    sixdeskmess
	    sixdeskmess="Expected: ${envFilesPath}"
	    sixdeskmess
	    sixdeskexit 3
	fi
    fi

    return 0
}

function consistencyChecks(){

    # - make sure we are in the correct workspace
    if [ -z "${workspace}" ] ; then
	sixdeskmess="Workspace not declared in $envFilesPath/sixdeskenv!!!"
	sixdeskmess
	sixdeskexit 5
    fi
    local __cworkspace=`basename $sixdeskwhere`
    if [ "${workspace}" != "${__cworkspace}" ] ; then
	sixdeskmess="Workspace mismatch: ${workspace} (from sixdeskenv) different from ${__cworkspace} (from current path)!!!"
	sixdeskmess
	sixdeskmess="Check the workspace definition in $envFilesPath/sixdeskenv."
	sixdeskmess
	sixdeskexit 6
    fi

    # - study:
    #   . make sure we have one in sixdeskenv
    if [ -z "${LHCDescrip}" ] ; then
	sixdeskmess="LHCDescrip not declared in $envFilesPath/sixdeskenv!!!"
	sixdeskmess
	sixdeskexit 7
    fi
    #   . make sure it corresponds to the expected one
    if ${lload} ; then
	if [ "${LHCDescrip}" != "${currStudy}" ] ; then
	    sixdeskmess="Study mismatch: ${LHCDescrip} (from sixdeskenv) different from $currStudy (command-line argument)!!!"
	    sixdeskmess
	    sixdeskexit 8
	fi
    fi

    # - sixtrack app name
    sixDeskCheckAppName ${appName}
    if [ $? -ne 0 ] ; then
	sixdeskexit 9
    fi

    return 0
}

function getInfoFromFort3Local(){
    export fort3localLines=`cat ${envFilesPath}/fort.3.local`
    local __activeLines=`echo "${fort3localLines}" | grep -v '/'`
    local __firstActiveBlock=`echo "${__activeLines}" | head -1 | cut -c1-4`
    local __otherActiveBlocks=`echo "${__activeLines}" | grep -A1 NEXT | grep -v NEXT | grep -v '^\-\-' | cut -c1-4`
    local __allActiveBlocks="${__firstActiveBlock} ${__otherActiveBlocks}"
    __allActiveBlocks=( ${__allActiveBlocks} )
    if [ ${#__allActiveBlocks[@]} -gt 0 ] ; then
	sixdeskmess="active blocks in ${envFilesPath}/fort.3.local:"
	sixdeskmess
	for tmpActiveBlock in ${__allActiveBlocks[@]} ; do
	    sixdeskmess="- ${tmpActiveBlock}"
	    sixdeskmess
	done
	local __nLines=`echo "${__activeLines}" | wc -l`
	sixdeskmess="for a total of ${__nLines} ACTIVE lines."
	sixdeskmess
	for tmpActiveBlock in ${__allActiveBlocks[@]} ; do
	    if [ "${tmpActiveBlock}" == "ZIPF" ] ; then
		lZIPF=true
		break
	    fi
	done
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
lset=false
lload=false
lcptemplate=false
loverwrite=true
lverbose=false
llocalfort3=false
currPlatform=""
currStudy=""
# variables set based on parsing fort.3.local
lZIPF=false

# get options (heading ':' to disable the verbose error handling)
while getopts  ":hsvld:ep:n" opt ; do
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
	l)
	    # use fort.3.local
	    llocalfort3=true
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
if ${llocalfort3} ; then
    echo ""
    echo " --> User requested inclusion of fort.3.local"
    echo ""
fi

# ------------------------------------------------------------------------------
# preparatory steps
# ------------------------------------------------------------------------------

export sixdeskhostname=`hostname`
export sixdeskname=`basename $0`
export sixdeskroot=`basename $PWD`
export sixdeskwhere=`dirname $PWD`
# Set up some temporary values until we parse input files
# Don't issue lock/unlock debug text (use 2 for that)
export sixdesklogdir=""
export sixdesklevel=1
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
# - path to input files
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

    sixdeskmess="copying here template files for brand new study"
    sixdeskmess
    sixdeskmess="template input files from ${SCRIPTDIR}/templates/input"
    sixdeskmess

    for tmpFile in sixdeskenv sysenv fort.3.local ; do
	sixdeskmess="${tmpFile}"
	sixdeskmess
	# preserve original time stamps
	cp -p ${SCRIPTDIR}/templates/input/${tmpFile} .
    done

else

    # - make sure we have sixdeskenv/sysenv/fort.3.local files
    sixdeskInspectPrerequisites ${lverbose} $envFilesPath -s sixdeskenv sysenv
    exit_status=$?
    if ${llocalfort3} ; then
	sixdeskInspectPrerequisites ${lverbose} $envFilesPath -s fort.3.local
	let exit_status+=$?
    fi
    if [ ${exit_status} -gt 0 ] ; then
	sixdeskexit 4
    fi

    # - source active sixdeskenv/sysenv
    source ${envFilesPath}/sixdeskenv
    source ${envFilesPath}/sysenv
    if ${llocalfort3} ; then
	getInfoFromFort3Local
    fi

    # - perform some consistency checks on parsed info
    consistencyChecks

    # - save input files
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
	    if ${llocalfort3} ; then
		cp ${envFilesPath}/fort.3.local studies/${LHCDescrip}
	    fi
	    if ${__lnew} ; then
  	        # new study
		sixdeskmess="Created a NEW study $LHCDescrip"
		sixdeskmess
	    else
 	        # updating an existing study
		sixdeskmess="Updated sixdeskenv/sysenv(/fort.3.local) for $LHCDescrip"
		sixdeskmess
	    fi
	elif ${lload} ; then
	    cp ${envFilesPath}/sixdeskenv .
	    cp ${envFilesPath}/sysenv .
	    if ${llocalfort3} ; then
		cp ${envFilesPath}/fort.3.local .
	    fi
	    sixdeskmess="Switched to study $LHCDescrip"
	    sixdeskmess
	fi
    fi

    # - overwrite platform
    if [ -n "${currPlatform}" ] ; then
	platform=$currPlatform
    fi
    sixdeskSetPlatForm $platform

    # export lZIPF
    export lZIPF

    # - useful output
    PTEXT="[${sixdeskplatform}]"
    STEXT="[${LHCDescrip}]"
    WTEXT="[${workspace}]"
    BTEXT="no BNL flag"
    if [ "$BNL" != "" ] ; then
	BTEXT="BNL flag active"
    fi
    NTEXT="["$sixdeskhostname"]"
    sixdeskmess="Using: Study $STEXT - Worskspace $WTEXT - Platform $PTEXT - Hostname $NTEXT - $BTEXT"
    sixdeskmess

    if [ -e "$sixdeskstudy"/deleted ] ; then
	if ${loverwrite} ; then
	    rm -f "$sixdeskstudy"/deleted
	else
	    sixdeskmess="Warning! Study `basename $sixdeskstudy` has been deleted!!! Please restore it explicitely"
	    sixdeskmess
	fi
    fi

fi

# - unlock dirs
for tmpDir in ${lockingDirs[@]} ; do
    sixdeskunlock $tmpDir
done

# - kinit, to renew kerberos ticket
sixdeskmess=" --> kinit:"
sixdeskmess
multipleTrials "kinit -R ; local __exit_status=$?" "[ \$__exit_status -eq 0 ]"
if [ $? -gt 0 ] ; then
    sixdeskmess="--> kinit -R failed - AFS/Kerberos credentials expired??? aborting..."
    sixdeskmess
    exit
else
    sixdeskmess=" --> klist output after kinit -R:"
    sixdeskmess
    klist
fi

# - fs listquota
echo ""
sixdeskmess=" --> fs listquota:"
sixdeskmess
tmpLines=`fs listquota`
echo "${tmpLines}"
#   check, and in case raise a warning
fraction=`echo "${tmpLines}" | tail -1 | awk '{frac=$3/$2*100; ifrac=int(frac); if (frac-ifrac>0.5) {ifrac+=1} print (ifrac)}'`
if [ ${fraction} -gt 90 ] ; then
    sixdeskmess="WARNING: your quota is above 90%!! pay attention to occupancy of the current study, in case of submission..."
    sixdeskmess
fi

