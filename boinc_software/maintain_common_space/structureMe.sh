#!/bin/bash

function setUpDir(){
    local __Dir=$1
    local __OrigRepo=$2
    local __branch=$3
    local __commitSDBid=$4
    local __commitID=$5
    echo ""
    local __origDir=$PWD
    # echo at startup
    echo -e "\n\n"
    printf "=%.0s" {1..80}
    echo ""
    echo " running setUpDir() in `basename $0` at `date` for dir ${__Dir}"
    if ${lScripts} ; then
	# present commit in ${__Dir}
	if [ -d ${__Dir} ] ; then
	    cd ${__Dir}
	    local __oldTmpLogLines=`git log --max-count=1`
	    local __oldTmpBranchLines=`git branch`
	    cd - 2>&1 > /dev/null
	fi
	# clean
	rm -rf ${__Dir}
	mkdir ${__Dir}
	cd ${__Dir}
	echo "treating ${__Dir} - date: `date` - origin: ${__OrigRepo} - branch: ${__branch} - commit: ${__commitID}"
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
	git checkout ${__branch}
	if [ -n "${__commitID}" ] ; then
	    # . required - see https://stackoverflow.com/questions/2007662/rollback-to-an-old-git-commit-in-a-public-repo
	    git checkout ${__commitID} .
	fi
	# get last log
	local __newTmpLogLines=`git log --max-count=1`
	local __newTmpBranchLines=`git branch`
	cd ${__origDir}
    fi
    if ${lSixDB} ; then
	cd ${__Dir}
	if [ -d utilities/externals/SixDeskDB ] ; then
	    rm -rf utilities/externals/SixDeskDB
	    mkdir -p utilities/externals/SixDeskDB
	fi
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
	cd utilities/externals/SixDeskDB
	[ -n "${__commitSDBid}" ] || __commitSDBid='master'
	git checkout ${__commitSDBid}
	cd ${__origDir}
    fi
    if ${lScripts} ; then
	# make fortran exes for checking fort.10
	cd ${__Dir}
	cd utilities/fortran
	make
	ls -ltrh
	cd ${__origDir}
	# echo commits/logs
	echo ""
	echo " --> present branch:"
	echo "${__newTmpBranchLines}"
	echo " --> present log:"
	echo "${__newTmpLogLines}"
	if [ -n "${__oldTmpLogLines}" ] ; then
	    echo ""
	    echo " --> last but one branch:"
	    echo "${__oldTmpBranchLines}"
	    echo " --> last but one log:"
	    echo "${__oldTmpLogLines}"
	fi
    fi
}

function checkDir(){
    local __Dir=$1
    # echo at startup
    echo -e "\n\n"
    printf "=%.0s" {1..80}
    echo ""
    echo " running checkDir() in `basename $0` at `date` for dir ${__Dir}"
    local __origDir=$PWD
    # checkout of local dir
    cd ${__Dir}
    git log --max-count=1
    cd ${__origDir}
    # compilation of fortran exes
    cd ${__Dir}/utilities/fortran
    ls -ltrh
    cd ${__origDir}
    # checkout of SixDB
    cd ${__Dir}/utilities/externals/SixDeskDB/
    git log --max-count=1
    # go home, man
    cd ${__origDir}
}

lScripts=true
lSixDB=true
lCheck=true

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
branch=(
    'isolateScripts'
    'pro'
    'old'
    'sixtracktest'
)
commitID=(
    ''
    ''
    ''
    ''
)
commitSixDB=(
     ''
     ''
     '372a0daec619c5b8ed337c2bd484684ae58d6a8c'
     ''
)

for (( ii=0; ii<${#SixDeskVer[@]}; ii++ )) ; do
    setUpDir ${SixDeskVer[$ii]} ${originRepo[$ii]} ${branch[$ii]} ${commitSixDB[$ii]} ${commitID[$ii]} 2>&1 | tee -a `basename $0`.log
done

# final checks
if ${lCheck} ; then
    for (( ii=0; ii<${#SixDeskVer[@]}; ii++ )) ; do
	checkDir ${SixDeskVer[$ii]} 2>&1 | tee -a `basename $0`.log
    done
fi
