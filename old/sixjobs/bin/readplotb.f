      program readplot
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      character*20 title
      integer tl,ich
      parameter(ment=1000)
      character*8192 ch
      dimension sumda(ment,60),tl(ment),al(ment),ichl(ment)
      open(27,form='formatted',recl=8192,status='unknown')
      open(25,form='formatted',recl=8192,status='unknown')
      zero=0d0
      pieni=1d-38
      icount=1
      ntlint=4
      ntlmax=12
      iin=0
      iend=0
      do 900 i=1,ntlmax
        do 900 j=1,ntlint
          tl((i-1)*ntlint+j)=nint(10**(dble(i-1)+dble(j-1)/
     &    dble(ntlint)))
          al((i-1)*ntlint+j)=zero
          ichl((i-1)*ntlint+j)=0
 900  continue
      tl(ntlmax*ntlint+1)=nint(10**(dble(ntlmax)))
      al(ntlmax*ntlint+1)=zero
      ichl(ntlmax*ntlint+1)=0
      achaos=zero
      achaos1=zero
      alost1=zero
      alost2=zero
      ilost=0
      read(5,*) elhc,einj 
      if(abs(einj).lt.pieni) then
        print *,'Injection energy too small'
        stop
      endif
      fac=2d0
c      fac=3d0
      fac1=2d0
      fac2=0.1d0
      fac3=0.01d0 
      fac4=1.1d0
      fac5=0.9d0
      itest=1
      do 1 i=1,ment
        read(10,*,end=2) (sumda(itest,j), j=1,60)
        if(abs(sumda(itest,5)).gt.pieni.and.abs(sumda(itest,6))
     &    .gt.pieni.and.abs(sumda(itest,46)).gt.pieni.and.
     &    abs(sumda(itest,47)).gt.pieni) then
          sumda(itest,7)=sqrt(sumda(itest,5)*sumda(itest,46))
          sumda(itest,8)=sqrt(sumda(itest,6)*sumda(itest,47))
        endif
        if(abs(sumda(itest,3)).gt.pieni) itest=itest+1
 1    continue
 2    continue
      if(itest.eq.1.or.sumda(1,1).eq.zero) then
        write(*,*) 'File 10 does not hold useful postprocessing data'
        stop
      endif
      i=itest
      if(i.eq.ment) print*, 'readplot Warning: dimension too small' 
      iel=i-1
      if(iel.le.0) goto 999
      rat=1d0
      if(abs(sumda(1,46)).lt.pieni.and.(abs(sumda(1,7)).gt.pieni.and.
     &  abs(sumda(1,6)).gt.pieni)) then
        rat=sumda(1,8)*sumda(1,8)*sumda(1,5)/
     &  (sumda(1,7)*sumda(1,7)*sumda(1,6))
      endif
      if((sumda(1,47).gt.sumda(1,46)).or.rat.gt.1d0) rat=zero
      if(rat.eq.zero) then
        dummy=sumda(1,6)
        sumda(1,6)=sumda(1,5)
        sumda(1,5)=dummy
        dummy=sumda(1,8)
        sumda(1,8)=sumda(1,7)
        sumda(1,7)=dummy
        dummy=sumda(1,43)
        sumda(1,43)=sumda(1,40)
        sumda(1,40)=dummy
        dummy=sumda(1,44)
        sumda(1,44)=sumda(1,41)
        sumda(1,41)=dummy
        dummy=sumda(1,45)
        sumda(1,45)=sumda(1,42)
        sumda(1,42)=dummy
        dummy=sumda(1,47)
        sumda(1,47)=sumda(1,46)
        sumda(1,46)=dummy
        dummy=sumda(1,49)
        sumda(1,49)=sumda(1,48)
        sumda(1,48)=dummy
      endif
      sigma=sqrt(sumda(1,5)*elhc/einj)
      if(abs(sumda(1,7)).gt.pieni.and.abs(sumda(1,6)).gt.pieni.and.
     &sigma.gt.pieni) then
        if(abs(sumda(1,46)).lt.pieni) then
          rad=sqrt(1d0+sumda(1,8)*sumda(1,8)*sumda(1,5)/
     &    (sumda(1,7)*sumda(1,7)*sumda(1,6)))/sigma
        else
          rad=sqrt((sumda(1,46)+sumda(1,47))/sumda(1,46))/sigma
        endif          
      else
        rad=1d0
      endif
      if(abs(sumda(1,41)).gt.pieni.and.abs(sumda(1,6)).gt.pieni.and.
     &sigma.gt.pieni) then
        if(abs(sumda(1,46)).lt.pieni) then
          rad1=sqrt(1d0+sumda(1,44)*sumda(1,44)*sumda(1,5)/
     &    (sumda(1,41)*sumda(1,41)*sumda(1,6)))/sigma
        else
          rad1=(sumda(1,44)*sqrt(sumda(1,5))-
     &    sumda(1,41)*sqrt(sumda(1,49)))/(sumda(1,41)*sqrt(sumda(1,6))-
     &    sumda(1,44)*sqrt(sumda(1,48)))
          rad1=sqrt(1d0+rad1*rad1)/sigma
        endif
      else
        rad1=1d0
      endif
      ich1=0
      ich2=0
      ich3=0
      amin=1d0/pieni
      amax=zero
      do 3 i=1,iel
        if(i.ge.2.and.rat.eq.zero) then
          dummy=sumda(i,6)
          sumda(i,6)=sumda(i,5)
          sumda(i,5)=dummy
          dummy=sumda(i,8)
          sumda(i,8)=sumda(i,7)
          sumda(i,7)=dummy
          dummy=sumda(i,43)
          sumda(i,43)=sumda(i,40)
          sumda(i,40)=dummy
          dummy=sumda(i,44)
          sumda(i,44)=sumda(i,41)
          sumda(i,41)=dummy
          dummy=sumda(i,45)
          sumda(i,45)=sumda(i,42)
          sumda(i,42)=dummy
          dummy=sumda(i,47)
          sumda(i,47)=sumda(i,46)
          sumda(i,46)=dummy
          dummy=sumda(i,49)
          sumda(i,49)=sumda(i,48)
          sumda(i,48)=dummy
        endif
        if(abs(sumda(i,7)).gt.pieni.and.sumda(i,7).lt.amin)
     &    amin=sumda(i,7) 
        if(abs(sumda(i,7)).gt.pieni.and.sumda(i,7).gt.amax)
     &    amax=sumda(i,7) 
        if(ich1.eq.0.and.(sumda(i,11).gt.fac.or.sumda(i,11).lt.1./fac))
     &  then
          ich1=1
	  iin=i
          achaos=rad*sumda(i,7)
        endif          
        if(ich3.eq.0.and.(sumda(i,10).gt.fac3)) then
          ich3=1
	  iend=i
          achaos1=rad*sumda(i,7)
        endif          
        if(ich2.eq.0.and.
     &    (sumda(i,22).lt.sumda(I,1).or.sumda(I,23).lt.sumda(I,1))) then
          ich2=1
          alost2=rad*sumda(i,7)
        endif          
        do 300 j=1,ntlmax*ntlint+1
          if(ichl(j).eq.0.and.nint(sumda(i,1)).ge.tl(j).and.
     &    (nint(sumda(i,22)).lt.tl(j).or.nint(sumda(i,23)).lt.tl(j))) 
     &    then
            ichl(j)=1
            al(j)=rad*sumda(i,7)
          endif          
 300    continue
 3    continue

      if(iin.ne.0.and.iend.eq.0) iend=iel
      if(iin.ne.0.and.iend.gt.iin) then
        do 302 i=iin,iend
          if(abs(rad*sumda(i,7)).gt.pieni)
     &    alost1=alost1+rad1*sumda(i,41)/rad/sumda(i,7)
          if(i.ne.iend) icount=icount+1
 302      continue
        alost1=alost1/icount
	if(alost1.ge.fac4.or.alost1.le.fac5) alost1=-alost1
      else
        alost1=1d0
      endif
      do 301 j=1,ntlmax*ntlint+1 
        al(j)=abs(alost1)*al(j)
 301  continue
      alost1=alost1*alost2
      if(amin.eq.1d0/pieni) amin=zero
      amin=amin*rad
      amax=amax*rad
      do 310 j=1,ntlmax*ntlint+1
        if(al(j).eq.zero) al(j)=amax
 310  continue
      alost3=sumda(1,1)
      do 30 i=1,iel
        if(sumda(i,22).eq.zero) sumda(i,22)=1d0 
        if(sumda(i,23).eq.zero) sumda(i,23)=1d0 
        if(sumda(i,22).lt.alost3) then 
          alost3=sumda(i,22)
        endif
        if(sumda(i,23).lt.alost3) then
          alost3=sumda(i,23)
        endif
 30   continue
      if(achaos.ne.zero) then 
        write(14,*) achaos,alost3/fac
        write(14,*) achaos,sumda(1,1)*fac
      endif
      if(achaos.eq.zero) achaos=amin
      if(achaos1.eq.zero) achaos1=amax
      if(abs(alost1).lt.pieni) then 
        alost1=amax
        ilost=1
      endif
      write(11,*) achaos,1d-1
      write(11,*) al(7*ntlint+1),1d-1
      write(11,*) al(6*ntlint+1),1d-1
      write(11,*) al(5*ntlint+1),1d-1
      write(11,*) al(4*ntlint+1),1d-1
      write(11,*) al(3*ntlint+1),1d-1
      write(11,*) amin,1d-1
      write(11,*) amax,1d-1
      write(11,*) achaos1,1d-1
      write(26,*) achaos,1d-1
      if(alost2.gt.pieni) then
        write(26,*) alost2,1d-1 
      else
        write(26,*) amax,1d-1
      endif
      write(ch,*) (al(j), j=1,ntlmax*ntlint+1)
      do ich=8192,1,-1
        if(ch(ich:ich).ne.' ') goto 700
      enddo
 700  write(27,'(a)') ch(:ich)
