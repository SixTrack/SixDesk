#!/bin/bash

function setUpDir(){
    local __Dir=$1
    local __OrigRepo=$2
    local __checkOut=$3
    echo ""
    echo "treating ${__Dir} - origin: ${__OrigRepo} - checkout: ${__checkOut}"
    local __origDir=$PWD
    # clean
    rm -rf ${__Dir}
    mkdir ${__Dir}
    cd ${__Dir}
    echo "treating ${__Dir} - date: `date` - origin: ${__OrigRepo} - checkout: ${__checkOut}" > .origin.txt
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
EOF
    # add proper remote
    git remote add -f origin ${__OrigRepo}
    # actually checkout
    git checkout ${__checkOut}
    # make fortran exes for checking fort.10
    cd utilities/fortran
    make
    ls -ltrh
    cd ${__origDir}
}

SixDeskVer=( 'dev' 'pro' 'old' )
originRepo=(
    'https://github.com/amereghe/SixDesk.git'
    'https://github.com/amereghe/SixDesk.git'
    'https://github.com/amereghe/SixDesk.git'
    )
checkout=(
    'includingHTCondor'
    '27dc8b0b67783d4553d8b1d243364dd18f3a10f7'
    '09a5ac07a2e64668d1994e119c973106583433be'
)

for (( ii=0; ii<3; ii++ )) ; do
    setUpDir ${SixDeskVer[$ii]} ${originRepo[$ii]} ${checkout[$ii]}
done