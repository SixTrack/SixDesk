#!/bin/bash
#BSUB -J SIXJOBNAME    # job name

TRACKDIR=SIXTRACKDIR
BINPATH=SIXDESKHOME/bin
pwd		# where am I?
rm -f $TRACKDIR/SIXJOBDIR/JOB_NOT_YET_STARTED
touch $TRACKDIR/SIXJOBDIR/JOB_NOT_YET_COMPLETED
# copy compressed fortran files from the designated"job"  directory to our work dir
# pick up inputfiles
cp $TRACKDIR/SIXJOBDIR/fort.*.gz .
gunzip fort.*.gz
# sussix stuff
%susscp $TRACKDIR/SIXJOBDIR/sussix.inp.[1-3].gz .
%sussgunzip sussix.inp.[1-3].gz
%susscp $BINPATH/sussix .
%susscp $BINPATH/repair .
#get  sixtrack image
cp SIXTRACKEXE sixtrack
ls -al 
./sixtrack > fort.6 
%sussrm -rf fort.93 fort.94 fort.95 
%sussmv sussix.inp.1 sussix.inp
%suss./sussix
%sussif [ -s reson51 ] ;then
%suss  mv reson51 fort.93  
%susselse
%suss  touch fort.93
%sussfi
%sussmv sussix.inp.2 sussix.inp
%suss./sussix
%sussif [ -s reson51 ] ;then
%suss  mv reson51 fort.94  
%susselse
%suss  touch fort.94
%sussfi
%sussmv sussix.inp.3 sussix.inp
%suss./sussix
%sussif [ -s reson51 ] ;then
%suss  mv reson51 fort.95  
%susselse
%suss  touch fort.95
%sussfi
%sussrm -rf sussix*
%suss./repair
%sussif [ -s fort.11 ] ;then
%suss  mv fort.11 fort.10
%sussfi
%sussrm -rf fort.93
%sussrm -rf fort.94
%sussrm -rf fort.95
if [ ! -s fort.10 ];then
  rm -f fort.10
fi
gzip fort.*
if [ -s core ];then
   cp core sixtrack $TRACKDIR/SIXJOBDIR
   exit
fi

cp fort.10.gz $TRACKDIR/SIXJOBDIR/

if [ -f Sixout.zip ] ; then
    cp Sixout.zip $TRACKDIR/SIXJOBDIR/
fi

#
rm -f $TRACKDIR/SIXJOBDIR/JOB_NOT_YET_COMPLETED

