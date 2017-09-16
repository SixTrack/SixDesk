BEGIN {
}
FNR==1 {
    ang=$1
    ach=$2
    al10m=$3
    al1m=$4
    al100k=$5
    al10k=$6
    al1000=$7
    amin=$8
    amax=$9
    ach1=$10
}
{
    if ($3 < al10m) {all10m=$3}
    if ($4 < al1m) {al1m=$4}
    if ($5 < al100k) {al100k=$5}
    if ($6 < al10k) {al10k=$6}
    if ($7 < al1000) {al1000=$7}
    if ($9 < amax) {amax=$9}
}
END {
  print (ang" "ach" "al10m" "al1m" "al100k" "al10k" "al1000" "amin" "amax" "ach1)
}
