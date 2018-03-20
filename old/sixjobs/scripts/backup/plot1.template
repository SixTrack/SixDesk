# begin gnuplot
set term postscript color
set output "%myname%.%j%.eps"
set clabel
set style data linespoints
set title "%mynames% Angle %j%"
set xlabel "Seed Number"
set xrange [0:%myend%]
set xtics 0,1
set ylabel "DA"
set yrange [0:%maxDA%]
set ytics 0,1
set multiplot
plot "%myname%.%j%.stable" using 1:2 title "%name1%","%myname%.%j%.stable" using 1:3 title "%name2%"
set nomultiplot
quit
#end gnuplot
