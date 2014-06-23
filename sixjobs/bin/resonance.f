*=======================================================================
*     Yannis Papaphilippou        :     Oct-1997   
*
*     Program that reads the normal form files fort.20 for different 
*     number of seeds and produces the file file order.dat
* 
*     This program also takes the modified version (order.dat) of the DaLie 
*     output file fort.20 and produces a *.hbook file readable by paw++.
*=======================================================================

 
      PROGRAM  RESONANCE
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER (I-N)
      PARAMETER (NP =1000, N = 500)
      DIMENSION AMP(N),AMPH(N),kx(N),ky(N),lx(N),ly(N)
      DIMENSION AMPP(N),kxp(N),kyp(N),lxp(N),lyp(N)
      DIMENSION AMPP2(N),AMPPN(N),kxp2(N),kyp2(N),lxp2(N),lyp2(N)
      DIMENSION AMPP1(NP),kxp1(NP),kyp1(NP),lxp1(NP),lyp1(NP)
      INTEGER ord

      OPEN (1001,FILE='ordercos.dat',STATUS='OLD',
     $FORM='FORMATTED')

      OPEN (1002,FILE='ordersin.dat',STATUS='OLD',
     $FORM='FORMATTED')

      OPEN (1003,FILE='ampl.dat',STATUS='UNKNOWN',FORM='FORMATTED')
      
      OPEN (1004,FILE='ord.inp',STATUS='OLD',FORM='FORMATTED')
      READ (1004,*) omx,omy,sigma,key,ord,en,e0

      
      pi = 4.0d0*datan(1.0d0)
      amp0 = 10.d0 
      m = 0     

      DO WHILE (amp0.ne.0.d0)
         READ(1001,100) kn,amp0,nord0,kx0,lx0,ky0,ly0,l0
         if (nord0.eq.ord.and.dabs(amp0).gt.1.d-13.and.l0.eq.0.d0) then
            m = m + 1
            ampp1(m) = amp0
            kxp1(m) = kx0 
            lxp1(m) = lx0
            kyp1(m) = ky0
            lyp1(m) = ly0
*            WRITE(*,*) ampp1(m),kxp1(m),lxp1(m),kyp1(m),lyp1(m),m
         end if
      END DO

      mend = m      
      m = 0
      jend = mend
      j = 0
      i = 0


      DO WHILE (m.le.mend)
         m = m + 1
         j = m + 1
         DO WHILE (j.le.mend)
            if (dabs(dabs(ampp1(m))-dabs(ampp1(j))).lt.1.d-14) then
               i = i + 1
               ampp2(i) = ampp1(m)
               kxp2(i) = kxp1(m)
               lxp2(i) = lxp1(m)
               kyp2(i) = kyp1(m)
               lyp2(i) = lyp1(m)
*               WRITE(*,*) ampp2(i),kxp2(i),lxp2(i),kyp2(i),lyp2(i),i
            end if
            j = j + 1
         END DO
      END DO

      
      

     
      jend = i
      j = 0
      
      CALL STRUCT(ord,N,kx,lx,ky,ly,num)
      

      DO WHILE (j.lt.jend)
         i = 0 
         m = 0
         j = j + 1
         DO WHILE (i.eq.0.and.m.le.num)
            m = m + 1
*            write(*,*) kx(m),lx(m),ky(m),ly(m)
            if (kx(m).eq.kxp2(j).and.lx(m).eq.lxp2(j).and.
     $          ky(m).eq.kyp2(j).and.ly(m).eq.lyp2(j)) then
                i = 1
                ampp(m) = ampp2(j)
                kxp(m) = kx(m) 
                lxp(m) = lx(m)
                kyp(m) = ky(m)
                lyp(m) = ly(m)
*                write (*,*) ampp(m),kxp(m),lxp(m),kyp(m),lyp(m),m
                k = k + 1
            end if 
            if (kx(m).eq.lxp2(j).and.lx(m).eq.kxp2(j).and.
     $         ky(m).eq.lyp2(j).and.ly(m).eq.kyp2(j).and.i.eq.0) then
                i = 1
                ampp(m) = ampp2(j)
                kxp(m) = kx(m) 
                lxp(m) = lx(m)
                kyp(m) = ky(m)
                lyp(m) = ly(m)
*                write (*,*) ampp(m),kxp(m),lxp(m),kyp(m),lyp(m),m
                k = k + 1
            end if
         END DO
      END DO



      j = 0
      m = 0
      amp0 = 10.d0



      DO WHILE (amp0.ne.0.d0)
         READ(1002,100) kn,amp0,nord0,kx0,lx0,ky0,ly0,l0
         if (nord0.eq.ord.and.dabs(amp0).gt.1.d-13.and.l0.eq.0.d0) then
            m = m + 1
            ampp1(m) = amp0
            kxp1(m) = kx0 
            lxp1(m) = lx0
            kyp1(m) = ky0
            lyp1(m) = ly0
