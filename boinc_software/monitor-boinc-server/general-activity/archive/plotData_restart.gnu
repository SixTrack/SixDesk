reset

# changes in status page:
# - 2018-02-26: old server actually switched off on 2018-02-06;
#   -> new status page has slightly different order of table lines;
#   -> swapping $10 and $11, and $13 and $14;

restartFile='/afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server/general-activity/restart.txt'
stuckFile='../assimilatorStuck.txt'
restaFile='../assimilatorRestart.txt'

set xdata time
set timefmt '%Y-%m-%d %H:%M:%S'
# set format x '%b %Y'
set format x '%Y-%m-%d'
# set format x '%Y-%m-%d %H:%M'
# set xtics 365.2425 / 12 * 24 * 3600 rotate by 90 right
set xtics 3600*24 rotate by 90 right
set grid xtics lt 0 lw 1
# tMin=strptime("%Y-%m-%d %H:%M:%S","2019-06-01 00:00:00")
# tMax=strptime("%Y-%m-%d %H:%M:%S","2019-08-01 00:00:00")
# use bash's date command, since gnuplot's time(0.0) returns UTC time stamps,
#     and logging is in GVA local time
tNow=strptime("%Y-%m-%d %H:%M:%S",system('date +"%F %T"'))
tMax=tNow+1*24*3600
tMin=tNow-45*24*3600
set xrange [tMin:tMax]
ybar=300
M=0.1
# typical enlarged window size: 1900,400
# trigger use of png or interactive windows: 0: png, 1: interactive
linteractive=0
lprintDate=0 # 0: no date/time in png name; 1: date/time in png name
xSizeWdw=1600#regular: 1000
ySizeWdw=600#regular: 400

if ( lprintDate==0 ) {
rightNowPNG=''
} else {
rightNowPNG=system('date +"_%F_%H-%M-%S"')
}

# ------------------------------------------------------------------------------
# general overview of server status
# ------------------------------------------------------------------------------
currTitle='server overview'
if ( linteractive==0 ) {
set term png size xSizeWdw,ySizeWdw notransparent enhanced
set output '/afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server/boincStatus/serverOverview'.rightNowPNG.'.png'
} else {
set term qt 0 title currTitle size xSizeWdw,ySizeWdw
}
set multiplot title currTitle
set key outside horizontal
set ylabel 'tasks in progress/ready to send [10^3]'
set ytics nomirror
set y2label 'tasks waiting for assimilation' tc rgb 'blue'
set y2tics tc rgb 'blue'
# set y2range [0:*]
nLines=system("wc -l ".restaFile." | awk '{print ($1)}'")
plot \
     '< cat ????-??/server_status_????-??.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'in progress',\
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'ready to send '.gprintf('(x%.1f)',1.0/M),\
     ''               index 0 using 1:6 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle,\
     restartFile index 0 using 1:(ybar) with impulses lt -1 lw 2 notitle,\
     '< paste '.stuckFile.' '.restaFile.' | head -n'.nLines index 0 using 1:(0.5*ybar):1:3 with xerrorbars lt -1 lw 1 notitle
     
unset grid
set grid ytics lt 0 lw 1
replot
unset grid
set grid y2tics lt 0 lw 1 lc rgb 'blue'
replot
unset multiplot
# set y2range [*:*]

# credit
currTitle='credit'
if ( linteractive==0 ) {
set term png size xSizeWdw,ySizeWdw notransparent enhanced
set output '/afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server/boincStatus/creditOverview'.rightNowPNG.'.png'
} else {
set term qt 1 title currTitle size xSizeWdw,2*ySizeWdw
}
set title currTitle
set key inside horizontal top center
set ylabel 'recent credit [10^3]' tc rgb 'red'
set ytics nomirror tc rgb 'red'
set y2label 'total credit [10^3]' tc rgb 'blue'
set y2tics tc rgb 'blue'
set grid xtics ytics lt 0 lw 1 lc rgb 'black'
set multiplot layout 2,1
fact=1E3
#
set title 'users'
# set yrange [7.5E3/fact:10E3/fact]
# set y2range [158E3/fact:165E3/fact]
plot \
     '< cat ????-??/server_status_????-??.dat' index 0 using 1:($11/fact) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'with recent credit',\
     ''               index 0 using 1:($10/fact) with linespoints axis x1y2 pt 7 ps 1 lt 1 lw 1 lc rgb 'blue' title 'with credit'
