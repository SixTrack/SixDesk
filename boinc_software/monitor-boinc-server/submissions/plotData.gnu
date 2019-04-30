# today=system("date +%F")
today='2019-04-30'
iFileName='submitAll_'.today.'.dat'
iFileNameAssimilated='assimilateAll_'.today.'.dat'
oFileName='submitAll_'.today.'.ps'

set terminal postscript enhanced 'Times-Roman, 16'
set output oFileName

tStep=3600
set xdata time
set timefmt '%Y-%m-%dT%H:%M:%S'
set format x '%H:%M:%S'
set xlabel 'time'
set xtics rotate by 90 tStep

set grid

set key outside horizontal
set ylabel 'submitted WUs [10^3]'
set title 'date: '.today
print "< awk '{if ($6==\"fvanderv\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName
plot \
     "< awk '{if ($6==\"mcrouch\") {tot+=$4; print ($1,$3,tot)}}'  ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'black'       title 'mcrouch',\
     "< awk '{if ($6==\"ynosochk\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'dark-green'  title 'ynosochk',\
     "< awk '{if ($6==\"emaclean\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'green'       title 'emaclean',\
     "< awk '{if ($6==\"fvanderv\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'blue'        title 'fvanderv',\
     "< awk '{if ($6==\"kaltchev\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'magenta'     title 'kaltchev',\
     "< awk '{if ($6==\"phermes\") {tot+=$4; print ($1,$3,tot)}}'  ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'cyan'        title 'phermes',\
     "< awk '{if ($6==\"nkarast\") {tot+=$4; print ($1,$3,tot)}}'  ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'orange'      title 'nkarast',\
     "< awk '{if ($6==\"dpellegr\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'pink'        title 'dpellegr',\
     "< awk '{if ($6==\"ecruzala\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'navy'        title 'ecruzala',\
     "< awk '{if ($6==\"amereghe\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'purple'      title 'amereghe',\
     "< awk '{if ($6==\"rdemaria\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'yellow'      title 'rdemaria',\
     "< awk '{if ($6==\"jbarranc\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'dark-blue'   title 'jbarranc',\
     "< awk '{if ($6==\"giovanno\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'gold'        title 'giovanno',\
     "< awk '{if ($6==\"mcintosh\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'violet'      title 'mcintosh',\
     "< awk '{if ($6==\"skostogl\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'dark-red'    title 'skostogl',\
     "< awk '{if ($6==\"lcoyle\") {tot+=$4; print ($1,$3,tot)}}'   ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'salmon'      title 'lcoyle',\
     "< awk '{if ($6==\"mihofer\") {tot+=$4; print ($1,$3,tot)}}'  ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'turquoise'   title 'mihofer',\
     "< awk '{if ($6==\"xiaohan\") {tot+=$4; print ($1,$3,tot)}}'  ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'skyblue'     title 'xiaohan',\
     "< awk '{if ($6==\"dmirarch\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'slategray'   title 'dmirarch',\
     "< awk '{if ($6==\"-\") {tot+=$4; print ($1,$3,tot)}}' ".iFileName        index 0 using 1:($3/1E6) with steps lt 1 lw 3 lc rgb 'red'         title '-'

set ylabel 'WUs [10^3]'
plot \
     "< awk '{tot+=$4; print ($1,tot)}'  ".iFileName index 0 using 1:($2/1000) with steps lt 1 lw 3 lc rgb 'red' title 'submitted',\
     "< awk '{tot+=$4; print ($1\"T\"$2,tot)}'  ".iFileNameAssimilated index 0 using 1:($2/1000) with steps lt 1 lw 3 lc rgb 'blue' title 'assimilated'
