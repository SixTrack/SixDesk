import sys

xmin=float(sys.argv[1])
xmax=float(sys.argv[2])
xdelta=float(sys.argv[3])
prec=float(sys.argv[4])

# checks
if ( xmax<xmin ):
    tmp=xmax
    xmax=xmin
    xmin=tmp
if ( abs(xdelta)<prec):
    xdelta=xmin
if ( xmin != 0.0 ):
    if ( abs(xmax/xmin-1)<prec ):
        xdelta=xmin
        xmax=xmin
elif ( xdelta != 0.0 ):
    if ( abs(xmax/xdelta-1)<prec ):
        xdelta=xmin
        xmax=xmin
else:
    if ( abs(xmax)<prec ):
        xdelta=xmin
        xmax=xmin

x=xmin
while ( x<xmax*(1+prec) ):
    if ( x-int(x) < prec ):
        print int(x)
    else:
        print x
    x+=xdelta
