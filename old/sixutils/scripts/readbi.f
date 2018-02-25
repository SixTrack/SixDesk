      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      CHARACTER*80 SIXTIT,COMMENT
      CHARACTER*8 CDATE,CTIME,PROGRAM
      integer outfile,out2
      DIMENSION QWC(3),CLO(3),CLOP(3),TA(6,6),T(6,6),BET0(2),ALF0(2)
      DIMENSION RDUMMY(4),txyz(6),xyzv(6)

C---------------------------------------------------------------------
      pieni = 1d-38
      zero=0d0
      one=1d0
      do 70 i=1,6
        do 70 j=1,6
          t(i,j)=zero
          ta(i,j)=zero
   70 continue
      PI=ATAN(1D0)*4D0
      zero=dble(0d0)
      print*,'Give input & output file: '
      read(*,*) infile,outfile
c      print*,'Give skip: '
c      read(*,*) iskip
      Write(*,*) 'Transformation from file (NO=0): '
      read(*,*) nfile
      READ(infile) SIXTIT,COMMENT,CDATE,CTIME,
     &PROGRAM,IFIPA,ILAPA,ITOPA,ICODE,NUML,QWC(1),QWC(2),QWC(3),
     &CLO(1),CLOP(1),CLO(2),CLOP(2),CLO(3),CLOP(3),
     &DI0X,DIP0X,DI0Z,DIP0Z,DUMMY,DUMMY,
     &TA(1,1),TA(1,2),TA(1,3),
     &TA(1,4),TA(1,5),TA(1,6),
     &TA(2,1),TA(2,2),TA(2,3),
     &TA(2,4),TA(2,5),TA(2,6),
     &TA(3,1),TA(3,2),TA(3,3),
     &TA(3,4),TA(3,5),TA(3,6),
     &TA(4,1),TA(4,2),TA(4,3),
     &TA(4,4),TA(4,5),TA(4,6),
     &TA(5,1),TA(5,2),TA(5,3),
     &TA(5,4),TA(5,5),TA(5,6),
     &TA(6,1),TA(6,2),TA(6,3),
     &TA(6,4),TA(6,5),TA(6,6),
     &DMMAC,DNMS,DIZU0,DNUMLR,
     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
     &DUMMY,DUMMY,DUMMY,DUMMY
c      print*,TA(1,1),TA(1,2),TA(1,3)
c      print*,TA(1,4),TA(1,5),TA(1,6)
c      print*,TA(2,1),TA(2,2),TA(2,3)
c      print*,TA(2,4),TA(2,5),TA(2,6)
c      print*,TA(3,1),TA(3,2),TA(3,3)
c      print*,TA(3,4),TA(3,5),TA(3,6)
c      print*,TA(4,1),TA(4,2),TA(4,3)
c      print*,TA(4,4),TA(4,5),TA(4,6)
c      print*,TA(5,1),TA(5,2),TA(5,3)
c      print*,TA(5,4),TA(5,5),TA(5,6)
c      print*,TA(6,1),TA(6,2),TA(6,3)
c      print*,TA(6,4),TA(6,5),TA(6,6)
      if(nfile.ne.0) then
      READ(nfile) SIXTIT,COMMENT,CDATE,CTIME,
     &PROGRAM,IFIPA,ILAPA,ITOPA,ICODE,NUML,QWC(1),QWC(2),QWC(3),
     &CLO(1),CLOP(1),CLO(2),CLOP(2),CLO(3),CLOP(3),
     &DI0X,DIP0X,DI0Z,DIP0Z,DUMMY,DUMMY,
     &TA(1,1),TA(1,2),TA(1,3),
     &TA(1,4),TA(1,5),TA(1,6),
     &TA(2,1),TA(2,2),TA(2,3),
     &TA(2,4),TA(2,5),TA(2,6),
     &TA(3,1),TA(3,2),TA(3,3),
     &TA(3,4),TA(3,5),TA(3,6),
     &TA(4,1),TA(4,2),TA(4,3),
     &TA(4,4),TA(4,5),TA(4,6),
     &TA(5,1),TA(5,2),TA(5,3),
     &TA(5,4),TA(5,5),TA(5,6),
     &TA(6,1),TA(6,2),TA(6,3),
     &TA(6,4),TA(6,5),TA(6,6),
     &DMMAC,DNMS,DIZU0,DNUMLR,
     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
     &DUMMY,DUMMY,DUMMY,DUMMY
      endif
