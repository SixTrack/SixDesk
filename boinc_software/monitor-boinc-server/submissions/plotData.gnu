# today=system("date +%F")
today='2020-08-31'
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
set xtics rotate by 90 tStep right

set grid

set key outside horizontal
set ylabel 'submitted WUs [10^3]'
set title 'date: '.today
scaleFact=1E3
plot \
     "< awk '{if ($6==\"mcrouch\")  {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'black'          title 'mcrouch',\
     "< awk '{if ($6==\"ynosochk\") {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'dark-green'     title 'ynosochk',\
     "< awk '{if ($6==\"emaclean\") {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'green'          title 'emaclean',\
     "< awk '{if ($6==\"fvanderv\") {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'blue'           title 'fvanderv',\
     "< awk '{if ($6==\"kaltchev\") {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'magenta'        title 'kaltchev',\
     "< awk '{if ($6==\"phermes\")  {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'cyan'           title 'phermes',\
     "< awk '{if ($6==\"nkarast\")  {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'orange'         title 'nkarast',\
     "< awk '{if ($6==\"dpellegr\") {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'pink'           title 'dpellegr',\
     "< awk '{if ($6==\"ecruzala\") {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'navy'           title 'ecruzala',\
     "< awk '{if ($6==\"amereghe\") {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'purple'         title 'amereghe',\
     "< awk '{if ($6==\"rdemaria\") {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'yellow'         title 'rdemaria',\
     "< awk '{if ($6==\"jbarranc\") {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'dark-blue'      title 'jbarranc',\
     "< awk '{if ($6==\"giovanno\") {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'gold'           title 'giovanno',\
     "< awk '{if ($6==\"mcintosh\") {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'violet'         title 'mcintosh',\
     "< awk '{if ($6==\"skostogl\") {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'dark-red'       title 'skostogl',\
     "< awk '{if ($6==\"lcoyle\")   {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'salmon'         title 'lcoyle',\
     "< awk '{if ($6==\"mihofer\")  {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'olive'          title 'mihofer',\
     "< awk '{if ($6==\"xiaohan\")  {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'skyblue'        title 'xiaohan',\
     "< awk '{if ($6==\"dmirarch\") {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'slategray'      title 'dmirarch',\
     "< awk '{if ($6==\"dalena\")   {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'dark-plum'      title 'dalena',\
     "< awk '{if ($6==\"mischenk\") {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'dark-goldenrod' title 'mischenk',\
     "< awk '{if ($6==\"-\")        {print ($0)}}' ".iFileName." | awk '{tot+=$4; print ($1,$3,tot)}END{print ($3,$1,tot)}' " index 0 using 1:($3/scaleFact) with steps lt 1 lw 3 lc rgb 'red'            title '-'

set ylabel 'WUs [10^3]'
plot \
     "< awk '{tot+=$4; print ($1,tot)}'  ".iFileName index 0 using 1:($2/1000) with steps lt 1 lw 3 lc rgb 'red' title 'submitted',\
     "< awk '{tot+=$4; print ($1\"T\"$2,tot)}'  ".iFileNameAssimilated index 0 using 1:($2/1000) with steps lt 1 lw 3 lc rgb 'blue' title 'assimilated'
