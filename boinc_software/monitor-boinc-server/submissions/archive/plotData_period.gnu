reset

# ------------------------------------------------------------------------------
# user defined vars
# ------------------------------------------------------------------------------

# files
grepFiles='2019-??/submit*.dat'
iFileName='submitAll.dat'
grepFilesAssimilated='2019-??/assimilate*.dat'
iFileNameAssimilated='assimilateAll.dat'

# last 24h
rightNow=system('date +"%FT%T"')
last24H=system('date -d "yesterday 13:00 " '."'+%Y-%m-%d'")."T".system('date +"%T"')
tMin=last24H
tMax=rightNow
tStep=1*3600

# time interval
# AM -> tMin='2017-05-23T00:00:00'
# AM -> tMin='2017-06-15T00:00:00'
tMin='2019-04-29T00:00:00'
tMax='2019-05-20T23:59:59'
tStep=3600*12

# typical enlarged window size: 1900,400
# trigger use of png or interactive windows: 0: png, 1: interactive
linteractive=0
lprintDate=0 # 0: no date/time in png name; 1: date/time in png name
xSizeWdw=1600#regular: 1000
ySizeWdw=600#regular: 400
lLog=0 # 1: log y-axis; 0: linear y-axis

if ( lprintDate==0 ) {
rightNowPNG=''
} else {
rightNowPNG=system('date +"_%F_%H-%M-%S"')
}

# ------------------------------------------------------------------------------
# actual script
# ------------------------------------------------------------------------------

# retrieve data
system('awk -v "tMin='.tMin.'" -v tMax="'.tMax.'" '."'{if ($1!=\"#\") {if (tMin<$1 && $1<tMax) {print ($0)}}}' ".grepFiles.' > '.iFileName)
system('awk -v "tMin='.tMin.'" -v tMax="'.tMax.'" '."'{if ($1!=\"#\") {tStamp=$1\"T\"$2; if (tMin<=tStamp && tStamp<=tMax) {print ($1\"T\"$2,$3,$4,$5)}}}' ".grepFilesAssimilated.' > '.iFileNameAssimilated)
# AM -> system('awk -v "tMin='.tMin.'" '."'{if (tMin<$1) {print ($0)}}' ".grepFiles.' > '.iFileName)

# echo runners
system( "awk '{if ($1!=\"#\") {print ($6,$4)}}' ".iFileName." | sort -k 1 | awk '{if (NR==1) {oldOwner=$1} else {if ($1!=oldOwner) {print (tot,oldOwner); totot+=tot; tot=0; oldOwner=$1;}} tot+=$2}END{print (tot,oldOwner); totot+=tot; print(\"total:\",totot)}'" )

set xdata time
set timefmt '%Y-%m-%dT%H:%M:%S'
set format x '%Y-%m-%d %H:%M'
# set format x '%Y-%m-%d'
set xtics rotate by 90 tStep left
tMin=strptime("%Y-%m-%dT%H:%M:%S",tMin)
tMax=strptime("%Y-%m-%dT%H:%M:%S",tMax)
set xrange [tMin:tMax]
set key outside horizontal
set grid

currTitle='submitted WUs'
if ( linteractive==0 ) {
set term png size xSizeWdw,ySizeWdw notransparent enhanced
set output '/afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server/boincStatus/submissionCumulative'.rightNowPNG.'.png'
} else {
set term qt 10 title currTitle size xSizeWdw,ySizeWdw
}
set ylabel 'submitted WUs [10^6]'
if ( lLog==1 ) {
set logscale y
set grid xtics ytics mxtics mytics
set grid layerdefault   linetype -1 linecolor rgb "gray"  linewidth 0.200,  linetype 0 linecolor rgb "gray"  linewidth 0.200
set format y '10^{%L}'
set mytics 10
}

plot \
     "< awk '{if ($6==\"mcrouch\") {tot+=$4; print ($1,$3,tot)}}'  ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'black'          title 'mcrouch',\
     "< awk '{if ($6==\"ynosochk\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'dark-green'     title 'ynosochk',\
     "< awk '{if ($6==\"emaclean\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'green'          title 'emaclean',\
     "< awk '{if ($6==\"fvanderv\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'blue'           title 'fvanderv',\
     "< awk '{if ($6==\"kaltchev\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'magenta'        title 'kaltchev',\
     "< awk '{if ($6==\"phermes\") {tot+=$4; print ($1,$3,tot)}}'  ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'cyan'           title 'phermes',\
     "< awk '{if ($6==\"nkarast\") {tot+=$4; print ($1,$3,tot)}}'  ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'orange'         title 'nkarast',\
     "< awk '{if ($6==\"dpellegr\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'pink'           title 'dpellegr',\
     "< awk '{if ($6==\"ecruzala\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'navy'           title 'ecruzala',\
     "< awk '{if ($6==\"amereghe\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'purple'         title 'amereghe',\
     "< awk '{if ($6==\"rdemaria\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'yellow'         title 'rdemaria',\
     "< awk '{if ($6==\"jbarranc\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'dark-blue'      title 'jbarranc',\
     "< awk '{if ($6==\"giovanno\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'gold'           title 'giovanno',\
     "< awk '{if ($6==\"mcintosh\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'violet'         title 'mcintosh',\
     "< awk '{if ($6==\"skostogl\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'dark-red'       title 'skostogl',\
     "< awk '{if ($6==\"lcoyle\") {tot+=$4; print ($1,$3,tot)}}'   ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'salmon'         title 'lcoyle',\
     "< awk '{if ($6==\"mihofer\") {tot+=$4; print ($1,$3,tot)}}'  ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'olive'          title 'mihofer',\
     "< awk '{if ($6==\"xiaohan\") {tot+=$4; print ($1,$3,tot)}}'  ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'skyblue'        title 'xiaohan',\
     "< awk '{if ($6==\"dmirarch\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'slategray'      title 'dmirarch',\
     "< awk '{if ($6==\"dalena\") {tot+=$4; print ($1,$3,tot)}}'   ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'dark-plum'      title 'dalena',\
     "< awk '{if ($6==\"mischenk\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E3) with steps lt 1 lw 3 lc rgb 'dark-goldenrod' title 'mischenk',\
     "< awk '{if ($6==\"-\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName        index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'red'            title '-'
#
if (lLog==1){
unset logscale y
set format y '%g'
unset mytics
}
     
currTitle='overview'
if ( linteractive==0 ) {
set term png size xSizeWdw,ySizeWdw notransparent enhanced
set output '/afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server/boincStatus/overviewCumulative'.rightNowPNG.'.png'
} else {
set term qt 11 title currTitle size xSizeWdw,ySizeWdw
}
set ylabel 'WUs [10^6]'
plot \
     "< awk '{tot+=$4; print ($1,tot)}'  ".iFileName index 0 using 1:($2/1E6) with steps lt 1 lw 3 lc rgb 'red' title 'submitted',\
     "< awk '{tot+=$3; print ($1,tot)}'  ".iFileNameAssimilated index 0 using 1:($2/1E6) with steps lt 1 lw 3 lc rgb 'blue' title 'assimilated'
