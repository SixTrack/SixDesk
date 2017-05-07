reset

restartFile='/home/amereghe/Documents/notebooks/simulations/code development/general notes/boinc/monitoring restarts/restart.txt/restart.txt'
stuckFile='../assimilatorStuck.txt'
restaFile='../assimilatorRestart.txt'

set xdata time
set timefmt '%Y-%m-%d %H:%M:%S'
set format x '%Y-%m-%d %H:%M'
ybar=100
M=10

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
set xtics 3600*12 rotate by 90 right
set grid xtics lt 0 lw 1
tMin=strptime("%Y-%m-%d %H:%M:%S","2017-04-25 00:00:00")
set xrange [tMin:*]
nLines=system("wc -l ".restaFile." | awk '{print ($1)}'")
plot \
     '< cat 2017-??/server_status_????-??.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'in progress',\
     ''               index 0 using 1:6 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle,\
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'ready to send '.gprintf('(M=%.1f)',M),\
     restartFile index 0 using 1:(ybar) with impulses lt -1 lw 2 notitle,\
     '< paste '.stuckFile.' '.restaFile.' | head -n'.nLines index 0 using 1:(0.5*ybar):1:3 with xerrorbars lt -1 lw 1 notitle
     
unset grid
set grid ytics lt 0 lw 1
replot
unset grid
set grid y2tics lt 0 lw 1 lc rgb 'blue'
replot
unset multiplot

# credit
set key outside horizontal
set ylabel 'recent credit [10^3]' tc rgb 'red'
set ytics nomirror tc rgb 'red'
set y2label 'total credit [10^3]' tc rgb 'magenta'
set y2tics tc rgb 'magenta'
set grid xtics ytics lt 0 lw 1 lc rgb 'black'
set title 'date: '.today
plot \
     '< cat 2017-??/server_status_????-??.dat' index 0 using 2:($10/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'users',\
     ''               index 0 using 2:($13/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'blue' title 'computers',\
     ''               index 0 using 2:($11/1000) with linespoints axis x1y2 pt 7 ps 1 lt 1 lw 1 lc rgb 'magenta' notitle,\
     ''               index 0 using 2:($14/1000) with linespoints axis x1y2 pt 7 ps 1 lt 1 lw 1 lc rgb 'cyan' notitle

# gigaflops
set key outside horizontal
set ylabel 'GigaFLOPs [10^3]' tc rgb 'black'
set ytics mirror tc rgb 'black'
unset y2label
unset y2tics
set grid xtics ytics lt 0 lw 1 lc rgb 'black'
set title 'date: '.today
plot \
     '< cat 2017-??/server_status_????-??.dat' index 0 using 2:($16/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' notitle

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
set xtics rotate by 90 right
set grid xtics lt 0 lw 1
plot \
     '< cat 2017-??/SixTrack_status_????-??.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'in progress',\
     ''               index 0 using 1:5 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle,\
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'ready to send '.gprintf('(M=%.1f)',M)
unset grid
set grid ytics lt 0 lw 1
replot
unset grid
set grid y2tics lt 0 lw 1 lc rgb 'blue'
replot
unset multiplot

# ------------------------------------------------------------------------------
# sixtracktest
# ------------------------------------------------------------------------------
set term qt 1
set multiplot title 'sixtracktest app'
set key outside horizontal
set ylabel 'tasks in progress/unsent [10^3]'
set ytics nomirror
set y2label 'users in last 24h' tc rgb 'blue'
set y2tics tc rgb 'blue'
set xtics rotate by 90 right
set grid xtics lt 0 lw 1
plot \
     '< cat 2017-??/sixtracktest_status_????-??.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'in progress',\
     ''               index 0 using 1:5 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle,\
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'ready to send '.gprintf('(M=%.1f)',M)
unset grid
set grid ytics lt 0 lw 1
replot
unset grid
set grid y2tics lt 0 lw 1 lc rgb 'blue'
replot
unset multiplot
