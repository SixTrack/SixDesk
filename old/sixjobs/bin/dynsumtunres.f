*=======================================================================
*     Yannis Papaphilippou        :     DEC-1997   
*
*     Program that reads the normal form files fort.20 and detuning files 
*     fort.25 for different seeds and produces the files sumall.dat and
*     sumalldyn.dat with all detuning terms and resonance terms added up 
*     to a certain amplitude
*
*=======================================================================

 
      PROGRAM  DYNSUMTUNRES
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER (I-N)
      PARAMETER (N = 2000, NP = 4000, NI = 200, NT = 20)
      DIMENSION F_JKLM(NI),F_JKLM_C(NI),F_JKLM_S(NI),ix(NI),iy(NI)
      DIMENSION F_JKLMD(NI),F_JKLM_CD(NI),F_JKLM_SD(NI)
      DIMENSION ixt(NT),iyt(NT)
      DIMENSION fjklmthf(NT),fjklmtvf(NT),fjklmthdf(NT),fjklmtvdf(NT)
      DIMENSION AMPTH(NT),AMPTHP(NT),kxth(NT),kyth(NT),lxth(NT),lyth(NT)
      DIMENSION AMPTV(NT),AMPTVP(NT),kxtv(NT),kytv(NT),lxtv(NT),lytv(NT)
      DIMENSION AMPP(NP),AMPH(NP),kxp(NP),kyp(NP),lxp(NP),lyp(NP)     
      DIMENSION AMPP1(N),AMPH1(N),kxp1(N),kyp1(N),lxp1(N),lyp1(N)
      DIMENSION AMPP2(N),AMPH2(N),kxp2(N),kyp2(N),lxp2(N),lyp2(N)
      INTEGER ord


****************************
*   Input and Output files
****************************

      OPEN (1001,FILE='tunhor.dat',STATUS='OLD',
     $FORM='FORMATTED')

      OPEN (1002,FILE='tunver.dat',STATUS='OLD',
     $FORM='FORMATTED')


      OPEN (1003,FILE='ordercos.dat',STATUS='OLD',
     $FORM='FORMATTED')

      OPEN (1004,FILE='ordersin.dat',STATUS='OLD',
     $FORM='FORMATTED')

      OPEN (1005,FILE='res.dat',STATUS='OLD',
     $FORM='FORMATTED')

      OPEN (1006,FILE='sumall.dat',STATUS='OLD',FORM='FORMATTED',
     $      ACCESS='APPEND')

      OPEN (1007,FILE='sumalldyn.dat',STATUS='OLD',FORM='FORMATTED',
     $      ACCESS='APPEND')
      
      OPEN (1008,FILE='ord.inp',STATUS='OLD',FORM='FORMATTED')
      READ (1008,*) omx,omy,nsigma,akey,nmax,en,e0

      OPEN (1009,FILE='seed',STATUS='OLD',FORM='FORMATTED')
      READ (1009,*) iseed
    
      OPEN (1010,FILE='dynap.dat',STATUS='OLD',FORM='FORMATTED')
 

**************************************
* Reading the dynamic aperture  file
**************************************    
      
      DO i=1,iseed
         READ (1010,*) dynap
      END DO

      

      pi = 4.0d0*datan(1.0d0)
      akeyc = dcos(akey*pi/1.80d2)
      akeys = dsin(akey*pi/1.80d2)
      sigma=nsigma*dsqrt(en/e0)
      dsigma=dynap*dsqrt(en/e0)
      amp0 = 10.d0 
      m = 0
*      write(*,*) akeyc,akeys,sigma,nsigma,akey,dsigma,dynap

*****************************************
* Reading the horizontal detuning  file
*****************************************

      call READFILE(1001,NT,ampthp,kxth,lxth,kyth,lyth,mend)
      mhend = mend

*****************************************
* Reading the vertical detuning file
*****************************************

      call READFILE(1002,NT,amptvp,kxtv,lxtv,kytv,lytv,mend)
      mvend = mend

      if (mhend.ne.mvend) then
         stop 'tune component vectors have not the same length'
      else
         ntun = mend
      end if

***************************************
* arranging the tune resonance numbers  
***************************************

      if (nmax/2.d0-idint(nmax/2.d0).eq.0.d0) then
         nordtune = nmax - 2
      else
         nordtune = nmax - 3
      end if
      
      

      call STRUCTUNE(nordtune,N,ixt,iyt,num)
*      write(*,*)  nordtune,num,ntun

