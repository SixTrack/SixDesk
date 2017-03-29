#!/bin/ksh

export junktmp=%SIXJUNKTMP%
export i=%SIXI%
export filejob=%SIXFILEJOB%
export sixtrack_input=%SIXTRACK_INPUT%
export CORR_TEST=%CORR_TEST%
export fort_34=%FORT_34%
export MADX_PATH=%MADX_PATH%
export MADX=%MADX%

echo "Calling madx version $MADX in $MADX_PATH"
$MADX_PATH/$MADX < $junktmp/$filejob."$i" > $filejob.out."$i"
cp -f $filejob.out."$i" $junktmp
ls -l
grep -i "finished normally" $filejob.out."$i" > /dev/null
if test $? -ne 0
then
  touch $sixtrack_input/ERRORS
  echo "MADX has NOT completed properly!"
  echo "$filejob.out.${i} MADX has NOT completed properly!" >> $sixtrack_input/ERRORS
  exit 1
fi
grep -i "TWISS fail" $filejob.out."$i" > /dev/null
if test $? -eq 0
then
  touch $sixtrack_input/ERRORS
  echo "MADX TWISS appears to have failed!"
  echo "$filejob.out.${i} MADX TWISS appears to have failed!" >> $sixtrack_input/ERRORS
  exit 2
fi
if test ! -s fc.2
then
  touch $sixtrack_input/ERRORS
  echo "MADX has produced an empty fc.2/fort.2_"$i"!"
  echo "$filejob.out.${i} MADX has produced an empty fc.2/fort.2_"$i"!" >> $sixtrack_input/ERRORS
  exit 4
fi
if test "$fort.34" != ""
then
  if test ! -s fc.34
  then
    touch $sixtrack_input/ERRORS
    echo "MADX has produced an empty fc.34/fort.34_"$i" (which you asked for)!"
    echo "$filejob.out.${i} MADX has produced an empty fc.34/fort.34_"$i" (which you asked for)!" >> $sixtrack_input/ERRORS
    exit 5
  fi
fi
if test "$fort_34" != ""
then
  mv fc.34 fort.34
  if test -s $sixtrack_input/fort.34_"$i".gz
  then
    cp  $sixtrack_input/fort.34_"$i".gz .
    gunzip fort.34_"$i".gz
    diff fort.34_"$i" fort.34 > diffs
    if test $? -ne 0
    then
      touch $sixtrack_input/WARNINGS
      echo "A different fc.34/fort.34_"$i" has been produced!"
      echo "$filejob.out.${i} MADX has produced a different fc.34/fort.34_"$i"!">> $sixtrack_input/WARNINGS
      cat diffs
      cat diffs >> $sixtrack_input/WARNINGS
    fi
  fi
  mv fort.34 fort.34_"$i"
  gzip fort.34_"$i"
  cp fort.34_"$i".gz $sixtrack_input 
fi
# and now do 2, 16, and 8 (zipped) and the MC errors (unzipped)
touch fc.16
touch fc.8
touch fc.34
mv fc.2 fort.2
mv fc.16 fort.16
mv fc.8 fort.8
for fil in fort.2 fort.8 fort.16
do
  if test -s $sixtrack_input/"$fil"_"$i".gz
  then
    cp  $sixtrack_input/"$fil"_"$i".gz .
    gunzip "$fil"_"$i".gz
    diff "$fil"_"$i" "$fil" > diffs
    if test $? -ne 0
    then
      touch $sixtrack_input/WARNINGS
      echo "A different "$fil"_"$i" has been produced!"
      echo "$filejob.out.${i} MADX has produced a different "$fil"_"$i"!">> $sixtrack_input/WARNINGS
      cat diffs
      cat diffs >> $sixtrack_input/WARNINGS
    fi
  fi
  mv "$fil" "$fil"_"$i"
  gzip "$fil"_"$i"
  cp "$fil"_"$i".gz $sixtrack_input
done
if test "$CORR_TEST" -ne 0
then
  for fil in MCSSX_errors MCOSX_errors MCOX_errors MCSX_errors MCTX_errors
  do
    if test -s $sixtrack_input/"$fil"_"$i"
  then
    cp  $sixtrack_input/"$fil"_"$i" .
    diff "$fil"_"$i" temp/"$fil" > diffs
    if test $? -ne 0
    then
      touch $sixtrack_input/WARNINGS
      echo "A different "$fil"_"$i" has been produced!"
      echo "$filejob.out.${i} MADX has produced a different "$fil"_"$i"!">> $sixtrack_input/WARNINGS
      cat diffs
      cat diffs >> $sixtrack_input/WARNINGS
    fi
  fi
  mv temp/"$fil" "$fil"_"$i"
  cp "$fil"_"$i" $sixtrack_input
  done
fi
