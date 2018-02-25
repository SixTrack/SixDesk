      program joinf10
      IMPLICIT none
      integer i,j,k,i1,ii,ich,jj,kk
      double precision a,b,pieni
      character*20 title1,title2
      character*8192 ch
      dimension a(1000,60),b(1000,60)
      open(11,form='formatted',status='unknown')
      pieni=1d-38
      i=1
 1    continue 
      read(22,*,end=2) (a(i,j), j=1,60)
      if(abs(a(i,3)).gt.pieni) i=i+1
      goto 1
 2    k=1
 3    continue 
      read(23,*,end=100) (b(k,j), j=1,60)
      if(abs(b(k,3)).gt.pieni) k=k+1
      goto 3
 100  continue
      i=i-1
      k=k-1
      ii=1
      kk=1
      if(i.eq.0.and.k.eq.0) then 
        goto 999
      else if(i.eq.0.and.k.ne.0) then
        do 4 i1=1,k
          write(ch,*) (b(i1,j), j=1,60)
          do ich=8192,1,-1
            if(ch(ich:ich).ne.' ') goto 700
          enddo
 700      write(11,'(a)') ch(:ich)
 4      continue  
      else if(i.ne.0.and.k.eq.0) then
        do 5 i1=1,i
          write(ch,*) (a(i1,j), j=1,60)
          do ich=8192,1,-1
            if(ch(ich:ich).ne.' ') goto 701
          enddo
 701      write(11,'(a)') ch(:ich)
 5     continue  
      else 
 6      continue  
        if(a(ii,7).le.b(kk,7)) then
          write(ch,*) (a(ii,j), j=1,60)
          do ich=8192,1,-1
            if(ch(ich:ich).ne.' ') goto 702
          enddo
 702      write(11,'(a)') ch(:ich)
          ii=ii+1
        else
          write(ch,*) (b(kk,j), j=1,60)
          do ich=8192,1,-1
            if(ch(ich:ich).ne.' ') goto 703
          enddo
 703      write(11,'(a)') ch(:ich)
          kk=kk+1
        endif
        if(ii.gt.i.and.kk.gt.k) then
          goto 999
        else if(ii.gt.i.and.kk.le.k) then
          do 7 jj=kk,k
            write(ch,*) (b(jj,j), j=1,60)
            do ich=8192,1,-1
              if(ch(ich:ich).ne.' ') goto 704
            enddo
 704        write(11,'(a)') ch(:ich)
 7        continue
          goto 999
        else if(ii.le.i.and.kk.gt.k) then
          do 8 jj=ii,i
            write(ch,*) (a(jj,j), j=1,60)
            do ich=8192,1,-1
              if(ch(ich:ich).ne.' ') goto 705
            enddo
 705        write(11,'(a)') ch(:ich)
 8        continue
          goto 999
        else 
          goto 6
        endif
      endif
 999  continue
      close(11)
      stop
      end