*******************************************************
* calculating the total number of detuning terms and of
* the evaluated detuning for each order up to nordtune 
*******************************************************
       
      ndet = 0
       
      do i = 2,nordtune/2+1
         ndet = i + ndet
      end do
*      write(*,*) ndet


********************************************
* calculating the total number of resonances
********************************************

      do i = 1,Nmax
         Nro = 2*i + Nro
      end do


******************************************************************
* calculating the horizontal and vertical detuning order by order
******************************************************************

      m=0
      j=0

      fjklmth0 = 0.d0 
      fjklmth  = 0.d0 
      fjklmtv0 = 0.d0 
      fjklmtv  = 0.d0 
      fjklmthd0 = 0.d0 
      fjklmthd  = 0.d0 
      fjklmtvd0 = 0.d0 
      fjklmtvd  = 0.d0 


      DO m = 1,num
         DO  j = 1,ntun
            if (ixt(m).eq.(kxth(j)+lxth(j)).and.
     $          iyt(m).eq.(kyth(j)+lyth(j))) then
                nsum = kxth(j) + lxth(j) + kyth(j) + lyth(j)
                jk = kxth(j) + lxth(j)
                lm = kyth(j) + lyth(j)
                fjklmth = ampthp(j)*(sigma**nsum)*(akeyc**jk)
     $                    *(akeys**lm) + fjklmth0
                fjklmth0 = fjklmth
                fjklmthd = ampthp(j)*(dsigma**nsum)*(akeyc**jk)
     $                    *(akeys**lm) + fjklmthd0
                fjklmthd0 = fjklmthd
                ampth(m) = ampthp(j)
*             write(*,*) fjklmth,fjklmthd,kxth(j),lxth(j),kyth(j),lyth(j)
*     $                  ,ampth(j)
            end if
            if (ixt(m).eq.(kxtv(j)+lxtv(j)).and.
     $          iyt(m).eq.(kytv(j)+lytv(j))) then
                nsum = kxtv(j) + lxtv(j) + kytv(j) + lytv(j)
                jk = kxtv(j) + lxtv(j)
                lm = kytv(j) + lytv(j)
                fjklmtv  = amptvp(j)*(sigma**nsum)*(akeyc**jk)
     $                    *(akeys**lm) + fjklmtv0
                fjklmtv0 = fjklmtv  
                fjklmtvd = amptvp(j)*(dsigma**nsum)*(akeyc**jk)
     $                     *(akeys**lm) + fjklmtvd0
                fjklmtvd0 = fjklmtvd  
                amptv(m) = amptvp(j)            
*             write(*,*) fjklmtv,fjklmtvd,kxtv(j),lxtv(j),kytv(j),lytv(j)
*     $                  ,amptv(j)
            end if
        END DO
        if (nsum/2.d0-idint(nsum/2.d0).eq.0.d0) then  
           fjklmthf(nsum/2) =  fjklmth
           fjklmtvf(nsum/2) =  fjklmtv 
           fjklmthdf(nsum/2) =  fjklmthd
           fjklmtvdf(nsum/2) =  fjklmtvd
        end if
      END DO          
*      write(*,*) ampth,fjklmthf
*      write(*,*)
*      write(*,*) amptv,fjklmtvf
*      write(*,*)
*      write(*,*) fjklmthdf,fjklmtvdf


*************************************************************************
* Reading the cosine components of the normal forms' generating function
*************************************************************************

      call READFILE(1003,NP,ampp,kxp,lxp,kyp,lyp,mend)


*****************************************************
* Taking the double product of the cosine amplitudes
*****************************************************


      m = 0
      jend = mend
      j = 0
      i = 0
      DO WHILE (m.le.mend)
         m = m + 1
         j = m + 1
         DO WHILE (j.le.mend)
            if (dabs(dabs(ampp(m))-dabs(ampp(j))).lt.1.d-14) then
               i = i + 1
               ampp1(i) = 2.d0*ampp(m)
               kxp1(i) = kxp(m)
               lxp1(i) = lxp(m)
               kyp1(i) = kyp(m)
               lyp1(i) = lyp(m)
*               WRITE(*,*) ampp1(i),kxp1(i),lxp1(i),kyp1(i),lyp1(i),i
            end if
            j = j + 1
         END DO
      END DO
      mend1 = i


*************************************************************************
* Reading the sine components of the normal forms' generating function
*************************************************************************

      call READFILE(1004,NP,ampp,kxp,lxp,kyp,lyp,mend)
      msend = mend

      mend = m      
      m = 0
      jend = mend
      j = 0
      i = 0
      