*            WRITE(*,*) ampp1(m),kxp1(m),lxp1(m),kyp1(m),lyp1(m),m
         end if
      END DO
     
      mend = m 
      m = 0
      jend = mend
      j = 0
      i = 0


      DO WHILE (m.le.mend)
         m = m + 1
         j = m + 1
         DO WHILE (j.le.mend)
            if (dabs(dabs(ampp1(m))-dabs(ampp1(j))).lt.1.d-14) then
               i = i + 1
               ampp2(i) = ampp1(m)
               kxp2(i) = kxp1(m)
               lxp2(i) = lxp1(m)
               kyp2(i) = kyp1(m)
               lyp2(i) = lyp1(m)
*               WRITE(*,*) ampp2(i),kxp2(i),lxp2(i),kyp2(i),lyp2(i),i
            end if
            j = j + 1
         END DO
      END DO


      jend = i
      j = 0

      DO WHILE (j.lt.jend)
         i = 0 
         m = 0
         j = j + 1
         DO WHILE (i.eq.0.and.m.le.num)
            m = m + 1
*            write(*,*) kx(m),lx(m),ky(m),ly(m)
            if (kx(m).eq.kxp2(j).and.lx(m).eq.lxp2(j).and.
     $          ky(m).eq.kyp2(j).and.ly(m).eq.lyp2(j)) then
                i = 1
                amp(m) = 2.0d0*dsqrt(ampp2(j)**2.d0 +  ampp(m)**2.d0)
                amph(m) = dabs(2.0d0*amp(m)*dsin(pi*((kx(m)-lx(m))*omx +
     $                                              (ky(m)-ly(m))*omy)))
                amppn(m) = ampp2(j)
*                write (*,*) amp(m),kx(m),lx(m),ky(m),ly(m),m
            end if 
            if (kx(m).eq.lxp2(j).and.lx(m).eq.kxp2(j).and.
     $         ky(m).eq.lyp2(j).and.ly(m).eq.kyp2(j).and.i.eq.0) then
                i = 1
                amp(m) = 2.0d0*dsqrt(ampp2(j)**2.d0 +  ampp(m)**2.d0)
                amph(m) = dabs(2.0d0*amp(m)*dsin(pi*((kx(m)-lx(m))*omx +
     $                                              (ky(m)-ly(m))*omy)))
                amppn(m) = ampp2(j)
*                write (*,*) amp(m),kx(m),lx(m),ky(m),ly(m),m
            end if
         END DO
      END DO



      DO m = 1,num
         write(1003,101) amp(m),amph(m),2.0d0*ampp(m),2.0d0*amppn(m),
     $                   kx(m),lx(m),ky(m),ly(m),m
         write(*,101) amp(m),amph(m),2.0d0*ampp(m),2.0d0*amppn(m),kx(m),
     $                lx(m),ky(m),ly(m),m
      END DO



100   FORMAT(I6,2X,G20.14,I5,4x,18(2i2,1X))
101   FORMAT(G20.14,2x,G20.14,2x,G16.10,2x,G16.10,4x,2(2i2,2X),I4)
      END



      SUBROUTINE  STRUCT(ord,N,kx,lx,ky,ly,mend)
      IMPLICIT DOUBLE PRECISION (A-H,P-Z), INTEGER (I-O) 
      DIMENSION kx(N),ky(N),lx(N),ly(N)
   
      m = 0
      k = 0
      nord  = 0

      DO WHILE (nord.le.ord)
         k = ord - nord
         nord1 = 0
         DO WHILE (nord1.le.k)
            j0 = nord/2 
            DO j = j0,0,-1
               if (nord1.ne.0.or.k.ne.0) then
                  m = m + 1
                  kx(m) = k - nord1 + j
                  lx(m) = j
                  ky(m) = nord1 + nord/2 - j
                  ly(m) = nord/2 - j
               end if
            END DO
            nord1 = nord1 + 2
         END DO         
         nord1 = 0
         DO WHILE (nord1.lt.k)
            j0 = nord/2 
            DO j = j0,0,-1
                if (nord1.ne.0) then 
                   m = m + 1
                   kx(m) = k - nord1 + j
                   lx(m) = j
                   ky(m) = nord/2 - j
                   ly(m) = nord1 + nord/2 - j
                end if
            END DO
            nord1 = nord1 + 2
         END DO
         nord = nord + 2
      END DO
   
      k = 0
      nord  = 0

      DO WHILE (nord.le.ord)
         k = ord - nord
         nord2 = 1
         DO WHILE (nord2.le.k)
            j0 = nord/2  
            DO j = j0,0,-1
                m = m + 1
                kx(m) = k - nord2 + j
                lx(m) = j
                ky(m) = nord2 + nord/2 - j
                ly(m) = nord/2 - j
            END DO
            nord2 = nord2 + 2
         END DO  
         nord2 = 1
         DO WHILE (nord2.lt.k)
            j0 = nord/2 
            DO j = j0,0,-1
               m = m + 1
               kx(m) = k - nord2 + j
               lx(m) = j
               ky(m) = nord/2 - j
               ly(m) = nord2 + nord/2 - j 
            END DO
            nord2 = nord2 + 2
         END DO
         nord = nord + 2
      END DO
      mend = m

      END

