      program readf10
      implicit none
      double precision prob(60)
      integer line,word
      logical diff,diffs
      line=0
    1 read (20,*,end=100,err=98) prob
      line=line+1
      write (*,*) prob
      go to 1
 98   continue
      write (*,*) "READ I/O error!! fort.20 line no ",line
      stop
 100  continue
      end
