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

# ------------------------------------------------------------------------------
# general overview of server status
# ------------------------------------------------------------------------------
set term qt 0 
set multiplot title 'server overview'
set key outside horizontal
set ylabel 'tasks in progress/ready to send [10^3]'
set ytics nomirror
set y2label 'tasks waiting for assimilation' tc rgb 'blue'
set y2tics tc rgb 'blue'
set xtics 3600*4 rotate by -90
set grid xtics lt 0 lw 1
tMin=strptime("%Y-%m-%d %H:%M:%S","2017-01-30 16:00:00")
set xrange [tMin:*]
nLines=system("wc -l ".restaFile." | awk '{print ($1)}'")
plot \
     '2017-01/server_status_2017-01.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'in progress',\
     ''               index 0 using 1:6 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle,\
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'ready to send '.gprintf('(M=%.1f)',M),\
     '2017-02/server_status_2017-02.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' notitle,\
     ''               index 0 using 1:6 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle,\
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' notitle,\
     restartFile index 0 using 1:(ybar) with impulses lt -1 lw 1 notitle,\
     '< paste '.stuckFile.' '.restaFile.' | head -n'.nLines index 0 using 1:(0.5*ybar):1:3 with xerrorbars lt -1 lw 1 notitle
     
unset grid
set grid ytics lt 0 lw 1
replot
unset grid
set grid y2tics lt 0 lw 1 lc rgb 'blue'
replot
unset multiplot

# ------------------------------------------------------------------------------
# sixtrack
# ------------------------------------------------------------------------------
set term qt 1
set multiplot title 'SixTrack app'
set key outside horizontal
set ylabel 'tasks in progress/unsent [10^3]'
set ytics nomirror
set y2label 'users in last 24h' tc rgb 'blue'
set y2tics tc rgb 'blue'
set xtics rotate by -90
set grid xtics lt 0 lw 1
plot \
     '2017-01/SixTrack_status_2017-01.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'in progress',\
     ''               index 0 using 1:5 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle,\
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'ready to send '.gprintf('(M=%.1f)',M),\
     '2017-02/SixTrack_status_2017-02.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' notitle,\
     ''               index 0 using 1:5 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle,\
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' notitle
unset grid
set grid ytics lt 0 lw 1
replot
unset grid
set grid y2tics lt 0 lw 1 lc rgb 'blue'
replot
unset multiplot
