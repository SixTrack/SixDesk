#!/bin/bash

bname="ALL"
interval=600
verb=2
NEWLINE=$'\n'

OPTIND=1
while getopts "h?n:i:sv" opt; do
  case "$opt" in
  h|\?)
    echo "Usage: $0 [-n batch name] [-i interval in seconds] [-s[s really] silent] [-v verbose]"
    echo
    echo "The batch name (when given) filters the condor_q output. Example:"
    echo " $0 -n mad/MY_WORKSPACE/ -i 60"
    exit 0
    ;;
  n)  bname=$OPTARG
    ;;
  i)  interval=$OPTARG
    ;;
  s)  ((verb--))
    ;;
  v)  ((verb++))
    ;;
  esac
done

function msg () {
  if [ $verb -ge $1 ]; then
    echo "$(date) --> $2"
  fi
}

msg 1 "Waiting for jobs named $bname to complete. Querying every $interval seconds..."

while
  while
    cq="$(condor_q)"
    [ $? -ne 0 ]
  do
    msg 1 "Warning condor_q did not return zero..."
    sleep 5
  done
  j="$(echo "$cq" | tail -n +5 | head -n -3 )"
  if [ "$bname" != "ALL" ]; then
    j="$(echo "$j" | grep $bname)"
  fi

  if [[ -z $j ]]; then
    q_jobs=0
  else
    q_jobs=$(echo "$j" | wc -l)
  fi
  [ $q_jobs -gt 0 ]
do
  msg 3 "${NEWLINE}$(echo "$cq" | head -4 | tail -1)${NEWLINE}$j"
  msg 2 "Number of batches in the cluster: $q_jobs"
  sleep $interval
done

msg 1 "No more jobs!"
