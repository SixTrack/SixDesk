reset

restartFile='/home/amereghe/Documents/notebooks/simulations/code development/general notes/boinc/monitoring restarts/restart.txt/restart.txt'
stuckFile='../assimilatorStuck.txt'
restaFile='../assimilatorRestart.txt'

set xdata time
set timefmt '%Y-%m-%d %H:%M:%S'
set format x '%Y-%m-%d %H:%M'
ybar=500
M=1
# typical enlarged window size: 1900,400
# trigger use of png or interactive windows: 0: png, 1: interactive
linteractive=1
rightNowPNG=system('date +"%F_%H-%M-%S"')

# ------------------------------------------------------------------------------
# general overview of server status
# ------------------------------------------------------------------------------
currTitle='server overview'
if ( linteractive==0 ) {
set term png font "Times-Roman" size 1200,400 notransparent enhanced
set output '/home/amereghe/Downloads/boincStatus/serverOverview_'.rightNowPNG.'.png'
} else {
set term qt 0 title currTitle font "Times-Roman" size 1000,400
}
set multiplot title currTitle
set key outside horizontal
set ylabel 'tasks in progress/ready to send [10^3]'
set ytics nomirror
set y2label 'tasks waiting for assimilation' tc rgb 'blue'
set y2tics tc rgb 'blue'
set xtics 3600*24 rotate by 90 right
set grid xtics lt 0 lw 1
tMin=strptime("%Y-%m-%d %H:%M:%S","2017-05-05 00:00:00")
set xrange [tMin:*]
nLines=system("wc -l ".restaFile." | awk '{print ($1)}'")
plot \
     '< cat 2017-??/server_status_????-??.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'in progress',\
     ''               index 0 using 1:6 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle,\
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'ready to send '.gprintf('(x1/%.1f)',M),\
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
currTitle='credit'
if ( linteractive==0 ) {
set term png font "Times-Roman" size 1200,400 notransparent enhanced
set output '/home/amereghe/Downloads/boincStatus/creditOverview_'.rightNowPNG.'.png'
} else {
set term qt 1 title currTitle font "Times-Roman" size 1000,400
}
set title currTitle
set key outside horizontal
set ylabel 'recent credit (users/computers) [10^3]' tc rgb 'red'
set ytics nomirror tc rgb 'red'
set y2label 'total credit (users/computers) [10^3]' tc rgb 'magenta'
set y2tics tc rgb 'magenta'
set grid xtics ytics lt 0 lw 1 lc rgb 'black'
plot \
     '< cat 2017-??/server_status_????-??.dat' index 0 using 1:($10/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'users',\
     ''               index 0 using 1:($13/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'blue' title 'computers',\
     ''               index 0 using 1:($11/1000) with linespoints axis x1y2 pt 7 ps 1 lt 1 lw 1 lc rgb 'magenta' notitle,\
     ''               index 0 using 1:($14/1000) with linespoints axis x1y2 pt 7 ps 1 lt 1 lw 1 lc rgb 'cyan' notitle

# gigaflops
currTitle='TeraFLOPs'     
if ( linteractive==0 ) {
set term png font "Times-Roman" size 1200,400 notransparent enhanced
set output '/home/amereghe/Downloads/boincStatus/teraFLOPsOverview_'.rightNowPNG.'.png'
} else {
set term qt 2 title currTitle font "Times-Roman" size 1000,400
}
set title currTitle
set key outside horizontal
set ylabel 'TeraFLOPs []' tc rgb 'black'
set ytics mirror tc rgb 'black'
unset y2label
unset y2tics
set grid xtics ytics lt 0 lw 1 lc rgb 'black'
plot \
     '< cat 2017-??/server_status_????-??.dat' index 0 using 1:($16/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' notitle
unset title

# WUs waiting for validation
currTitle='Validation'     
if ( linteractive==0 ) {
set term png font "Times-Roman" size 1200,400 notransparent enhanced
set output '/home/amereghe/Downloads/boincStatus/validationOverview_'.rightNowPNG.'.png'
} else {
set term qt 3 title currTitle font "Times-Roman" size 1000,400
}
set title currTitle
set key outside horizontal
set ylabel 'WUs waiting for validation []' tc rgb 'black'
set ytics mirror tc rgb 'black'
unset y2label
unset y2tics
set grid xtics ytics lt 0 lw 1 lc rgb 'black'
plot \
     '< cat 2017-??/server_status_????-??.dat' index 0 using 1:5 with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' notitle
unset title

# ------------------------------------------------------------------------------
# sixtrack
# ------------------------------------------------------------------------------
currTitle='SixTrack app'
if ( linteractive==0 ) {
set term png font "Times-Roman" size 1200,400 notransparent enhanced
set output '/home/amereghe/Downloads/boincStatus/sixtrackOverview_'.rightNowPNG.'.png'
} else {
set term qt 4 title currTitle font "Times-Roman" size 1000,400
}
set multiplot title currTitle
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
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'ready to send '.gprintf('(x1/%.1f)',M)
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
currTitle='sixtracktest app'
if ( linteractive==0 ) {
set term png font "Times-Roman" size 1200,400 notransparent enhanced
set output '/home/amereghe/Downloads/boincStatus/sixtracktestOverview_'.rightNowPNG.'.png'
} else {
set term qt 5 title currTitle font "Times-Roman" size 1000,400
}
set multiplot title currTitle
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
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'ready to send '.gprintf('(x1/%.1f)',M)
unset grid
set grid ytics lt 0 lw 1
replot
unset grid
set grid y2tics lt 0 lw 1 lc rgb 'blue'
replot
unset multiplot
