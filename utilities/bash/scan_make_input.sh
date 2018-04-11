#!/bin/bash

### INITIALIZATION

source ./scan_definitions
source ./sixdeskenv
#source $SixDeskDev/dot_profile

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
if [ ! -s ${SixDeskDev}/dot_profile ] ; then
    echo "${SixDeskDev}"
    echo "dot_profile is missing!!!"
    exit 1
fi

if [ ! -s ${SixDeskDev}/dot_scan ] ; then
    echo "${SixDeskDev}"
    echo "dot_scan is missing!!!"
    exit 1
fi

sixdeskmessleveldef=0
sixdeskmesslevel=$sixdeskmessleveldef

# - load environment
source ${SixDeskDev}/dot_profile
source ${SixDeskDev}/dot_scan

kinit -R


function how_to_use() {
    cat <<EOF
   `basename $0` [action] [option]
    performs actions on the input preparation for a defined set of studies

    actions
    -s      submit MAD jobs for all studies to HTCondor
    -c      check the progress of the MAD-X studies
    -w      submit wrong seeds for all studies (requires to run -c beforehand)
    -U      unlock the directories required to run the script for all studies
    -M      create the mask files for all studies without any additional action

    options
    -A      (additional) arguments for mad6t
              e.g. `basename $0` -s -A "-o 2" will execute mad6t.sh -s -o 2
              alternatively the same functionality can be obtained with
                   `basename $0` -A "-s -o 2"

EOF
}







function generate_mask_file(){

    local _val
    local _j
    local _placeholders=(${scan_placeholders})
    local _placeholder
    local _
    local _tmpmask="mask/${scan_prefix}_temp.mask"

    cp mask/${scan_prefix}.mask ${_tmpmask}              # copy mask template to other name to be working on

    mask_vals=${mask_values[i]:2}                      # read the mask variable values for the particular studies

    IFS='%' read -a values <<< "${mask_vals}"          # split the string

    _j=0
    for _ in ${values[@]}; do                          # replace the individual placeholders in the tmp mask file

	_placeholder=${_placeholders[${_j}]}           # the placeholder to be substituted in the mask file
	_val=${values[${_j}]}                          # the value this placeholder shall be replaced with


	if ${do_placeholder_check}; then                            # check if all placeholders are existing in mask file
	    check_mask_for_placeholder ${_placeholder} ${_tmpmask}
	fi

	sed -i "s/${_placeholder}/${_val}/g" ${_tmpmask}

	((_j++))
    done

    sixdeskmess -1 "Generated mask file: ${study}.mask"
    mv ${_tmpmask} mask/${study}.mask                  # move tmp mask file to definite name


}


function check_mask_for_placeholder(){
    local _placeholder=${1}
    local _tmpmask=${2}


    if ! grep -q "${_placeholder}" "${_tmpmask}"; then

	sixdeskmess -1 "WARNING: Placeholder ${_placeholder} not found in raw mask file ${_tmpmask}!"
	sixdeskmess -1 "Continue? [y/n]"
	mask_integrity_error_message
    fi
}



function mask_integrity_error_message(){
	read answer
	case ${answer} in
	    [yY] | [yY][Ee][Ss] )
		sixdeskmess -1 "Continuing..."
		do_placeholder_check=false
                ;;

	    [nN] | [n|N][O|o] )
                sixdeskmess -1  "Interrupted, please modify mask file or check scan_definitions";
                exit 1
                ;;
	    *) sixdeskmess -1 "Invalid input"
	       ;;
	esac
}


function doCommand(){
    echo "running command" ${1}
    ${1}
}


function runmad6t(){
    _cmnd="${SixDeskDev}/mad6t.sh"

    # this part could be done in getopts but it's clearer to do it here
    if ${lsubmit}; then
	_cmnd="${_cmnd} -s"
    elif ${lcheck}; then
	_cmnd="${_cmnd} -c"
    elif ${lwrongseeds}; then
	_cmnd="${_cmnd} -w"
    elif ${lunlock}; then
	_cmnd="${_cmnd} -U"
    fi

    if ${laddargs}; then
	_cmnd="${_cmnd} ${addargs}"
    fi

    doCommand "${_cmnd}"

}




lcreatemask=false
lsubmit=false
lrerun=false
lcheck=false
laddargs=false
addargs=""
lwrongseeds=false
lunlock=false

do_placeholder_check=true


while getopts  "hrmcMpsA:wU" opt ; do
    case $opt in
	s)
	    lsubmit=true
	    ;;
	c)
	    lcheck=true
	    ;;
	U)
	    lunlock=true
	    ;;
	w)
	    lwrongseeds=true
	    ;;
	m)  findmissing=true
	    ;;
	M)  lcreatemask=true
	    ;;
	A)
	    laddargs=true
	    addargs=${OPTARG}
	    ;;
	h)
	    how_to_use
	    exit 1
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


if ! ${lsubmit} && ! ${lcreatemask} && ! ${lrerun} && ! ${lcheck} && ! ${laddargs} && ! ${lunlock} && ! ${lwrongseeds}; then
    sixdeskmess -1 "ERROR: no action specified"
    how_to_use
    exit 1
fi


if ${lcreatemask}; then
    sixdeskmess 1 "Creating mask file"
    scan_loop generate_mask_file
fi


if ${lsubmit} || ${laddargs}; then
    scan_loop generate_mask_file
    scan_loop runmad6t
fi

if ${lcheck} || ${lwrongseeds} || ${lunlock}; then
    scan_loop runmad6t
fi






exit
