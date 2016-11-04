#!/bin/bash

function how_to_use() {
    cat <<EOF

   `basename $0` [action] [option]
   to set up the SixDesk environment

   actions (mandatory, one of the following):
   -s              set up new study or update existing one
                   NB: the local sixdeskenv and sysenv will be parsed, used and
                       saved in studies/
   -d <study_name> load existing study. In this case, the -d option is mandatory!
                   NB: the sixdeskenv and sysenv in studies/<study_name> will
                       be parsed, used and saved in sixjobs

   options (optional)
   -p      platform name (when running many jobs in parallel)
   -e      just parse the concerned sixdeskenv/sysenv files, without
               overwriting

EOF
}

function preliminaryChecks(){

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
	sixdeskInspectPrerequisites studies -d
    fi
    if [ $? -gt 0 ] ; then
	sixdeskexit 2
    fi

    # - make sure that, in case of loading, we have the concerned directory in studies:
    if ${lload} ; then
	sixdeskInspectPrerequisites studies/${currStudy} -d
	if [ $? -gt 0 ] ; then
	    sixdeskmess="Study $currStudy not found in studies!!!"
	    sixdeskmess
	    sixdeskexit 3
	fi
    fi

    # - make sure we have sixdeskenv/sysenv files
    sixdeskInspectPrerequisites $envFilesPath -s sixdeskenv sysenv
    if [ $? -gt 0 ] ; then
	sixdeskexit 4
    fi

    # - make sure we are in the correct workspace
    local __cworkspace=`basename $sixdeskwhere`
    local __workspace=`egrep "^ *export *workspace=" $envFilesPath/sixdeskenv | tail -1 | sed -e 's/\(.*=\)\([^ ]*\)\(.*\)/\2/'`
    if [ -z "${__workspace}" ] ; then
	sixdeskmess="Couldn't find a workspace in $envFilesPath/sixdeskenv!!!"
	sixdeskmess
	sixdeskexit 5
    fi
    if [ "$__workspace" != "$__cworkspace" ] ; then
	sixdeskmess="Workspace mismatch: $__workspace (from sixdeskenv) different from $__cworkspace (from current path)!!!"
	sixdeskmess
	sixdeskmess="Check the workspace definition in $envFilesPath/sixdeskenv."
	sixdeskmess
	sixdeskexit 6
    fi

    # - study:
    #   . make sure we have one in sixdeskenv
    local __LHCDescrip=`egrep "^ *export *LHCDescrip=" $envFilesPath/sixdeskenv | tail -1 | sed -e 's/\(.*=\)\([^ ]*\)\(.*\)/\2/'`
    if [ -z "${__LHCDescrip}" ] ; then
	sixdeskmess="Couldn't find an LHCDescrip in $envFilesPath/sixdeskenv!!!"
	sixdeskmess
	sixdeskexit 7
    fi
    #   . make sure it corresponds to the expected one
    if ${lload} ; then
	if [ "${__LHCDescrip}" != "${currStudy}" ] ; then
	    sixdeskmess="Study mismatch: $__LHCDescrip (from sixdeskenv) different from $currStudy (command-line argument)!!!"
	    sixdeskmess
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
loverwrite=true
currPlatform=""
currStudy=""

# get options (heading ':' to disable the verbose error handling)
while getopts  ":hsd:ep:" opt ; do
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
	e)
	    # do not overwrite
	    loverwrite=false
	    ;;
	p)
	    # the user is requesting a specific platform
	    currPlatform="${OPTARG}"
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
if ! ${lset} && ! ${lload} ; then
    how_to_use
    echo "No action specified!!! aborting..."
    exit
elif ${lset} && ${lload} ; then
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

export sixdeskhostname=`hostname`
export sixdeskname=`basename $0`
export sixdeskroot=`basename $PWD`
export sixdeskwhere=`dirname $PWD`
# Set up some temporary values until we execute sixdeskenv/sysenv
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
lockingDirs=( . studies )
# - path to active sixdeskenv/sysenv
if ${lset} ; then
    envFilesPath="."
elif ${lload} ; then
    envFilesPath="studies/${currStudy}"
fi

# - preliminary checks (i.e. input info is consisten with present workspace)
preliminaryChecks
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

# - source active sixdeskenv/sysenv
source ${envFilesPath}/sixdeskenv
source ${envFilesPath}/sysenv

# - save sixdeskenv/sysenv
if ${loverwrite} ; then
    if ${lset} ; then
        # We now call update_sixjobs in case there were changes
        #    and to create for example the logfile directories
	source ${SCRIPTDIR}/bash/update_sixjobs
        # and now we can check 
	source ${SCRIPTDIR}/bash/check_envs
	cp ${envFilesPath}/sixdeskenv studies/${LHCDescrip}
	cp ${envFilesPath}/sysenv studies/${LHCDescrip}
	if [ -d studies/${LHCDescrip} ] ; then
	    # updating an existing study
	    sixdeskmess="Updated sixdeskenv/sysenv for $LHCDescrip"
	    sixdeskmess
	else
	    # new study
	    sixdeskmess="Created a NEW study $LHCDescrip"
	    sixdeskmess
	    mkdir studies/${LHCDescrip}
	fi
    elif ${lload} ; then
	cp ${envFilesPath}/sixdeskenv .
	cp ${envFilesPath}/sysenv .
	sixdeskmess="Switched to study $LHCDescrip"
	sixdeskmess
    fi
fi

# - overwrite platform
if [ -n "${currPlatform}" ] ; then
    platform=$currPlatform
fi
sixdeskSetPlatForm $platform

# - useful output
PTEXT="["$sixdeskplatform"]"
STEXT="["$LHCDescrip"]"
BTEXT=""
if [ "$BNL" != "" ] ; then
  BTEXT=" BNL"
fi
sixdeskmess="Using$BTEXT Study $STEXT Platform $PTEXT"
sixdeskmess

if [ -e "$sixdeskstudy"/deleted ] ; then
    if ${loverwrite} ; then
	rm "$sixdeskstudy"/deleted
    else
	sixdeskmess="Warning! Study `basename $sixdeskstudy` has been deleted!!! Please restore it explicitely"
	sixdeskmess
    fi
fi

# - unlock dirs
for tmpDir in ${lockingDirs[@]} ; do
    sixdeskunlock $tmpDir
done

