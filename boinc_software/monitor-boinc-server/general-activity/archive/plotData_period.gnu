period='2018-02'
iFileName='server_status_'.period

# changes in status page:
# - 2018-02-26: old server actually switched off on 2018-02-06;
#   -> new status page has slightly different order of table lines;
#   -> swapping $10 and $11, and $13 and $14;

set terminal postscript enhanced color 'Times-Roman, 11'
set output 'status_'.period.'.ps'

set xdata time
set timefmt '%Y-%m-%d %H:%M:%S'
set format x '%Y-%m-%d %H:%M'
set xlabel 'time'
M=10.0

set multiplot
set title 'server status - period: '.period
set key outside horizontal
set ylabel 'tasks in progress/ready to send [10^3]'
set ytics nomirror
set y2label 'tasks waiting for assimilation' tc rgb 'blue'
set y2tics tc rgb 'blue'
set xtics rotate by -90
set grid xtics lt 0 lw 1
plot \
     iFileName.'.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'in progress',\
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'ready to send '.gprintf('(M=%.1f)',M),\
     ''               index 0 using 1:6 with linespoints axis x1y2 pt 7 ps 1 lt 3 lw 1 lc rgb 'blue' notitle
unset grid
set grid ytics lt 0 lw 1
replot
unset grid
set grid y2tics lt 0 lw 1 lc rgb 'blue'
replot
unset multiplot

# credit
set key outside horizontal
set ylabel 'recent credit (users/computers) [10^3]' tc rgb 'red'
set ytics nomirror tc rgb 'red'
set y2label 'total credit (users/computers) [10^3]' tc rgb 'magenta'
set y2tics tc rgb 'magenta'
set grid xtics ytics lt 0 lw 1 lc rgb 'black'
set title 'credit - period: '.period
plot \
     iFileName.'.dat' index 0 using 1:($11/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'users',\
     ''               index 0 using 1:($14/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'blue' title 'computers',\
     ''               index 0 using 1:($10/1000) with linespoints axis x1y2 pt 7 ps 1 lt 1 lw 1 lc rgb 'magenta' notitle,\
     ''               index 0 using 1:($13/1000) with linespoints axis x1y2 pt 7 ps 1 lt 1 lw 1 lc rgb 'cyan' notitle

# gigaflops
set key outside horizontal
set ylabel 'TeraFLOPs []' tc rgb 'black'
set ytics mirror tc rgb 'black'
unset y2label
unset y2tics
set grid xtics ytics lt 0 lw 1 lc rgb 'black'
set title 'TeraFLOPs - period: '.period
plot \
     iFileName.'.dat' index 0 using 1:($16/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' notitle
unset title


application='SixTrack'
iFileName=application.'_status_'.period.'.dat'
set multiplot
set key outside horizontal
set ylabel 'tasks in progress/unsent [10^3]'
set ytics nomirror
set y2label 'users in last 24h' tc rgb 'blue'
set y2tics tc rgb 'blue'
set xtics rotate by -90
set title 'SixTrack app - period: '.period.' - application: '.application
set grid xtics lt 0 lw 1
plot \
     iFileName index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'in progress',\
     ''        index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'unsent '.gprintf('(M=%.1f)',M),\
     ''        index 0 using 1:5 with linespoints axis x1y2 pt 7 ps 1 lt 3 lw 1 lc rgb 'blue' notitle
unset grid
set grid ytics lt 0 lw 1
replot
unset grid
set grid y2tics lt 0 lw 1 lc rgb 'blue'
replot
unset multiplot



application='sixtracktest'
iFileName=application.'_status_'.period.'.dat'
set multiplot
set key outside horizontal
set ylabel 'tasks in progress/unsent [10^3]'
set ytics nomirror
set y2label 'users in last 24h' tc rgb 'blue'
set y2tics tc rgb 'blue'
set xtics rotate by -90
set title 'sixtracktest app - period: '.period.' - application: '.application
set grid xtics lt 0 lw 1
plot \
     iFileName index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'in progress',\
     ''        index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'unsent '.gprintf('(M=%.1f)',M),\
     ''        index 0 using 1:5 with linespoints axis x1y2 pt 7 ps 1 lt 3 lw 1 lc rgb 'blue' notitle
unset grid
set grid ytics lt 0 lw 1
replot
unset grid
set grid y2tics lt 0 lw 1 lc rgb 'blue'
replot
unset multiplot
