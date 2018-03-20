      program corr9394
c
c
c  program to replace in fort.93 missing entries
c  by those of fort.94 and vice versa. This problem arises when the tunes
c  Qx and Qy are equal, i.e. one the Qx-Qy resonance.
      implicit none 
      integer ifile
      character*100 ch,ch1
      character*2 ch3
      ifile=90
      open(96,form='formatted',status='unknown')
      open(97,form='formatted',status='unknown')
 1    continue
      ch=' '
      ch1=' '
      write(ch3,'(i2)') ifile
      read(93,'(A)',end=100) ch
      read(94,'(A)',end=100) ch1
      if(ch(89:90).eq.ch3.or.
     &  (ch(89:90).ne.ch3.and.ch1(89:90).ne.ch3)) then
        write(96,'(A)') ch
      else 
        write(96,'(A)') ch1
      endif
      if(ch1(89:90).eq.ch3.or.
     &  (ch(89:90).ne.ch3.and.ch1(89:90).ne.ch3)) then
        write(97,'(A)') ch1
      else 
        write(97,'(A)') ch
      endif
      ifile=ifile-1
      goto 1
 100  continue
      stop
      end