set title 'computers'
# set yrange [21E3/fact:25E3/fact]
# set y2range [450E3/fact:470E3/fact]
plot \
     '< cat ????-??/server_status_????-??.dat' index 0 using 1:($14/fact) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'with recent credit',\
     ''               index 0 using 1:($13/fact) with linespoints axis x1y2 pt 7 ps 1 lt 1 lw 1 lc rgb 'blue' title 'with credit'
# set yrange [*:*]
# set y2range [*:*]
unset multiplot

# gigaflops
currTitle='TeraFLOPs'     
if ( linteractive==0 ) {
set term png size xSizeWdw,ySizeWdw notransparent enhanced
set output '/afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server/boincStatus/teraFLOPsOverview'.rightNowPNG.'.png'
} else {
set term qt 2 title currTitle size xSizeWdw,ySizeWdw
}
set title currTitle
set key outside horizontal
set ylabel 'TeraFLOPs []' tc rgb 'black'
set ytics mirror tc rgb 'black'
unset y2label
unset y2tics
set grid xtics ytics lt 0 lw 1 lc rgb 'black'
# set yrange [70:155]
plot \
     '< cat ????-??/server_status_????-??.dat' index 0 using 1:($16/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' notitle
# set yrange [*:*]
unset title

# WUs waiting for validation
currTitle='Validation'     
if ( linteractive==0 ) {
set term png size xSizeWdw,ySizeWdw notransparent enhanced
set output '/afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server/boincStatus/validationOverview'.rightNowPNG.'.png'
} else {
set term qt 3 title currTitle size xSizeWdw,ySizeWdw
}
set title currTitle
set key outside horizontal
set ylabel 'WUs waiting for validation []' tc rgb 'black'
set ytics mirror tc rgb 'black'
unset y2label
unset y2tics
set grid xtics ytics lt 0 lw 1 lc rgb 'black'
plot \
     '< cat ????-??/server_status_????-??.dat' index 0 using 1:5 with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' notitle
unset title

# ------------------------------------------------------------------------------
# sixtrack
# ------------------------------------------------------------------------------
currTitle='SixTrack app'
if ( linteractive==0 ) {
set term png size xSizeWdw,ySizeWdw notransparent enhanced
set output '/afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server/boincStatus/sixtrackOverview'.rightNowPNG.'.png'
} else {
set term qt 4 title currTitle size xSizeWdw,ySizeWdw
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
     '< cat ????-??/SixTrack_status_????-??.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'in progress',\
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'ready to send '.gprintf('(x%.1f)',1.0/M),\
     ''               index 0 using 1:5 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle
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
set term png size xSizeWdw,ySizeWdw notransparent enhanced
set output '/afs/cern.ch/work/s/sixtadm/public/monitor_activity/boinc_software/monitor-boinc-server/boincStatus/sixtracktestOverview'.rightNowPNG.'.png'
} else {
set term qt 5 title currTitle size xSizeWdw,ySizeWdw
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
     '< cat ????-??/sixtracktest_status_????-??.dat' index 0 using 1:($4/1000) with linespoints pt 7 ps 1 lt 1 lw 1 lc rgb 'red' title 'in progress',\
     ''               index 0 using 1:($3/1000*M) with linespoints pt 7 ps 1 lt 2 lw 1 lc rgb 'green' title 'ready to send '.gprintf('(x%.1f)',1.0/M),\
     ''               index 0 using 1:5 with linespoints axis x1y2 pt 7 ps 1 lt 2 lw 1 lc rgb 'blue' notitle
unset grid
set grid ytics lt 0 lw 1
replot
unset grid
set grid y2tics lt 0 lw 1 lc rgb 'blue'
replot
unset multiplot
