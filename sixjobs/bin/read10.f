      program read10
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      character*20 title
      parameter(ment=1000)
      dimension sumda(ment,60)
      pieni=1d-38
      icount=0
      iin=0
      iend=0
      zero=0d0
      alost1=0d0
      alost2=0d0
      read(5,*) elhc,einj
      read(5,'(a20)') title
      write(*,*) elhc,einj,title
      if(abs(einj).lt.pieni) then
        print *,'Injection energy too small'
        stop
      endif
c      fac=1.25
      fac=2d0
      fac3=0.01d0 
      fac4=1.1d0
      fac5=0.9d0
      itest=1
c      achaos=1d0/pieni
      do 1 i=1,ment
        read(10,*,end=2) (sumda(itest,j), j=1,60)
        if(abs(sumda(itest,3)).gt.pieni) then 
          itest=itest+1
c          if(abs(sumda(i,7)).gt.pieni.and.sumda(i,7).lt.achaos)
c     &    achaos=sumda(i,7) 
        endif
 1    continue
 2    continue
      if(itest.eq.0) goto 999
      i=itest
      if(i.eq.ment) print*, 'read10 Warning: dimension too small' 
      iel=i-1
      if(iel.le.0) goto 999
      rat=1d0
      if(abs(sumda(1,46)).lt.pieni) then
        rat=sumda(1,8)*sumda(1,8)*sumda(1,5)/
     &  (sumda(1,7)*sumda(1,7)*sumda(1,6))
      endif
      if((sumda(1,47).gt.sumda(1,46)).or.rat.gt.1d0) rat=0d0
      if(rat.eq.0d0) then
        dummy=sumda(1,6)
        sumda(1,6)=sumda(1,5)
        sumda(1,5)=dummy
        dummy=sumda(1,8)
        sumda(1,8)=sumda(1,7)
        sumda(1,7)=dummy
        dummy=sumda(1,44)
        sumda(1,44)=sumda(1,41)
        sumda(1,41)=dummy
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
c      achaos=rad*achaos
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
      do 3 i=1,iel
        if(i.ge.2.and.rat.eq.0d0) then
          dummy=sumda(i,6)
          sumda(i,6)=sumda(i,5)
          sumda(i,5)=dummy
          dummy=sumda(i,8)
          sumda(i,8)=sumda(i,7)
          sumda(i,7)=dummy
          dummy=sumda(i,44)
          sumda(i,44)=sumda(i,41)
          sumda(i,41)=dummy
          dummy=sumda(i,47)
          sumda(i,47)=sumda(i,46)
          sumda(i,46)=dummy
          dummy=sumda(i,49)
          sumda(i,49)=sumda(i,48)
          sumda(i,48)=dummy
        endif
        if(ich1.eq.0.and.(sumda(i,11).gt.fac.or.sumda(i,11).lt.1./fac))
     &  then
          ich1=1
          achaos=rad*sumda(i,7)
          iin=i
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
        write(30,'(a20,1x,5(1pg13.6,1x))') title,rad*sumda(i,7),
     &    sumda(i,11),achaos,alost2,rad1*sumda(i,41)
 3    continue
      if(iin.ne.0.and.iend.eq.0) iend=iel
      if(iin.ne.0.and.iend.ge.iin) then
        do 4 i=iin,iend
          icount=icount+1
          if(abs(rad*sumda(i,7)).gt.pieni)
     &    alost1=alost1+rad1*sumda(i,41)/rad/sumda(i,7)
 4      continue
        alost1=alost1/icount
	if(alost1.ge.fac4.or.alost1.le.fac5) alost1=-alost1
      else
        alost1=1d0
      endif
      alost1=alost1*alost2
      write(17,'(a20,1x,6(1pg13.6,1x))') title,achaos,achaos1,alost1,
     &              alost2,rad*sumda(1,7),rad*sumda(iel,7)
      stop
 999  continue
      write(30,'(a20,1x,5(1pg13.6,1x))') title,zero,zero,zero,zero,zero
      write(17,'(a20,1x,6(1pg13.6,1x))') title,zero,zero,zero,zero,zero,
     &zero
      STOP
      END
