#!/bin/bash


FILES=*
for f in $FILES
do
    echo "Processing $f file..."

    differences=$(diff ${f} newfiles/"new_${f}" | wc -l)
    if [ ${differences} -ne 0 ]; then
	echo "${f}    no difference found"
    else
	echo "${f}    difference found"
    fi


done


