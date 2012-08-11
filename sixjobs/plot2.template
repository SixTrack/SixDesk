# begin gnuplot
set term postscript color
set output "%myname%.%myend%.eps"
set clabel
set style data points
set title "%mynames% Summary PLot of All Angles"
set xlabel "Angle"
set xrange [%mybegin%:%myend%]
set xtics 0,5
set ylabel "DA"
set yrange [0:%maxDA%]
set ytics 0,1
set multiplot
plot "%myname%.sum" using 1:2:3:4 with yerrorbars title "%name1%","%myname%.sum" using 1:5:6:7 with yerrorbars title "%name2%"
set nomultiplot
quit
#end gnuplot
