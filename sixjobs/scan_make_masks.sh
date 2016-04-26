#!/bin/sh

source ./scan_set_def

echo "Recreating the masks from the template"
rm -f mask/lhc2016_scan*.mask

for qp in $SCAN_QPRIME
do
  for i in $SCAN_I_MO
  do 
    cat mask/lhc2016_template_chr_oct.mask |\
    sed -e "s/%QPRIME/$qp/" |\
    sed -e "s/%I_MO/$i/" > 'mask/lhc2016_scan_'$qp'_'$i'.mask'
  done
done
