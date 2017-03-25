#!/bin/sh

PROJ=/data/boinc/project/sixtrack
VER=451.7
VS=4517

signit()
{
    dir=$VER/$1
    exe=$2
    app=$3
  
    if [ ! -d $dir ]
    then
        echo "make directory $dir "
   	mkdir -p $dir
    else
        echo "directory $dir exists"
    fi
    cp -u mcintosh/$exe $dir/$app
    ( cd $dir;  echo "GEN SIGN:"; $PROJ/bin/sign_executable $app $PROJ/keys/code_sign_private >$app.sig; ls; pwd; )
    echo "_____________________________________________"
    echo ""
}

#__________________________________________________ linux  32 bit ______________________________________________
signit i686-pc-linux-gnu          SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_ia32_O2.linux sixtrack_lin32_${VS}_gen.linux
signit i686-pc-linux-gnu__sse2    SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse2_O2.linux sixtrack_lin32_${VS}_sse2.linux
signit i686-pc-linux-gnu__sse3    SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.linux sixtrack_lin32_${VS}_sse3.linux
signit i686-pc-linux-gnu__pni     SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.linux sixtrack_lin32_${VS}_pni.linux

#__________________________________________________ linux  64 bit ______________________________________________
signit x86_64-pc-linux-gnu        SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_ia32_O2.linux sixtrack_lin64_${VS}_gen.linux
signit x86_64-pc-linux-gnu__sse2  SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse2_O2.linux sixtrack_lin64_${VS}_sse2.linux
signit x86_64-pc-linux-gnu__sse3  SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.linux sixtrack_lin64_${VS}_sse3.linux
signit x86_64-pc-linux-gnu__pni   SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.linux sixtrack_lin64_${VS}_pni.linux

#__________________________________________________ darwin  64 bit ______________________________________________
#signit x86_64-apple-darwin        SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_O2.darwin     sixtrack_darwin_${VS}_gen.exe

#__________________________________________________ windows 64 bit ______________________________________________
signit windows_x86_64             SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_ia32_O2.exe   sixtrack_win64_${VS}_gen.exe
signit windows_x86_64__sse2       SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse2_O2.exe   sixtrack_win64_${VS}_sse2.exe
signit windows_x86_64__sse3       SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.exe   sixtrack_win64_${VS}_sse3.exe
signit windows_x86_64__pni        SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.exe   sixtrack_win64_${VS}_pni.exe

#__________________________________________________ windows 32 bit ______________________________________________
signit windows_intelx86           SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_ia32_O2.exe   sixtrack_win32_${VS}_gen.exe
signit windows_intelx86__sse2     SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse2_O2.exe   sixtrack_win32_${VS}_sse2.exe
signit windows_intelx86__sse3     SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.exe   sixtrack_win32_${VS}_sse3.exe
signit windows_intelx86__pni      SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.exe   sixtrack_win32_${VS}_pni.exe

#___________________ finalize ________________
chown -R lhcathom.boinc $VER

