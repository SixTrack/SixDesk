reset

# ------------------------------------------------------------------------------
# user defined vars
# ------------------------------------------------------------------------------

# files
grepFiles='2017-??/*dat'
iFileName='submitAll.dat'

# last 24h
rightNow=system('date +"%FT%T"')
last24H=system('date -d "yesterday 13:00 " '."'+%Y-%m-%d'")."T".system('date +"%T"')
tMin=last24H
tMax=rightNow
tStep=1*3600

# time interval
tMin='2017-04-25T00:00:00'
# AM -> tMax='2017-01-27T00:00:00'
tStep=12*3600

# ------------------------------------------------------------------------------
# actual script
# ------------------------------------------------------------------------------

# retrieve data
system('awk -v "tMin='.tMin.'" -v tMax="'.tMax.'" '."'{if ($1!=\"#\") {if (tMin<$1 && $1<tMax) {print ($0)}}}' ".grepFiles.' > '.iFileName)
# AM -> system('awk -v "tMin='.tMin.'" '."'{if (tMin<$1) {print ($0)}}' ".grepFiles.' > '.iFileName)

# echo runners
system( "awk '{if ($1!=\"#\") {print ($6,$4)}}' ".iFileName." | sort -k 1 | awk '{tot+=$2; if (NR==1) {oldOwner=$1} else {if ($1!=oldOwner) {print (tot,oldOwner); tot=0; oldOwner=$1;}}}END{print (tot,oldOwner)}'" )

# AM -> set logscale y
# AM -> set grid xtics ytics mxtics mytics
# AM -> set grid layerdefault   linetype -1 linecolor rgb "gray"  linewidth 0.200,  linetype 0 linecolor rgb "gray"  linewidth 0.200
# AM -> set format y '10^{%L}'
# AM -> set mytics 10

set term qt 10 title 'submitted WUs' font "Times-Roman" size 1900,400
set xdata time
set timefmt '%Y-%m-%dT%H:%M:%S'
set format x '%Y-%m-%d %H:%M'
set xtics rotate by 90 tStep right
set key outside horizontal
set grid
set ylabel 'submitted WUs [10^3]'
plot \
     "< awk '{if ($6==\"mcrouch\") {tot+=$4; print ($1,$3,tot)}}'  ".iFileName index 0 using 1:($3/1000) with steps lt 1 lw 3 lc rgb 'black'      title 'mcrouch',\
     "< awk '{if ($6==\"ynosochk\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1000) with steps lt 1 lw 3 lc rgb 'dark-green' title 'ynosochk',\
     "< awk '{if ($6==\"emaclean\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1000) with steps lt 1 lw 3 lc rgb 'green'      title 'emaclean',\
     "< awk '{if ($6==\"fvanderv\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1000) with steps lt 1 lw 3 lc rgb 'blue'       title 'fvanderv',\
     "< awk '{if ($6==\"kaltchev\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1000) with steps lt 1 lw 3 lc rgb 'magenta'    title 'kaltchev',\
     "< awk '{if ($6==\"phermes\") {tot+=$4; print ($1,$3,tot)}}'  ".iFileName index 0 using 1:($3/1000) with steps lt 1 lw 3 lc rgb 'cyan'       title 'phermes',\
     "< awk '{if ($6==\"nkarast\") {tot+=$4; print ($1,$3,tot)}}'  ".iFileName index 0 using 1:($3/1000) with steps lt 1 lw 3 lc rgb 'orange'     title 'nkarast',\
     "< awk '{if ($6==\"dpellegr\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1000) with steps lt 1 lw 3 lc rgb 'pink'       title 'dpellegr',\
     "< awk '{if ($6==\"amereghe\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1000) with steps lt 1 lw 3 lc rgb 'purple'     title 'amereghe',\
     "< awk '{if ($6==\"rdemaria\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1000) with steps lt 1 lw 3 lc rgb 'yellow'     title 'rdemaria',\
     "< awk '{if ($6==\"jbarranc\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1000) with steps lt 1 lw 3 lc rgb 'dark-blue'  title 'jbarranc',\
     "< awk '{if ($6==\"giovanno\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1000) with steps lt 1 lw 3 lc rgb 'gold'       title 'giovanno',\
     "< awk '{if ($6==\"mcintosh\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1000) with steps lt 1 lw 3 lc rgb 'violet'     title 'mcintosh',\
     "< awk '{if ($6==\"-\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName        index 0 using 1:($3/1000) with steps lt 1 lw 3 lc rgb 'red'        title '-'
