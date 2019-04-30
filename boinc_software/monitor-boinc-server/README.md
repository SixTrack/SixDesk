# Folder with plotting scripts for monitoring activity on BOINC

This is a collection of quick and dirty bash/gnuplot scripts for monitoring the activity on the boinc server. These scripts are not meant to be final or complete - just to get the data and show them. Scripts written and collected by A.Mereghetti, CERN, BE-ABP-HSS.

Monitoring is achieved via a series on acrontab jobs, which also produce daily plots updated every time the acrontab job is called. At date change, plots and data files are archived. Archiving is performed by months, and summary plots per moth are automatically produced. Plost are in .pdf format.

There are also plotting scripts available to show any time frame of interest for the user.

Folders in the github repo contains only the scripts. Folders with populated data can be found on lxplus.cern.ch, in:
`/afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server`

## `general-activity/`
Folder containing material for monitoring the activity of/on the BOINC server. Activity is monitored mainly via the BOINC status page. The acrontab job downloads the status page at regular time intervals, parses it, saves essential data and plots them.

 This folder contains:
   * `monitorAssimilatorErrors.sh`: monitors assimilator errors (no longer used);
   * `monitorAssimilatorTimeStamp.sh`: monitors assimilator time stamps, to detect periods of inactivity of the assimilator. In case inactivity is detected, a notification email is automatically sent;
   * `monitorBoincServer.sh`: parses the BOINC status page and updates daily plots (bash wrapper);
   * `monitorBoincServerDailyArchive.sh`: archives daily data and updated monthly plots;
   * `parseHTML.py`: parser of BOINC status page;
   * `plotData.gnu`: plots daily data;

## `general-activity/archive`
This folder contains past data, archived by months.
   * `plotData_period.gnu`: plots month data;
   * `plotData_restart.gnu`: plots data with time frame at user's will;
   * `plotPeriod.sh`: bash wrapper to `plotData_period.gnu`;

## `submissions/`
Folder containing material for monitoring the submission/assimilation of WUs/results by the BOINC server. Activity is monitored mainly looking at log giles on the BOINC server. The acrontab job parses the logs at regular time intervals, saves essential data and plots them.
   * `monitorSubmissions.sh`: parses the BOINC submission and assimilation logs and updates daily plots (bash wrapper);
   * `monitorSubmissionsDailyArchive.sh`: archives daily data;
   * `plotData.gnu`: plots daily data;
   * `retrieveData.sh`: retrieves data from the BOINC server;

## `submissions/archive`
This folder contains past data, archived by months. Contrary to the case of `general-activity`, no monthly plots are prepared.
   * `plotData_period.gnu`: plots data with time frame at user's will;

## `validation/validator.py`
A parser of the validator log. It performs some simple statistics on tasks and hosts, in the trial to better understand the process of validation.

## examples
To visulise BOINC activity:
   * of the current day:
```
# please change the date according to the current one 
evince general-activity/status_2019-04-30.pdf &
```
   * for a specific month:
```
# please change the year-month pair according to your needs
evince general-activity/archive/2018-03/status_2018-03.pdf &
```
   * for a any desired time range:
```
cd general-activity/archive
# please modify plotData_restart.gnu according to your needs
gnuplot plotData_restart.gnu
eog ../../boincStatus/serverOverview.png
# please ll ../../boincStatus/ to see all available plots
```

To visulise submission/assimilation on BOINC:
   * of the current day:
```
# please change the date according to the current one 
evince submissions/submitAll_2019-04-30.pdf &
```
   * for a any desired time range:
```
cd submissions/archive
# please modify plotData_period.gnu according to your needs
gnuplot plotData_period.gnu
eog ../../boincStatus/submissionCumulative.png &
# please ll ../../boincStatus/ to see all available plots
```


## acrontab jobs
An example of acrontab jobs:
```
# new scripts for monitoring BOINC server:
# - server status and plotting;
# - archiving plots/data;
5,15,25,35,45,55 * * * * lxplus.cern.ch cd /afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server/general-activity ; ./monitorBoincServer.sh >> monitorBoincServer.log 2>&1
58 23 * * * lxplus.cern.ch cd /afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server/general-activity ; ./monitorBoincServerDailyArchive.sh >> monitorBoincServer.log 2>&1 ; rm *dat *pdf
# - WUs being submitted;
# - archiving plots/data;
35 1,7,13,19 * * * lxplus.cern.ch cd /afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server/submissions ; ./monitorSubmissions.sh >> monitorSubmissions.log 2>&1
15 0 * * * lxplus.cern.ch cd /afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server/submissions ; ./monitorSubmissions.sh yesterday >> monitorSubmissions.log 2>&1 ; ./monitorSubmissionsDailyArchive.sh >> monitorSubmissions.log 2>&1
# assimilator getting stuck
1,6,11,16,21,26,31,36,41,46,51,56 * * * * lxplus.cern.ch cd /afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server/general-activity ; ./monitorAssimilatorTimeStamp.sh >> /dev/null 2>&1
```
