      program repair
      implicit none
      integer ment,i,j,ich
      double precision sumda,hor,ver,rlon
      parameter(ment=1000)
      dimension sumda(ment,60)
      character*8192 ch
      open(11,form='formatted',status='unknown')
      do 1 i=1,ment
        read(10,*,end=2) (sumda(i,j), j=1,60)
        read(93,*,end=900) hor
        sumda(i,12)=abs(hor)-(sumda(i,3)-int(sumda(i,3)))
 900    read(94,*,end=901) ver
        sumda(i,14)=abs(ver)-(sumda(i,4)-int(sumda(i,4)))
 901    read(95,*,end=902) rlon
        if(abs(rlon).gt.0.5) then
          sumda(i,25)=1d0-abs(rlon)
	else
          sumda(i,25)=abs(rlon)
	endif
 902    write(ch,*) (sumda(i,j), j=1,60)
        do ich=8192,1,-1
          if(ch(ich:ich).ne.' ') goto 700
        enddo
 700    write(11,'(a)') ch(:ich)
 1    continue
 2    continue
      STOP
      END
