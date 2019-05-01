#!/bin/bash

# do not forget to:
# - remove signs of fort.6 from sixtrack_res_template.xml
# - remove signs of fort.6 from run_results
# - sixtracktest in utilities/doc/sixdesk.tex

sixtrackVer=(
    "spooldir=/afs/cern.ch/work/b/boinc/boinc"
    "applicationDef=sixtrack"
    "fullAppName=sixtrack"
    "export appName=sixtrack"
    "export appNameDef=sixtrack"
#    "\\newcommand\{\\whichSixTrack\}\{sixtrack\}"
)
sixtracktestVer=(
    "spooldir=/afs/cern.ch/work/b/boinc/boinctest"
    "applicationDef=sixtracktest"
    "fullAppName=sixtracktest"
    "export appName=sixtracktest"
    "export appNameDef=sixtracktest"
#    "\\newcommand\{\\whichSixTrack\}\{sixtracktest\}"
)
sedFiles=(
    "boinc_software/cronjobs/cron.submit-simo3"
    "boinc_software/cronjobs/cron.submit-simo3"
    "boinc_software/sign_exes/gen-apps-structure.sh"
    "sixjobs/sysenv"
    "sixjobs/sixdeskenv"
#    "utilities/doc/sixdesk.tex"
)

if [ ${#sixtrackVer[@]} -ne ${#sixtracktestVer[@]} ] ; then
    echo " sixtrackVer and sixtracktestVer have different lengths! aborting..."
    exit 1
elif [ ${#sixtrackVer[@]} -ne ${#sedFiles[@]} ] ; then
    echo " sixtrackVer and sedFiles have different lengths! aborting..."
    exit 1
else
    for (( ii=0; ii<${#sixtrackVer[@]}; ii++ )) ; do
        echo " replacing ${sixtracktestVer[$ii]} with ${sixtrackVer[$ii]} in ${sedFiles[$ii]} ..."
        sed -i "s?${sixtracktestVer[$ii]}?${sixtrackVer[$ii]}?" ${sedFiles[$ii]}
    done
fi
    
