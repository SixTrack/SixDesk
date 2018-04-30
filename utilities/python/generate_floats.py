import sys

lDebug=False
lInvertExtremes=False

xstart=float(sys.argv[1])
xstop=float(sys.argv[2])
xdelta=float(sys.argv[3])
prec=float(sys.argv[4])

if (lDebug):
    print 'floats:',xstart,xstop,xdelta,prec

# checks

# - null values:
if ( abs(xstart)<prec):
    xstart=0.0
if ( abs(xstop)<prec):
    xstop=0.0
if ( abs(xdelta)<prec):
    delta=0.0

# - inverted extremes
if ( xdelta>0.0 and xstop<xstart ):
    if (lInvertExtremes):
        tmpX=xstop
        xstop=xstart
        xstart=tmpX
    else:
        xdelta=-xdelta
    if (lDebug):
        print '1a:',xstart,xstop,xdelta,prec
elif ( xdelta<0.0 and xstop>xstart ):
    if (lInvertExtremes):
        tmpX=xstop
        xstop=xstart
        xstart=tmpX
    else:
        xdelta=-xdelta
    if (lDebug):
        print '1b:',xstart,xstop,xdelta,prec
        
# - grant single points
if ( xdelta==0.0 ):
    if ( xstop==0.0 ):
        if ( xstart==0.0 ):
            xfin=1
        else:
            xfin=xstart
    else:
        if ( xstart==0.0 ):
            xfin=xstop
        else:
            xfin=xstart
    xdelta=xfin
    xstop=xstart+xfin*0.5
    if (lDebug):
        print '2:',xstart,xstop,xdelta,prec
else:
    if ( abs(xstop-xstart)<prec ):
        # xstop==xstart
        if ( xstart==0.0 ):
            xfin=1
        else:
            xfin=xstart
        xdelta=xfin
        xstop=xstart+xfin*0.5
        if (lDebug):
            print '3:',xstart,xstop,xdelta,prec

# - do not skip last point
if (xstop==0.0):
    xstop=xdelta*0.5
    if (lDebug):
        print '4:',xstart,xstop,xdelta,prec

x0=xstart
nIter=0
x=x0
if (lDebug):
    print 'start loop:',xstart,xstop,xdelta,prec
if ( xdelta>0.0):
    sign=1
else:
    sign=-1
while ( x*sign<xstop*sign*(1+prec) ):
    if ( abs(x%1)<prec or abs(x%1-1)<prec ):
        print int(round(x))
    else:
        print x
    nIter+=1
    x=x0+nIter*xdelta
if (lDebug):
    print 'end loop:',xstart,xstop,xdelta,prec
