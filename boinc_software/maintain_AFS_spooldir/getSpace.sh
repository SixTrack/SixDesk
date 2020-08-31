#!/bin/bash

# get data
du -cS * | sort -g -k1 > spaceOccupancy.txt

# all the processed dirs
grep processed spaceOccupancy.txt | awk '{tot+=$1}END{print tot}'

# 10 most problematic workspaces
tail spaceOccupancy.txt
