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
	git checkout ${__commitSDBid}
	if [ "${__commitSDBid}" == "master" ] ; then
	    git pull
	fi
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

lScripts=false
lSixDB=true

SixDeskVer=(
    'dev'
    'pro'
#    'old'
#    'test'
)
originRepo=(
    'https://github.com/amereghe/SixDesk.git'
    'https://github.com/amereghe/SixDesk.git'
    'https://github.com/amereghe/SixDesk.git'
    'https://github.com/amereghe/SixDesk.git'
)
branch=(
    'isolateScripts'
    'isolateScripts'
    'isolateScripts'
#    'a09128ed4a904002f49ed788d9158fe4f8d12409'
    'sixtracktest'
)
commitID=(
    ''
    ''
    ''
    ''
)
commitSixDB=(
    'b7c99755018267bcf20e769ea93d7719e7207643'
    '372a0daec619c5b8ed337c2bd484684ae58d6a8c'
    '372a0daec619c5b8ed337c2bd484684ae58d6a8c'
    '372a0daec619c5b8ed337c2bd484684ae58d6a8c'
)

for (( ii=0; ii<${#SixDeskVer[@]}; ii++ )) ; do
    setUpDir ${SixDeskVer[$ii]} ${originRepo[$ii]} ${branch[$ii]} ${commitSixDB[$ii]} ${commitID[$ii]} 2>&1 | tee -a `basename $0`.log
done
