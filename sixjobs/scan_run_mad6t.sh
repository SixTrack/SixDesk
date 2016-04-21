#!/bin/sh

for mask in $(ls mask/lhc2016_scan*)
do
  study=$(echo $mask | sed 's?.*/??' | sed 's?\..*??')
  echo
  echo "##############################################"
  echo "###  RUNNING MAD FOR STUDY: $study"
  echo
  ./set_env $study
  ./run_mad6t
done
