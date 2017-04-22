#!/bin/bash

# example of tree structure:
# /data/boinc/project/sixtrack/apps/<app_name>
#   |_ gen-apps-structure.sh                    this script
#   |_ <dir_with_new_unsigned_exes>             any name
#   |     |_ <exe1>
#   |     |_ <exe2>
#   |     |_ ...
#   |_ $VER                                     tag of version   \
#       |_ <boinc_platform_1>                      dir           |
#       |    |_ <signed_exe>                       exe           | created by
#       |    |_ <signed_exe>.sig                   signature     |  this script
#       |_ <boinc_platform_2>                                    |
#       |    |_ <signed_exe>                       exe           |
#       |    |_ <signed_exe>.sig                   signature     |
#       |_ ...                                                  /

PROJ=/data/boinc/project/sixtrack
dir_unsigned=/afs/cern.ch/user/k/kyrsjo/public/BOINC-release/execs-v6
VER=46.14
VS=4614
commonFlags="libarchive_bignblz_cr_boinc_api_crlibm_fast_tilt_cmake"
lcheckOnly=true
projXml=../xml/project.xml

signit()
{
    # interface:
    #   signit <boinc_platform> <exe_to_be_signed> <signed_exe>
    local __dir=$VER/$1
    local __exe=$2
    local __app=$3
    local __lerr=0
    local __platform=`echo $1 | sed 's#__.*##'`
  
    if [ ! -e ${dir_unsigned}/${__exe} ] ; then
	echo "unsigned exe ${dir_unsigned}/${__exe} does not exist!"
	let __lerr+=1
    fi
    local __BOINCplatform=`grep '\<name\>' ${projXml} | cut -d\< -f2 | cut -d\> -f2 | grep ${__platform} 2> /dev/null`
    if [ -z "${__BOINCplatform}" ] ; then
	echo "unknonw platform in ${1}"
	let __lerr+=1
    fi
    if ${lcheckOnly} ; then
	return ${__lerr}
    fi
    echo "signing exe: ${__dir} ${__exe} ${__app}" >> ${__dir}/README
    [ ! -d ${__dir} ] || mkdir -p ${__dir}
    cp -u ${dir_unsigned}/${__exe} ${__dir}/${__app}
    # actually sign:
    cd ${__dir}
    echo "GEN SIGN:"
    $PROJ/bin/sign_executable ${__app} $PROJ/keys/code_sign_private >${__app}.sig
    ls
    pwd
    cd -
    echo "_____________________________________________"
    echo ""
    return ${__lerr}
}

if ! ${lcheckOnly} ; then
    echo "running `basename $0` at `date`" > ${__dir}/README
    echo "unsigned exes from: ${dir_unsigned}" >> ${__dir}/README
    echo "version: ${VER} - ${VS}" >> ${__dir}/README
fi

#__________________________________________________ linux   32 bit ______________________________________________
signit i686-pc-linux-gnu__sse2          SixTrack_${VS}_${commonFlags}_Linux_gfortran_static_i686_32bit                  sixtrack_lin32_${VS}_sse2.linux
#__________________________________________________ linux   64 bit ______________________________________________
signit x86_64-pc-linux-gnu__sse2        SixTrack_${VS}_${commonFlags}_Linux_gfortran_static_x86_64_64bit                sixtrack_lin64_${VS}_sse2.linux
signit x86_64-pc-linux-gnu__avx         SixTrack_${VS}_${commonFlags}_Linux_gfortran_static_avx_x86_64_64bit            sixtrack_lin64_${VS}_avx.linux
#__________________________________________________ linux   AARM64 ______________________________________________
signit aarch64-android-linux-gnu__sse2  SixTrack_${VS}_${commonFlags}_Linux_gfortran-6_static_aarch64_64bit             sixtrack_lin64_${VS}_sse2.linux
signit aarch64-unknown-linux-gnu__sse2  SixTrack_${VS}_${commonFlags}_Linux_gfortran-6_static_aarch64_64bit             sixtrack_lin64_${VS}_avx.linux


#__________________________________________________ mac     64 bit ______________________________________________
signit x86_64-apple-darwin              SixTrack_${VS}_${commonFlags}_Darwin_gfortran_static_x86_64_64bit               sixtrack_darwin_${VS}_gen.exe
signit x86_64-apple-darwin__avx         SixTrack_${VS}_${commonFlags}_Darwin_gfortran_static_avx_x86_64_64bit           sixtrack_darwin_${VS}_avx.exe


#__________________________________________________ win     32 bit ______________________________________________
signit windows_intelx86__sse2           SixTrack_${VS}_${commonFlags}_Windows_gfortran.exe_static_AMD64_32bit.exe       sixtrack_win32_${VS}_sse2.exe
#__________________________________________________ win     64 bit ______________________________________________
signit windows_x86_64__sse2             SixTrack_${VS}_${commonFlags}_Windows_gfortran.exe_static_AMD64_64bit.exe       sixtrack_win64_${VS}_sse2.exe
signit windows_x86_64__avx              SixTrack_${VS}_${commonFlags}_Windows_gfortran.exe_static_avx_AMD64_64bit.exe   sixtrack_win64_${VS}_avx.exe

#__________________________________________________ freeBSD 64 bit ______________________________________________
signit x86_64-pc-freebsd__sse2          SixTrack_${VS}_${commonFlags}_FreeBSD_gfortran_static_amd64_64bit               sixtrack_freeBSD64_${VS}_sse2.exe
signit x86_64-pc-freebsd__avx           SixTrack_${VS}_${commonFlags}_FreeBSD_gfortran_static_avx_amd64_64bit           sixtrack_freeBSD64_${VS}_avx.exe


#__________________________________________________ netBSD 64 bit _______________________________________________
signit x86_64-pc-netbsd__sse2           SixTrack_${VS}_${commonFlags}_NetBSD_gfortran_static_x86_64_64bit               sixtrack_netBSD64_${VS}_sse2.exe
signit x86_64-pc-netbsd__avx            SixTrack_${VS}_${commonFlags}_NetBSD_gfortran_static_avx_x86_64_64bit           sixtrack_netBSD64_${VS}_avx.exe


#___________________ finalize ________________
if ! ${lcheckOnly} ; then
    chown -R lhcathom.boinc $VER
fi

