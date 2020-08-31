#!/bin/bash

amountWarn=50 # [%]
amountAlarm=98 # [%]

echo ""
echo "starting `basename $0` at `date` on `hostname`..."
echo "warning level at ${amountWarn} %"
echo "alarm level at ${amountAlarm} %"

# check AFS workspace

# get current quota:
# NB: example reply of fs listquota:
#     Volume Name                    Quota       Used %Used   Partition
#     work.boinc                 104857600   19303795   18%          0%  

fsListquota=`fs listquota /afs/cern.ch/work/b/boinc/boinc`
currAmount=`echo "${fsListquota}" | grep work.boinc | awk '{print ($4)}' | cut -d\% -f1`

echo "output of fs listquota /afs/cern.ch/work/b/boinc/boinc:"
echo "${fsListquota}"
if [ ${currAmount} -gt ${amountAlarm} ] ; then
    echo "...sending alarm to sixtadm@cern.ch"
    echo "${fsListquota}" | mail -s "boinc quota on AFS above alarm level!" sixtadm@cern.ch
elif [ ${currAmount} -gt ${amountWarn} ] ; then
    echo "...sending warning to sixtadm@cern.ch"
    echo "${fsListquota}" | mail -s "boinc quota on AFS above warning level..." sixtadm@cern.ch
else
    echo "...AFS quota is fine."
fi

# check EOS workspace

# get current quota:
# NB: example reply of eos quota:

# pre-configuring default route to /eos/user/s/sixtadm/
# -use $EOSHOME variable to override
#
# By user:
# ┏━> Quota Node: /eos/user/
# ┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
# │user      │used bytes│logi bytes│used files│aval bytes│aval logib│aval files│ filled[%]│vol-status│ino-status│
# └──────────┴──────────┴──────────┴──────────┴──────────┴──────────┴──────────┴──────────┴──────────┴──────────┘
#  sixtadm           0 B        0 B          0    2.00 TB    1.00 TB     1.00 M     0.00 %         ok         ok 
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
# 
# By group:
# ┏━> Quota Node: /eos/user/
# ┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
# │group     │used bytes│logi bytes│used files│aval bytes│aval logib│aval files│ filled[%]│vol-status│ino-status│
# └──────────┴──────────┴──────────┴──────────┴──────────┴──────────┴──────────┴──────────┴──────────┴──────────┘
#  def-cg       83.42 TB   41.71 TB    16.36 M        0 B        0 B          0   100.00 %    ignored    ignored 
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

export EOS_MGM_URL=root://eosuser.cern.ch 
eosQuota=`eos quota`
currAmount=`echo "${eosQuota}" | grep sixtadm | awk '{printf ("%.0f",$13)}'`

echo "output of eos quota:"
echo "${eosQuota}"
if [ ${currAmount} -gt ${amountAlarm} ] ; then
    echo "...sending alarm to sixtadm@cern.ch"
    echo "${eosQuota}" | mail -s "boinc quota on EOS above alarm level!" sixtadm@cern.ch
elif [ ${currAmount} -gt ${amountWarn} ] ; then
    echo "...sending warning to sixtadm@cern.ch"
    echo "${eosQuota}" | mail -s "boinc quota on EOS above warning level..." sixtadm@cern.ch
else
    echo "...EOS quota is fine."
fi

echo "...done by `date`."
