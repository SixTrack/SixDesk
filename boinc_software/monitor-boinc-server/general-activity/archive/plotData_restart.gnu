reset

restartFile='/home/amereghe/Documents/notebooks/simulations/code development/general notes/boinc/monitoring restarts/restart.txt/restart.txt'
stuckFile='../assimilatorStuck.txt'
restaFile='../assimilatorRestart.txt'

set xdata time
set timefmt '%Y-%m-%d %H:%M:%S'
set format x '%Y-%m-%d %H:%M:%S'
set xlabel 'time'
ybar=170
M=1

set multiplot
set key outside horizontal
set ylabel 'tasks in progress/ready to send [10^3]'
set ytics nomirror
set y2label 'tasks waiting for assimilation' tc rgb 'blue'
set y2tics tc rgb 'blue'
set xtics 3600*4 rotate by -90
set grid xtics lt 0 lw 1
# start from when we re-enabled the auto-restart
# tMin=strptime("%Y-%m-%d %H:%M:%S","2016-10-19 00:00:00")
# tMax=strptime("%Y-%m-%d %H:%M:%S","2016-10-21 00:00:00")
# 48h period shown at HSS section meeting, 2016-09-05
# tMin=strptime("%Y-%m-%d %H:%M:%S","2016-08-30 00:00:00")
tMin=strptime("%Y-%m-%d %H:%M:%S","2017-01-27 00:00:00")
set xrange [tMin:*]
nLines=system("wc -l ".restaFile." | awk '{print ($1)}'")
plot \
     '2017-01/server_status_2017-01.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'in progress',\
     ''               index 0 using 1:6 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle,\
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'ready to send '.gprintf('(M=%.1f)',M),\
     restartFile index 0 using 1:(ybar) with impulses lt -1 lw 1 notitle,\
     '< paste '.stuckFile.' '.restaFile.' | head -n'.nLines index 0 using 1:(0.5*ybar):1:3 with xerrorbars lt -1 lw 1 notitle
# AM ->      '2016-08/server_status_2016-08.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' notitle,\
# AM ->      ''               index 0 using 1:6 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle,\
# AM ->      ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' notitle,\
# AM ->      '2016-09/server_status_2016-09.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' notitle,\
# AM ->      ''               index 0 using 1:6 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle,\
# AM ->      ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' notitle,\
# AM ->      '2016-10/server_status_2016-10.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' notitle,\
# AM ->      ''               index 0 using 1:6 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle,\
# AM ->      ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' notitle,\
# AM ->      '2016-11/server_status_2016-11.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' notitle,\
# AM ->      ''               index 0 using 1:6 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle,\
# AM ->      ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' notitle,\
     
unset grid
set grid ytics lt 0 lw 1
replot
unset grid
set grid y2tics lt 0 lw 1 lc rgb 'blue'
replot
unset multiplot
