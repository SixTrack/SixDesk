#!/bin/sh

for mask in $(ls mask/lhc2016_scan*)
do
  study=$(echo $mask | sed 's?.*/??' | sed 's?\..*??')
  echo
  echo "####################################################"
  echo "###   RUNNING SIXTRACK FOR STUDY: $study"
  echo 
  ./run_six $study
done
