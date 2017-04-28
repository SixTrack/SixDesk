#!/bin/bash
#BSUB -J SIXJOBNAME    # job name

TRACKDIR=SIXTRACKDIR
pwd		# where am I?
rm -f $TRACKDIR/SIXJOBDIR/JOB_NOT_YET_STARTED
touch $TRACKDIR/SIXJOBDIR/JOB_NOT_YET_COMPLETED
# copy compressed fortran files from the designated"job"  directory to our work dir
# pick up inputfiles
cp $TRACKDIR/SIXJOBDIR/fort.*.gz .
gunzip fort.*.gz

#get  sixtrack image
cp SIXTRACKEXE sixtrack
ls -al
./sixtrack > fort.6  
ls -al
tail -100 fort.6

if [ ! -s fort.10 ];then
  rm -f fort.10
fi
gzip fort.*
cp fort.10.gz $TRACKDIR/SIXJOBDIR/
if [ -f fma_sixtrack ]; then
  gzip fma_sixtrack
  cp fma_sixtrack.gz $TRACKDIR/SIXJOBDIR/
# for debugging also copy files with particle
# coordinates
#  gzip *_DUMP_*
#  cp *_DUMP_*.gz $TRACKDIR/SIXJOBDIR/
fi
rm -f $TRACKDIR/SIXJOBDIR/JOB_NOT_YET_COMPLETED
