today=system("date +%F")
iFileName='server_status_'.today

set terminal postscript enhanced 'Times-Roman, 18'
set output iFileName.'.ps'

set xdata time
set timefmt '%H:%M:%S'
set format x '%H:%M:%S'
set xlabel 'time'

set multiplot
set key outside horizontal
set ylabel 'tasks in progress/ready to send [10^3]'
set ytics nomirror
set y2label 'tasks waiting for assimilation' tc rgb 'blue'
set y2tics tc rgb 'blue'
set xtics rotate by -90
set title 'date: '.today
set grid xtics lt 0 lw 1
plot \
     iFileName.'.dat' index 0 using 2:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'in progress',\
     ''               index 0 using 2:($3/100) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'ready to send (M=10)',\
     ''               index 0 using 2:6 with linespoints axis x1y2 pt 7 ps 1 lt 3 lw 1 lc rgb 'blue' notitle
unset grid
set grid ytics lt 0 lw 1
replot
unset grid
set grid y2tics lt 0 lw 1 lc rgb 'blue'
replot
unset multiplot
