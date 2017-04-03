#!/bin/bash

mkdir -p newfiles

FILES=*
for f in $FILES
do
    echo "Processing $f file..."
    python replace_sixdeskmess.py ${f} > newfiles/"new_${f}"
    
  # take action on each file. $f store current file name

done


