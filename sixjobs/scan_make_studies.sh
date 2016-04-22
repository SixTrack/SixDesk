#!/bin/sh

confirm="N"
read -p "Are you sure to recreate all the studies? [y/N] " input
confirm=${input:-$confirm}

if [ "$confirm" != "y" ]
then
  echo "Nothing done"
  exit 0
fi

source ./scan_make_masks.sh

rm -f lhc2016_scan_*
rm -rf studies

for mask in $(ls mask/lhc2016_scan*)
do
  mask=$(echo $mask | sed 's?.*/??' | sed 's?\..*??')
  echo
  echo "##########################################"
  echo "### SETTING ENV FOR MASK: $mask"
  echo
  sed -i 's/export LHCDescrip=.*/export LHCDescrip='$mask'/' sixdeskenv
  ./set_env
done
