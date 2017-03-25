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
dir_unsigned=mcintosh
VER=451.7
VS=4517

signit()
{
    # interface:
    #   signit <boinc_platform> <exe_to_be_signed> <signed_exe>
    local __dir=$VER/$1
    local __exe=$2
    local __app=$3
  
    if [ ! -d ${__dir} ] ; then
        echo "make directory ${__dir} "
   	mkdir -p ${__dir}
    else
        echo "directory ${__dir} exists"
    fi
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
}

#__________________________________________________ linux  32 bit ______________________________________________
signit i686-pc-linux-gnu          SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_ia32_O2.linux     sixtrack_lin32_${VS}_gen.linux
signit i686-pc-linux-gnu__sse2    SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse2_O2.linux     sixtrack_lin32_${VS}_sse2.linux
signit i686-pc-linux-gnu__sse3    SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.linux     sixtrack_lin32_${VS}_sse3.linux
signit i686-pc-linux-gnu__pni     SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.linux     sixtrack_lin32_${VS}_pni.linux

#__________________________________________________ linux  64 bit ______________________________________________
signit x86_64-pc-linux-gnu        SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_ia32_O2.linux     sixtrack_lin64_${VS}_gen.linux
signit x86_64-pc-linux-gnu__sse2  SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse2_O2.linux     sixtrack_lin64_${VS}_sse2.linux
signit x86_64-pc-linux-gnu__sse3  SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.linux     sixtrack_lin64_${VS}_sse3.linux
signit x86_64-pc-linux-gnu__pni   SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.linux     sixtrack_lin64_${VS}_pni.linux

#__________________________________________________ darwin  64 bit ______________________________________________
#signit x86_64-apple-darwin        SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_O2.darwin         sixtrack_darwin_${VS}_gen.exe

#__________________________________________________ windows 64 bit ______________________________________________
signit windows_x86_64             SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_ia32_O2.exe       sixtrack_win64_${VS}_gen.exe
signit windows_x86_64__sse2       SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse2_O2.exe       sixtrack_win64_${VS}_sse2.exe
signit windows_x86_64__sse3       SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.exe       sixtrack_win64_${VS}_sse3.exe
signit windows_x86_64__pni        SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.exe       sixtrack_win64_${VS}_pni.exe

#__________________________________________________ windows 32 bit ______________________________________________
signit windows_intelx86           SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_ia32_O2.exe       sixtrack_win32_${VS}_gen.exe
signit windows_intelx86__sse2     SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse2_O2.exe       sixtrack_win32_${VS}_sse2.exe
signit windows_intelx86__sse3     SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.exe       sixtrack_win32_${VS}_sse3.exe
signit windows_intelx86__pni      SixTrack_${VS}_crlibm_bnl_ifort_boinc_api_sse3_O2.exe       sixtrack_win32_${VS}_pni.exe

#___________________ finalize ________________
chown -R lhcathom.boinc $VER

