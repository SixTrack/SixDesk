*=======================================================================
*     Yannis Papaphilippou        :     DEC-1997   
*
*     Program that reads files with resonance amplitudes and detuning and
*     correlates them with the dynamic aperture
*
*=======================================================================

 
      PROGRAM  CORREL
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER (I-N)
      PARAMETER (N = 60, NR = 250)
      DIMENSION DYNAP(N),RESON(N),q(50)
      DIMENSION DETUHOR1(N),DETUVER1(N),RESON1(N,NR),RSQR1(NR)
      DIMENSION DETUHOR2(N),DETUVER2(N),RESON2(N,NR),RSQR2(NR)


****************************
*   Input and Output files
****************************


      OPEN (1001,FILE='sumall',STATUS='OLD',FORM='FORMATTED')

      OPEN (1002,FILE='sumalldyn',STATUS='OLD',FORM='FORMATTED')

      OPEN (1003,FILE='correl.dat',STATUS='UNKNOWN',FORM='FORMATTED')

      OPEN (1004,FILE='correldyn.dat',STATUS='UNKNOWN',FORM='FORMATTED')
      
      OPEN (1005,FILE='cor.inp',STATUS='OLD',FORM='FORMATTED')
      READ (1005,*) Na,Ne,Nro
     
******************************
* calculating the total number 
* of seeds and of resonances
******************************
       
      Nm = Ne - Na + 1
      i = 0
      do i = 1,Nro
         Nrm = 2*i + Nrm
      end do
      write(*,*) 'Nm,Nrm=',Nm,Nrm

*************************************************
* calculating the total number of detuning terms 
*************************************************

      if (nro/2.d0-idint(nro/2.d0).eq.0.d0) then
         nrdt = nro - 2
      else
         nrdt = nro - 3
      end if 
     
      ndet = 0
       
      do i = 2,nrdt/2+1
         ndet = i + ndet
      end do
      ndet = ndet + nrdt/2 - 1
      write(*,*) 'ndet=',ndet,nrdt



********************************
* Reading the dynamic aperture
* + detuning + resonance file
********************************
      

      DO i = 1,Nm
         READ(1001,101)is,DYNAP(i),(q(j), j=1,ndet),DETUHOR1(i),
     $                 (q(j), j=1,ndet),DETUVER1(i),
     $                 (RESON1(i,k), k=1,nrm)

         READ(1002,101)is,D,(q(j), j=1,ndet),DETUHOR2(i),
     $                 (q(j), j=1,ndet),DETUVER2(i),
     $                 (RESON2(i,k), k=1,nrm)
      END DO

**************************************************
* Calculation of the correlations for the detuning
**************************************************

      call RSQUARE(Nm,DYNAP,DETUHOR1,rsqhor1)

      call RSQUARE(Nm,DYNAP,DETUVER1,rsqver1)

      call RSQUARE(Nm,DYNAP,DETUHOR2,rsqhor2)

      call RSQUARE(Nm,DYNAP,DETUVER2,rsqver2)

*      write(*,*)  detuhor1,detuver1,detuhor2,detuver2
*      write(*,*)  rsqhor1,rsqver1,rsqhor2,rsqver2

****************************************************
* Calculation of the correlations for the resonances
****************************************************

      DO j = 1,Nrm

         DO i = 1,Nm
           RESON(i) = RESON1(i,j)
         END DO
         call RSQUARE(Nm,DYNAP,RESON,rsq)
         rsqr1(j) = rsq
         DO i = 1,Nm
           RESON(i) = RESON2(i,j)
         END DO
         call RSQUARE(Nm,DYNAP,RESON,rsq)
         rsqr2(j) = rsq

*         write(*,*) rsqr1(j),rsqr2(j),j
         
      END DO

*      DO i = 1,Nm
*         write(*,*) RESON1(i,43),i
*      END DO   

      write(1003,102) rsqhor1,rsqver1,(rsqr1(i), i=1,Nrm)
      write(1004,102) rsqhor2,rsqver2,(rsqr2(i), i=1,Nrm)
*      write(*,102) rsqhor1,rsqver1,rsqr1
*      write(*,102) rsqhor2,rsqver2,rsqr2

101   FORMAT(i3,2X,G18.8,250(G20.8))
102   FORMAT(23X,24(20X),G20.8,24(20X),G20.8,156(G20.8))
      END



********************************
* subroutine calculating the 
* linear correlation coefficient
********************************

      SUBROUTINE RSQUARE(NT,X,Y,rsq)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER (I-N)
      DIMENSION X(NT),Y(NT)

      prodxy0 = 0.d0
      sumx0 = 0.d0
      sumy0 = 0.d0
      sumxsq0 = 0.d0
      sumysq0 = 0.d0
      
      DO i=1,NT
         prodxy = x(i)*y(i) + prodxy0
         prodxy0 = prodxy
         sumx= x(i) + sumx0
         sumx0 = sumx
         sumy= y(i) + sumy0
         sumy0 = sumy
         sumxsq = x(i)**2.d0 + sumxsq0
         sumxsq0 = sumxsq
         sumysq = y(i)**2.d0 + sumysq0
         sumysq0 = sumysq
      END DO

      rsq = ((NT*prodxy - sumx*sumy)/dsqrt((NT*sumxsq-sumx**2.d0)*
     $      (NT*sumysq-sumy**2.d0)))**2.d0

      END
