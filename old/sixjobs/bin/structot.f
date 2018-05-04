      PROGRAM STRUCTOT
      IMPLICIT DOUBLE PRECISION (A-H,P-Z), INTEGER (I-O) 
      INTEGER ord
      
      OPEN (1005,FILE='res.dat',STATUS='UNKNOWN',FORM='FORMATTED')

      OPEN (1007,FILE='ord.inp',STATUS='OLD',FORM='FORMATTED')
      READ (1007,*) omx,omy,nsigma,akey,nmax,nordtune,en,e0

      nord  = 0
      
      DO ord = 1, nmax

         DO nord0 = 0,1

            nord = nord0

            DO WHILE (nord.le.ord)
               ix = ord - nord
               iy = nord
*               write(*,*) ix,iy
               write(1005,105) ix,iy
               nord = nord + 2
            END DO

            nord  = nord0

            DO WHILE (nord.le.ord)
               if (nord.ne.0.and. nord-ord.ne.0) then
                  ix = ord - nord
                  iy = -nord
*                 write(*,*) ix,iy
                 write(1005,105) ix,iy
               end if
               nord = nord + 2
            END DO

         END DO

      END DO

105   FORMAT(i3,1X,i3)
      
      END
