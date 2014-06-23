      program readweb
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      character*20 title
      parameter(ment=5000,mele=100)
      dimension qx(mele,mele),qz(mele,mele)
      do 900 i=1,mele
      do 900 j=1,mele
        qx(i,j)=0d0
        qx(i,j)=0d0
 900  continue
      i0=1
      i1=1 
      i2=1 
      do 1 j=1,ment
        read(10,*,end=2) a,b,i
        if(i.gt.mele) then
          print*, 'readweb Warning:', 
     &      ' (mele) dimension too small' 
          goto 2
        endif
        if(i.gt.i2) i2=i
        if(i0.gt.i) then
          write(11,*)
          i1=i1+1
          if(i1.gt.mele) then
            print*, 'readweb Warning:', 
     &        ' (mele) dimension too small' 
            goto 2
          endif
        endif
        qx(i1,i)=a
        qz(i1,i)=b
        write(11,*) a,b
        i0=i
 1    continue
 2    continue
      write(11,*)
      if(j.eq.ment) print*, 'readweb Warning:', 
     &  ' (ment) dimension too small' 
      iel=j-1
      if(iel.le.0) goto 999
      if(i1.gt.1) then
        j=0
        do 3 i=1,i2
 4        j=j+1
          j0=j
          if(qx(j,i).ne.0d0.and.qz(j,i).ne.0d0) then
            write(11,*) qx(j0,i),qz(j0,i)
            if(j0.eq.i1) goto 6
 5          if(qx(j+1,i).ne.0d0.and.qz(j+1,i).ne.0d0) then
              write(11,*) qx(j+1,i),qz(j+1,i)
              j=j+1
              if(j.eq.i1) goto 6
              goto 4
            else
              j=j+1
              if(j.eq.i1) goto 6
              goto 5
            endif
          else
            if(j0.eq.i1) goto 6
            goto 4
          endif
 6        j=0
          write(11,*)
 3      continue
      endif
 999  continue
      STOP
      END


