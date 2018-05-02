import sys

# ==============================================================================
# floating-point based
# ==============================================================================

def checkValues( xstart, xstop, xdelta, prec ):
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

    return xstart, xstop, xdelta

def genValues( xstart, xstop, xdelta, prec ):
    values=[]
    x0=xstart
    nIter=0
    x=x0
    if ( xdelta>0.0):
        sign=1
    else:
        sign=-1
    while ( x*sign<xstop*sign*(1+prec) ):
        if ( abs(x%1)<prec or abs(x%1-1)<prec ):
            x=int(round(x))
            x0=x
            nIter=0
        if ( not lForceIntegers ):
            x=float(x)
        values.append(x)
        nIter+=1
        x=x0+nIter*xdelta
    return values

# ==============================================================================
# integer based
# ==============================================================================

def split(x,sym='.'):
    data=x.split(sym)
    if (len(data)==1):
        # no sym -> only integer part
        x_i=data[0]
        x_f=''
    else:
        x_i=data[0]
        x_f=data[1]
    return x_i,x_f

def extremesInt( xstart, xstop, xdelta ):
    # get strings of integer and fractional parts
    xstart_i, xstart_f = split( xstart )
    xstop_i , xstop_f  = split( xstop  )
    xdelta_i, xdelta_f = split( xdelta )
    
    # analyse fractional parts
    # - get longest one:
    ll=max([len(xstart_f),len(xstop_f),len(xdelta_f)])
    # - pad with zeros:
    xstart_f=xstart_f.ljust(ll,'0')
    xstop_f =xstop_f.ljust(ll,'0')
    xdelta_f=xdelta_f.ljust(ll,'0')
    # - remove useless zeros:
    while( len(xstart_f)>0 and len(xstop_f)>0 and len(xdelta_f)>0 and xstart_f[-1]=='0' and xstop_f[-1]=='0' and xdelta_f[-1]=='0' ):
        xstart_f=xstart_f[:-1]
        xstop_f =xstop_f[:-1]
        xdelta_f=xdelta_f[:-1]
        ll=ll-1
        
    # build actual integer-made numbers:
    istart=int(xstart_i+xstart_f)
    istop =int(xstop_i+xstop_f)
    idelta=int(xdelta_i+xdelta_f)

    return istart, istop, idelta, ll

def checkInts( istart, istop, idelta ):
    # - inverted extremes
    if ( idelta>0 and istop<istart ):
        if (lInvertExtremes):
            tmpI=istop
            istop=istart
            istart=tmpI
        else:
            idelta=-idelta
        if (lDebug):
            print '1a:',istart,istop,idelta
    elif ( idelta<0 and istop>istart ):
        if (lInvertExtremes):
            tmpI=istop
            istop=istart
            istart=tmpI
        else:
            idelta=-idelta
        if (lDebug):
            print '1b:',istart,istop,idelta
            
    # - grant single points
    if ( idelta==0 ):
        idelta=1
        if ( istart!=istop ):
            istop=istart
        if (lDebug):
            print '2:',istart,istop,idelta

    return istart,istop,idelta    

def genIntValues( istart, istop, idelta, ll, sym='.' ):
    values=[]
    if (idelta<0):
        jdelta=-1
    else:
        jdelta=1
    for x in range(istart,istop+jdelta,idelta):
        tmp=str(x)
        if ( ll>0 ):
            output=''
            if (tmp[0]=='-'):
                output='-'
                tmp=tmp[1:]
            lt=len(tmp)
            if (lt<=ll):
                output+='0'+sym+''.ljust(ll-lt,'0')+tmp
            else:
                output+=tmp[:-ll]+sym+tmp[-ll:]
            if ( lForceIntegers and output[-ll:]==''.ljust(ll,'0') ):
                output=output[:len(output)-(ll+1)] # skip also the sym
            if ( lRemoveTrailingZeros and sym in output ):
                while( output[-1]=='0' ):
                    output=output[:-1]
        else:
            output=tmp
        if (lDebug):
            print 'gen:',x,output,ll,lForceIntegers
        values.append(output)
    return values

# ==============================================================================
# main
# ==============================================================================

if ( __name__ == "__main__" ):
    # some flags
    lDebug=False
    lInvertExtremes=False

    # terminal-line input parameters
    xstart=sys.argv[1]
    xstop=sys.argv[2]
    xdelta=sys.argv[3]

    # float-based or int-based loop?
    if ( len(sys.argv)>4 ):
        lIntegerBased=sys.argv[4].lower()=="true"
    else:
        lIntegerBased=True

    # dump an integer as .0 or as int?
    if ( len(sys.argv)>5 ):
        lForceIntegers=sys.argv[5].lower()=="true"
    else:
        lForceIntegers=False
        
    if ( lIntegerBased ):

        # remove trailing zeros
        if ( len(sys.argv)>6 ):
            lRemoveTrailingZeros=sys.argv[6].lower()=="true"
        else:
            lRemoveTrailingZeros=True
        
        # acquire values
        istart, istop, idelta, ll = extremesInt( xstart, xstop, xdelta )
        if (lDebug):
            print 'ints:', istart, istop, idelta, ll
        # sanity checks
        istart, istop, idelta = checkInts( istart, istop, idelta )
        if (lDebug):
            print 'after sanity checks:', istart, istop, idelta, ll
        # loop
        values = genIntValues( istart, istop, idelta, ll )
        for value in values:
            print value
        if (lDebug):
            print 'end loop:', istart, istop, idelta, ll
    else:
        if ( len(sys.argv)>6 ):
            prec=float(sys.argv[6])
        else:
            prec=1.0E-15
        # make them float, in case
        xstart=float(xstart)
        xstop=float(xstop)
        xdelta=float(xdelta)
        prec=float(prec)
        if (lDebug):
            print 'floats:',xstart,xstop,xdelta,prec
        # sanity checks
        xstart, xstop, xdelta = checkValues( xstart, xstop, xdelta, prec )
        if (lDebug):
            print 'after sanity checks:',xstart,xstop,xdelta,prec
        # loop
        values = genValues( xstart, xstop, xdelta, prec )
        for value in values:
            print value
        if (lDebug):
            print 'end loop:',xstart,xstop,xdelta,prec