!      write(27,*) (al(j), j=1,ntlmax*ntlint+1)
      do 4 i=1,iel
        write(12,*) rad*sumda(I,7),sumda(i,11)
        write(13,*) rad*sumda(I,7),sumda(i,10)
        write(15,*) rad*sumda(I,7),sumda(i,22)
        write(15,*) rad*sumda(I,7),sumda(i,23)
 4    continue
      do 5 i=1,iel
        if(ilost.eq.1.or.rad*sumda(I,7).lt.alost2) then
          if(sumda(i,11).lt.fac1.and.sumda(i,10).lt.fac2) then
            iel2=(iel+1)/2
            write(16,*) sumda(i,9),sumda(i,3)-sumda(iel2,3)
            write(17,*) sumda(i,9),sumda(i,4)-sumda(iel2,4)
            write(20,*) rad*sumda(i,7),sumda(i,12)
            write(21,*) rad*sumda(i,7),sumda(i,14)
            write(ch,*) (sumda(I,12)+sumda(I,3)),
     &      (sumda(i,14)+sumda(I,4)),i,sumda(I,12),sumda(i,14)
            do ich=8192,1,-1
              if(ch(ich:ich).ne.' ') goto 701
            enddo
 701        write(25,'(a)') ch(:ich)
!            write(25,*) (sumda(I,12)+sumda(I,3)),
!     &        (sumda(i,14)+sumda(I,4)),i,sumda(I,12),sumda(i,14)
          endif
          write(18,*) rad*sumda(I,7),sumda(i,19)
          write(19,*) rad*sumda(I,7),sumda(i,20)
          write(22,*) rad*sumda(I,7),rad1*sumda(i,40)
          write(23,*) rad*sumda(I,7),rad1*sumda(i,41)
          write(24,*) rad*sumda(I,7),rad1*sumda(i,42)
        endif
 5    continue
 999  continue
 600  format(a20,4f12.6)
 601  format()
      STOP
      END
