#!/bin/ksh
#BSUB -J SIXJOBNAME   	# job name

junktmp=SIXJUNKTMP
export junktmp
TRACKDIR=SIXTRACKDIR
CASTOR=SIXCASTOR
FIRSTINITIAL=`echo $LOGNAME | cut -c1`
CASTORDIR=$CASTOR_HOME/direct_track/SIXJOBDIR
BNLIN=SIXBNLIN
pwd		# where am I?
touch $TRACKDIR/SIXJOBDIR/JOB_NOT_YET_COMPLETED
rm -f $TRACKDIR/SIXJOBDIR/JOB_NOT_YET_STARTED
# copy compressed fortran files from the designated"job"  directory to our work dir
# pick up inputfiles
cp $TRACKDIR/SIXJOBDIR/fort.*.gz .
gunzip fort.*.gz
cp $BNLIN beambeamdist.dat
#get  sixtrack image
cp SIXTRACKBNLEXE sixtrack
ls -al
date
time ./sixtrack > fort.6  
stat=$?
date
problem="false"
### Eric for testing
##stat=999
##echo "blah" > core
###
if test $stat -ne 0
then
  problem="true"
  echo "SixTrack exited with status $stat"
else
  grep SIXTRACR fort.6
  egrep 'Computing Time|Total Time' fort.6
fi
touch fort.10
gzip fort.*
if [ -s core ];then
   cp core sixtrack $TRACKDIR/SIXJOBDIR
fi
cp fort.10.gz $TRACKDIR/SIXJOBDIR/title.dat.gz
if test "$problem" = "true"
then
  cp fort.6.gz $TRACKDIR/SIXJOBDIR/
fi
gzip *.dat
cp beambeam-output.dat.gz $TRACKDIR/SIXJOBDIR/
cp beambeam-lostID.dat.gz $TRACKDIR/SIXJOBDIR/
#cp SixTwiss.dat.gz $TRACKDIR/SIXJOBDIR/
cp checkdist.dat.gz $TRACKDIR/SIXJOBDIR/
if test "$CASTOR" = "true"
then
  nsrm -rf $CASTORDIR
  nsmkdir -p $CASTORDIR
  tar cvf SIXJOBNAME.tar *.gz
  export STAGE_HOST="castorpublic"
  export STAGE_SVCCLASS="default"
  xrdcp SIXJOBNAME.tar root://${STAGE_HOST}.cern.ch/$CASTORDIR
fi

if [ -f Sixout.zip ] ; then
    cp Sixout.zip $TRACKDIR/SIXJOBDIR/
fi

rm -f $TRACKDIR/SIXJOBDIR/JOB_NOT_YET_COMPLETED