***************************************************
* Taking the double product of the sine amplitudes
***************************************************


      DO WHILE (m.le.mend)
         m = m + 1
         j = m + 1
         DO WHILE (j.le.mend)
            if (dabs(dabs(ampp(m))-dabs(ampp(j))).lt.1.d-14) then
               i = i + 1
               ampp2(i) = 2.d0*ampp(m)
               kxp2(i) = kxp(m)
               lxp2(i) = lxp(m)
               kyp2(i) = kyp(m)
               lyp2(i) = lyp(m)
*               WRITE(*,*) ampp2(i),kxp2(i),lxp2(i),kyp2(i),lyp2(i),i
            end if
            j = j + 1
         END DO
      END DO      
      mend2 = i

      if (mend1.ne.mend2) then
         write(*,*) mend1, mend2
         stop 'tune component vectors have not the same length'
      else
         nnorm = mend
      end if



*********************************
* reading the resonance file    
*********************************

      DO m = 1,Nro
         READ(1005,*) k1,k2
         ix(m) = k1
         iy(m) = k2
*      write (*,*) ix(m),iy(m)
      END DO

*      write (*,*) ix,iy,nnorm

      num = NI
       
      jend = nnorm
      m = 0
      j = 0    

******************************************************
* computation of the total amplitudes up to an order
******************************************************


      DO m = 1,num
         fjklm0 = 0.d0 
         fjklm  = 0.d0  
         fjklmd0 = 0.d0 
         fjklmd  = 0.d0
         DO  j = 1,jend
            if (ix(m).eq.(kxp1(j)-lxp1(j)).and.
     $          iy(m).eq.(kyp1(j)-lyp1(j))) then
                nsum = kxp1(j) + lxp1(j) + kyp1(j) + lyp1(j)
                if (nsum.le.nmax) then
                   jk = kxp1(j) + lxp1(j)
                   lm = kyp1(j) + lyp1(j)
                   fjklm  = ampp1(j)*(sigma**nsum)*(akeyc**jk)
     $                      *(akeys**lm) + fjklm0
                   fjklmd = ampp1(j)*(dsigma**nsum)*(akeyc**jk)
     $                      *(akeys**lm) + fjklmd0
                   fjklm0 = fjklm
                   fjklmd0 = fjklmd
*               write(*,*) fjklm,kxp1(j),lxp1(j),kyp1(j),lyp1(j),ampp1(j)
                end if
            end if
            if (ix(m).eq.(lxp1(j)-kxp1(j)).and.
     $          iy(m).eq.(lyp1(j)-kyp1(j))) then
                nsum = kxp1(j) + lxp1(j) + kyp1(j) + lyp1(j)
                if (nsum.le.nmax) then
                   jk = kxp1(j) + lxp1(j)
                   lm = kyp1(j) + lyp1(j)
                   fjklm = ampp1(j)*(sigma**nsum)*(akeyc**jk)
     $                     *(akeys**lm) + fjklm0
                   fjklmd = ampp1(j)*(dsigma**nsum)*(akeyc**jk)
     $                      *(akeys**lm) + fjklmd0
                   fjklm0 = fjklm
                   fjklmd0 = fjklmd
*               write(*,*) fjklm,kxp1(j),lxp1(j),kyp1(j),lyp1(j),ampp1(j)
                end if
            end if
         END DO
         f_jklm_c(m) = fjklm
         f_jklm_cd(m) = fjklmd
*         write(*,*) f_jklm_c(m),f_jklm_cd(m),ix(m),iy(m)
      END DO


     
      jend = mend2    
      m = 0
      j = 0    

      DO m = 1,num 
         fjklm0 = 0.d0 
         fjklm  = 0.d0  
         fjklmd0 = 0.d0 
         fjklmd  = 0.d0 
         DO j = 1,jend
            if (ix(m).eq.(kxp2(j)-lxp2(j)).and.
     $          iy(m).eq.(kyp2(j)-lyp2(j))) then
                nsum = kxp2(j) + lxp2(j) + kyp2(j) + lyp2(j)
                if (nsum.le.nmax) then
                   sumn2 = nsum
                   jk = kxp2(j) + lxp2(j)
                   lm = kyp2(j) + lyp2(j)
                   fjklm  = ampp2(j)*(sigma**nsum)*(akeyc**jk)
     $                      *(akeys**lm) + fjklm0
                   fjklmd = ampp2(j)*(dsigma**nsum)*(akeyc**jk)
     $                      *(akeys**lm) + fjklmd0
                   fjklm0 = fjklm
                   fjklmd0 = fjklmd
