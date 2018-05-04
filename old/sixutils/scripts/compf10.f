      program compf10
      implicit none
      double precision prob(60),prob1(60),eps(60)
      integer line,word
      logical diff,diffs
! Now compare the closed orbit in 53-58 as well
      line=0
      diff=.false.
      diffs=.false.
    1 read (20,*,end=100,err=98) prob
      line=line+1
      read (21,*,end=99,err=97) prob1
      if (diffs) diff=.true.
      diffs=.false.
      do word=1,51
        eps(word)=abs(prob(word))-abs(prob1(word))
        if (eps(word).ne.0d0) then
          if (.not.diffs) then
            write (*,*) "DIFF fort.10, line",line
            diffs=.true.
          endif
          write (*,*) "DIFF",word,eps(word),prob(word),prob1(word)
          if (abs(eps(word)).ge.1d-14) then
            write (*,*) 'HUGE!',abs(eps(word))
          endif
        else
          write (*,*) "SAME",word,prob(word)
        endif
      enddo 
      do word=53,58
        eps(word)=abs(prob(word))-abs(prob1(word))
        if (eps(word).ne.0d0) then
          if (.not.diffs) then
            write (*,*) "DIFF fort.10, line",line
            diffs=.true.
          endif
          write (*,*) "DIFF",word,eps(word),prob(word),prob1(word)
          if (abs(eps(word)).ge.1d-14) then
            write (*,*) 'HUGE!',abs(eps(word))
          endif
        else
          write (*,*) "SAME",word,prob(word)
        endif
      enddo 
      go to 1
 99   continue
      write (*,*) "Comparing VERSION ",prob(52)," to ",prob1(52)
      write (*,*) "DIFF I/O error, wrong no of lines!! line no ",line
      stop
 98   continue
      write (*,*) "Comparing VERSION ",prob(52)," to ",prob1(52)
      write (*,*) "DIFF I/O error!! fort.20 line no ",line
      stop
 97   continue
      write (*,*) "Comparing VERSION ",prob(52)," to ",prob1(52)
      write (*,*) "DIFF I/O error!! fort.21 line no ",line
      stop
 100  continue
      if (line.eq.0) go to 99
      write (*,*) "Comparing VERSION ",prob(52)," to ",prob1(52)
      end
