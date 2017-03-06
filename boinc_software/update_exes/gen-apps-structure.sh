#!/bin/sh

PROJ=/share/boinc/project/sixtrack
VER=466.0
VS=466

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
    cp -u 2017-02_compiled/$exe $dir/$app
    ( cd $dir;  echo "GEN SIGN:"; $PROJ/bin/sign_executable $app $PROJ/keys/code_sign_private >$app.sig; ls; pwd; )
    echo "_____________________________________________"
    echo ""
}

#__________________________________________________ linux   32 bit ______________________________________________
#signit i686-pc-linux-gnu          SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_ia32_O2.linux sixtrack_lin32_${VS}_gen.linux
signit i686-pc-linux-gnu__sse2    SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_Linux_gfortran_static_i686_32bit              sixtrack_lin32_${VS}_sse2.linux
#signit i686-pc-linux-gnu__sse3    SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_sse3_O2.linux sixtrack_lin32_${VS}_sse3.linux
#signit i686-pc-linux-gnu__pni     SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_sse3_O2.linux sixtrack_lin32_${VS}_pni.linux

#__________________________________________________ linux   64 bit ______________________________________________
#signit x86_64-pc-linux-gnu        SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_ia32_O2.linux sixtrack_lin64_${VS}_gen.linux
signit x86_64-pc-linux-gnu__sse2  SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_Linux_gfortran_static_x86_64_64bit            sixtrack_lin64_${VS}_sse2.linux
#signit x86_64-pc-linux-gnu__sse3  SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_sse3_O2.linux sixtrack_lin64_${VS}_sse3.linux
#signit x86_64-pc-linux-gnu__pni   SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_sse3_O2.linux sixtrack_lin64_${VS}_pni.linux

#__________________________________________________ freeBSD 64 bit ______________________________________________
signit i386-pc-freebsd__sse2      SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_FreeBSD_gfortran_static_amd64_64bit           sixtrack_freeBSD64_${VS}_sse2

#__________________________________________________ darwin  64 bit ______________________________________________
signit x86_64-apple-darwin        SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_Darwin_gfortran_static_x86_64_64bit           sixtrack_darwin_${VS}_gen.exe

#__________________________________________________ windows 64 bit ______________________________________________
#signit windows_x86_64             SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_ia32_O2.exe   sixtrack_win64_${VS}_gen.exe
signit windows_x86_64__sse2       SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_Windows_gfortran.exe_static_AMD64_64bit.exe   sixtrack_win64_${VS}_sse2.exe
#signit windows_x86_64__sse3       SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_sse3_O2.exe   sixtrack_win64_${VS}_sse3.exe
#signit windows_x86_64__pni        SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_sse3_O2.exe   sixtrack_win64_${VS}_pni.exe

#__________________________________________________ windows 32 bit ______________________________________________
#signit windows_intelx86           SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_ia32_O2.exe   sixtrack_win32_${VS}_gen.exe
signit windows_intelx86__sse2     SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_Windows_gfortran.exe_static_AMD64_32bit.exe   sixtrack_win32_${VS}_sse2.exe
#signit windows_intelx86__sse3     SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_sse3_O2.exe   sixtrack_win32_${VS}_sse3.exe
#signit windows_intelx86__pni      SixTrack_${VS}_libarchive_cr_boinc_api_crlibm_fast_tilt_cmake_sse3_O2.exe   sixtrack_win32_${VS}_pni.exe

#___________________ finalize ________________
chgrp -R boinc $VER