!      write(outfile) SIXTIT,COMMENT,CDATE,CTIME,
!     &PROGRAM,IFIPA,ILAPA,ITOPA,ICODE,NUML,QWC(1),QWC(2),QWC(3),
!     &CLO(1),CLOP(1),CLO(2),CLOP(2),CLO(3),CLOP(3),
!     &DI0X,DIP0X,DI0Z,DIP0Z,DUMMY,DUMMY,
!     &TA(1,1),TA(1,2),TA(1,3),
!     &TA(1,4),TA(1,5),TA(1,6),
!     &TA(2,1),TA(2,2),TA(2,3),
!     &TA(2,4),TA(2,5),TA(2,6),
!     &TA(3,1),TA(3,2),TA(3,3),
!     &TA(3,4),TA(3,5),TA(3,6),
!     &TA(4,1),TA(4,2),TA(4,3),
!     &TA(4,4),TA(4,5),TA(4,6),
!     &TA(5,1),TA(5,2),TA(5,3),
!     &TA(5,4),TA(5,5),TA(5,6),
!     &TA(6,1),TA(6,2),TA(6,3),
!     &TA(6,4),TA(6,5),TA(6,6),
!     &DMMAC,DNMS,DIZU0,DNUMLR,
!     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
!     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
!     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
!     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
!     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
!     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
!     &DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,DUMMY,
!     &DUMMY,DUMMY,DUMMY,DUMMY
c      read(7,*) bbx,aax,bby,aay
      do 160 i=1,6
        do 160 j=1,6
  160 t(i,j)=ta(j,i)
      if(abs(t(1,1)).le.pieni.and.abs(t(2,2)).le.pieni) then
        t(1,1)=one
        t(2,2)=one
      endif
      if(abs(t(3,3)).le.pieni.and.abs(t(4,4)).le.pieni) then
        t(3,3)=one
        t(4,4)=one
      endif
      if(abs(t(5,5)).le.pieni.and.abs(t(6,6)).le.pieni) then
        t(5,5)=one
        t(6,6)=one
      endif
c      bet0x1=ta(1,1)*ta(1,1)+ta(1,2)*ta(1,2)
c      bet0x2 =ta(1,3)*ta(1,3)+ta(1,4)*ta(1,4)
c      bet0x3 =ta(1,5)*ta(1,5)+ta(1,6)*ta(1,6)
c      gam0x1 =ta(2,1)*ta(2,1)+ta(2,2)*ta(2,2)
c      gam0x2 =ta(2,3)*ta(2,3)+ta(2,4)*ta(2,4)
c      gam0x3 =ta(2,5)*ta(2,5)+ta(2,6)*ta(2,6)
c      alf0x1=-(ta(1,1)*ta(2,1)+ta(1,2)*ta(2,2))
c      alf0x2 =-(ta(1,3)*ta(2,3)+ta(1,4)*ta(2,4))
c      alf0x3 =-(ta(1,5)*ta(2,5)+ta(1,6)*ta(2,6))
c      print*,bet0x1,bet0x2,bet0x3
c      print*,gam0x1,gam0x2,gam0x3
c      print*,alf0x1,alf0x2,alf0x3
      DO 1 I=1,10000000
      READ(infile,END=2) I1,I2,A,B,C,D,E,F,G,H,
     &I3,A1,B1,C1,D1,E1,F1,G1,H1
       write (outfile,*) ' Turn ',I1,I2
       write (outfile,*) B,C,D,E,F,G
    1 CONTINUE
    2 CONTINUE
      STOP
      END
