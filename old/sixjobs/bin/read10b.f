      program read10
      implicit none
      integer i,j,iel,icount,iin,iend,itest,ment,ich1,ich2,ich3
      parameter(ment=10000)
      double precision sumda(ment,60),alost1,alost2,elhc,einj,dummy,    &
     &achaos,achaos1,rad,rad1,rat,sigma,zero,one,two,pieni,fac,fac3,    &
     &fac4,fac5
      parameter(zero=0d0,one=1d0,two=2d0,pieni=1d-10,fac=two,           &
     &fac3=1d-2,fac4=1.1d0,fac5=0.9d0)
      character*40 title
      
      icount=1
      iin=0
      iend=0
      alost1=zero
      alost2=zero
      read(5,*) elhc,einj
      read(5,'(a40)') title
      write(6,'(2f12.5,a40)') elhc,einj,title
      if(abs(einj).le.pieni) then
        print *,'Injection energy too small'
        stop
      endif
      itest=1
      do i=1,ment
        read(10,*,end=2) (sumda(itest,j), j=1,60)
        if(abs(sumda(itest,5)).gt.pieni.and.abs(sumda(itest,46)).gt.    &
     &    pieni) sumda(itest,7)=sqrt(sumda(itest,5)*sumda(itest,46))
        if(abs(sumda(itest,6)).gt.pieni.and.abs(sumda(itest,47)).gt.    &
     &    pieni) sumda(itest,8)=sqrt(sumda(itest,6)*sumda(itest,47))
        if(abs(sumda(itest,3)).gt.pieni.and.abs(sumda(itest,4)).gt.     &
     &    pieni.and.                                                    &
     &    sumda(itest,5).gt.pieni.and.sumda(itest,6).gt.pieni.and.      &
     &    (abs(sumda(itest,7)).gt.pieni.or.abs(sumda(itest,8)).gt.      &
     &    pieni)) itest=itest+1
      enddo
 2    continue
      if(itest.eq.ment) print*, 'read10 Warning: dimension too small' 
      iel=itest-1
      if(iel.le.0) goto 999
      rat=one
      if(abs(sumda(1,46)).le.pieni) then
        if(abs(sumda(1,7)).gt.pieni) then
          rat=sumda(1,8)*sumda(1,8)*sumda(1,5)/                         &
     &    (sumda(1,7)*sumda(1,7)*sumda(1,6))
        elseif(sumda(1,7)*sumda(1,7)*sumda(1,6).lt.                     &
     &  sumda(1,8)*sumda(1,8)*sumda(1,5)) then
          rat=two
        endif
      endif
      if((sumda(1,47).gt.sumda(1,46)).or.rat.gt.one) rat=zero
      if(rat.eq.zero) then
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
      if(abs(sumda(1,7)).gt.pieni.and.abs(sumda(1,6)).gt.pieni.and.     &
     &sigma.gt.pieni) then
        if(abs(sumda(1,46)).le.pieni) then
          rad=sqrt(one+sumda(1,8)*sumda(1,8)*sumda(1,5)/                &
     &    (sumda(1,7)*sumda(1,7)*sumda(1,6)))/sigma
        else
          rad=sqrt((sumda(1,46)+sumda(1,47))/sumda(1,46))/sigma
        endif          
      else
        rad=one
      endif
      if(abs(sumda(1,41)).gt.pieni.and.abs(sumda(1,6)).gt.pieni.and.    &
     &sigma.gt.pieni) then
        if(abs(sumda(1,46)).le.pieni) then
          rad1=sqrt(one+sumda(1,44)*sumda(1,44)*sumda(1,5)/             &
     &    (sumda(1,41)*sumda(1,41)*sumda(1,6)))/sigma
        else
          rad1=(sumda(1,44)*sqrt(sumda(1,5))-                           &
     &    sumda(1,41)*sqrt(sumda(1,49)))/(sumda(1,41)*sqrt(sumda(1,6))- &
     &    sumda(1,44)*sqrt(sumda(1,48)))
          rad1=sqrt(one+rad1*rad1)/sigma
        endif
      else
        rad1=one
      endif
      ich1=0
      ich2=0
      ich3=0
      do i=1,iel
        if(i.eq.1) then
          achaos=rad*sumda(1,7)
          achaos1=achaos
        endif
        if(i.ge.2.and.rat.eq.zero) then
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
        if(ich1.eq.0.and.(sumda(i,11).gt.fac.or.sumda(i,11).lt.one/fac))
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
        write(30,'(a40,5f12.6)') title,rad*sumda(i,7),sumda(i,11),
     &    achaos,alost2,rad1*sumda(i,41)
      enddo
      if(iin.ne.0.and.iend.eq.0) iend=iel
      if(iin.ne.0.and.iend.gt.iin) then
        do i=iin,iend
          if(abs(rad*sumda(i,7)).gt.pieni)
     &    alost1=alost1+rad1*sumda(i,41)/rad/sumda(i,7)
          if(i.ne.iend) icount=icount+1
        enddo
        alost1=alost1/icount
	if(alost1.ge.fac4.or.alost1.le.fac5) alost1=-alost1
      else
        alost1=one
      endif
      alost1=alost1*alost2
      write(17,600) title,achaos,achaos1,alost1,alost2,
     &              rad*sumda(1,7),rad*sumda(iel,7)
      stop
 999  continue
      write(30,'(a40,5f12.6)') title,zero,zero,zero,zero,zero
      write(17,600) title,zero,zero,zero,zero,zero,zero
      STOP
 600  format(a40,6f12.6)
      END
