      program readdp
      implicit none 
      integer i,ich,iel,ii,itest,j,ment
      DOUBLE PRECISION dp,pieni,pieni1,sumda
      character*80 filen
      character*8192 ch
      parameter(ment=1000)
      dimension sumda(ment,60)
      pieni=1d-6
      pieni1=1d-38
      itest=1
      do 1 i=1,ment
        read(10,*,end=2) (sumda(itest,j), j=1,60)
        if(abs(sumda(itest,3)).gt.pieni1) itest=itest+1
 1    continue
 2    continue
      i=itest
      if(i.eq.ment) print*, 'readdp Warning: dimension too small' 
      iel=i-1
      ii=11
      open(ii,form='formatted',status='unknown')
      do 3 i=1,iel
        if(i.eq.1) then
          dp=sumda(i,9)
        endif
        if((abs(sumda(i,25)).gt.pieni).or.(sumda(i,9).eq.dp)) then
          write(ch,*) (sumda(i,j), j=1,60)
          do ich=8192,1,-1
            if(ch(ich:ich).ne.' ') goto 700
          enddo
 700      write(ii,'(a)') ch(:ich)
        else 
          dp=sumda(i,9)
          ii=ii+1
          open(ii,form='formatted',status='unknown')
          write(ch,*) (sumda(i,j), j=1,60)
          do ich=8192,1,-1
            if(ch(ich:ich).ne.' ') goto 701
          enddo
 701      write(ii,'(a)') ch(:ich)
        endif 
 3    continue
      STOP
      END
