#!/bin/bash

function setUpDir(){
    local __Dir=$1
    local __OrigRepo=$2
    local __checkOut=$3
    echo ""
    local __origDir=$PWD
    # echo at startup
    echo -e "\n\n"
    printf "=%.0s" {1..80}
    echo ""
    echo " running setUpDir() in `basename $0` at `date`"
    # present commit in ${__Dir}
    if [ -d ${__Dir} ] ; then
	cd ${__Dir}
	local __oldTmpLogLines=`git log --max-count=1`
	cd - 2>&1 > /dev/null
    fi
    # clean
    rm -rf ${__Dir}
    mkdir ${__Dir}
    cd ${__Dir}
    echo "treating ${__Dir} - date: `date` - origin: ${__OrigRepo} - checkout: ${__checkOut}"
    # init git repo to use sparse checkout and list dirs
    git init
    git config core.sparseCheckout true
    cat > .git/info/sparse-checkout <<EOF
utilities/awk/*
utilities/bash/*
utilities/bats/*
utilities/exes/*
utilities/fortran/*
utilities/gnuplot/*
utilities/perl/lib/*
utilities/python/*
utilities/sed/*
utilities/templates/input/*
utilities/templates/lsf/*
utilities/templates/sussix/*
utilities/templates/htcondor/*
utilities/tex/*
externals/SixDeskDB/*
EOF
    # add proper remote
    git remote add -f origin ${__OrigRepo}
    # actually checkout
    git checkout ${__checkOut}
    # get last log
    local __newTmpLogLines=`git log --max-count=1`
    # update submodules
    if [ ! -e .gitmodules ] ; then
	# patch for odd behaviour with externals in shared AFS location
	cat > .gitmodules <<EOF
[submodule "utilities/externals/SixDeskDB"]
	path = utilities/externals/SixDeskDB
	url = git://github.com/SixTrack/SixDeskDB
EOF
    fi
    git submodule update --init --recursive
    # make fortran exes for checking fort.10
    cd utilities/fortran
    make
    ls -ltrh
    cd ${__origDir}
    # echo commits/logs
    echo ""
    echo " --> present log:"
    echo "${__newTmpLogLines}"
    if [ -n "${__oldTmpLogLines}" ] ; then
	echo ""
	echo " --> last but one log:"
	echo "${__oldTmpLogLines}"
    fi
}

SixDeskVer=(
    'dev'
    'pro'
    'old'
    'test'
)
originRepo=(
    'https://github.com/amereghe/SixDesk.git'
    'https://github.com/amereghe/SixDesk.git'
    'https://github.com/amereghe/SixDesk.git'
    'https://github.com/amereghe/SixDesk.git'
)
checkout=(
    'includingHTCondor'
    'isolateScripts'
    '27dc8b0b67783d4553d8b1d243364dd18f3a10f7'
    'sixtracktest'
)

for (( ii=0; ii<${#SixDeskVer[@]}; ii++ )) ; do
    setUpDir ${SixDeskVer[$ii]} ${originRepo[$ii]} ${checkout[$ii]} 2>&1 | tee -a `basename $0`.log
done
