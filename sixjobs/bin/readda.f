c  program to reduce any BERZ map with more than 4 variables 
c  to just the first varables 
      program readdp
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      character*80 ch,ch1
      dimension j(20)
c  initialisation
      iunit=18
      iout=91
      iout2=92
      ch=' '
      idim=4
      icount=0
      ivar=0
c  variable loop
 1    icount=icount+1
c  read header
      read(iunit,*)
      write(iout,'(a80)') ch 
      read(iunit,'(a80)') ch1
      write(iout,'(a32,i1,a47)') ch1(1:32),idim,ch1(34:80)    
      read(iunit,'(a80)') ch1
      write(iout,'(a80)') ch1
      read(iunit,'(a80)') ch1
      write(iout,'(a80)') ch 
      read(iunit,'(a80)') ch1
      write(iout,'(a80)') ch1
 2    ch1=' '
c  read data
      read(iunit,'(a80)') ch1
      if(ch1.eq.ch) then
        write(iout,'(a80)') ch
        if(icount.lt.4) then
          ivar=0
          goto 1
        else 
          goto 999
        endif
      else
c  overcome problem of internal read
        write(iout2,'(a80)') ch1
        rewind iout2
c  find total number of variables
        if(ivar.eq.0.and.icount.eq.1) then
          nvmax=0
          do 3 i=39,84,5
            if(ch1(i:i).eq.' ') then
              if(i.gt.38.and.ch1(i-3:i-3).eq.' ') nvmax=nvmax+1
              goto 100
            else
              nvmax=nvmax+1
              if(ch1(i+2:i+2).eq.' ') then
                goto 100
              else
                nvmax=nvmax+1
              endif
            endif
 3        continue
 100      print*,'NVMAX = ',nvmax
          if(nvmax.lt.5) then
            print*,'Map has less than 5 variables ',
     +      '- program stops'
            stop
          endif
        endif
c  actual read of map coefficients
        read(iout2,'(I6,2X,g20.13,I5,4X,18(2I2,1X))')
     *  Idummy,CC,IOA,(J(III),III=1,20)
        rewind iout2
        read(iunit,*) dd
        do 4 i=5,nvmax
          if(j(i).ne.0) goto 2
 4      continue
        ivar=ivar+1
c  writting of 4d map
         write(Iout,'(I6,2X,G20.14,I5,4X,18(2I2,1X))')
     *      ivar,CC,IOA,(J(III),III=1,4)
        WRITE(Iout,*) dd
        goto 2
      endif
 999  continue
      STOP
      END