*               write(*,*) fjklm,kxp2(j),lxp2(j),kyp2(j),lyp2(j),ampp2(j)
                end if
            end if
            if (ix(m).eq.(lxp2(j)-kxp2(j)).and.
     $          iy(m).eq.(lyp2(j)-kyp2(j))) then
                nsum = kxp2(j) + lxp2(j) + kyp2(j) + lyp2(j)
                if (nsum.le.nmax) then
                   sumn2 = nsum
                   jk = kxp2(j) + lxp2(j)
                   lm = kyp2(j) + lyp2(j)
                   fjklm = ampp2(j)*(sigma**nsum)*(akeyc**jk)
     $                     *(akeys**lm) + fjklm0
                   fjklmd = ampp2(j)*(dsigma**nsum)*(akeyc**jk)
     $                      *(akeys**lm) + fjklmd0
                   fjklm0  = fjklm
                   fjklmd0 = fjklmd
*               write(*,*) fjklm,kxp2(j),lxp2(j),kyp2(j),lyp2(j),ampp2(j)
                end if
            end if
         END DO
         f_jklm_s(m) = fjklm
         f_jklm_sd(m) = fjklmd
*         write(*,*) f_jklm_s(m),f_jklm_sd(m),ix(m),iy(m)
      END DO



      DO m = 1,num
         f_jklm(m) = dsqrt(f_jklm_c(m)**2.0d0+ f_jklm_s(m)**2.0d0)
         f_jklmd(m) = dsqrt(f_jklm_cd(m)**2.0d0+ f_jklm_sd(m)**2.0d0)
      END DO
      

      write(1006,101) iseed,dynap,(ampth(i), i=1,ndet),
     $               (fjklmthf(i), i=1,nordtune/2),(amptv(i), i=1,ndet),
     $               (fjklmtvf(i), i=1,nordtune/2),(f_jklm(i), i=1,nro)
      write(1007,101)iseed,dynap,(ampth(i), i=1,ndet),
     $              (fjklmthdf(i), i=1,nordtune/2),(amptv(i), i=1,ndet),
     $              (fjklmtvdf(i), i=1,nordtune/2),(f_jklmd(i), i=1,nro)

100   FORMAT(I6,2X,G20.14,I5,4x,18(2i2,1X))
101   FORMAT(i3,2X,G18.8,250(G20.8))
      END




*=============================================
*
* Subroutine READFILE for reading input files
*
*=============================================


      SUBROUTINE READFILE(nf,N,amp,kx,lx,ky,ly,mend)
      IMPLICIT DOUBLE PRECISION (A-H,P-Z), INTEGER (I-O) 
      DIMENSION AMP(N),kx(N),lx(N),ky(N),ly(N)

      amp0=10.0d0
      m = 0

      DO WHILE (amp0.ne.0.d0)
         READ(nf,100) kn,amp0,nord0,kx0,lx0,ky0,ly0,l0
         nsum = kx0+lx0+ky0+ly0
         if (dabs(amp0).gt.1.d-13.and.l0.eq.0.d0.and.nsum.ne.0.d0) then
            m = m + 1
            amp(m) = amp0
            kx(m) = kx0 
            lx(m) = lx0
            ky(m) = ky0 
            ly(m) = ly0
*            WRITE(*,*) amp(m),kx(m),lx(m),ky(m),ly(m),m
         end if
      END DO

      mend = m

100   FORMAT(I6,2X,G20.14,I5,4x,18(2i2,1X))

      END


*========================================
*
* Subroutine STRUCTUNE which structures
* the resonances in the tune function
*
*========================================

      SUBROUTINE  STRUCTUNE(ordmax,N,ix,iy,mend)
      IMPLICIT DOUBLE PRECISION (A-H,P-Z), INTEGER (I-O) 
      DIMENSION ix(N),iy(N)
      
      m = 1
      
      DO WHILE (ord.lt.ordmax)
         ord = ord + 2 
         nord  = 0  
         DO WHILE (nord.le.ord)
            ix(m) = ord - nord
            iy(m) = nord
*           write(*,*) ix(m),iy(m)
            m = m + 1
            nord = nord + 2
         END DO   
      END DO

      mend = m - 1

      END


