
# A.Mereghetti, 2016-06-22
# trying to have a makefile for the fortran exes

# Lahey fortran95 compiler 
# FC=lf95
# FFLAGS=--o1 --tp -Wa,--32 -o verify1059 -static -m32 -L/usr/lib/ -lc -L/usr/lib/gcc/x86_64-redhat-linux/3.4.6/32 -lgcc_eh

HOST=$(shell hostname)

ifneq (,$(findstring lxplus, ${HOST}))
	FC=f95
	FFLAGS=-Wa,--32 -static -m32 -L/usr/lib/ -lc -L/usr/lib/gcc/x86_64-redhat-linux/3.4.6/32 -lgcc_eh
else
	FC=gfortran
endif

#############  RULES  #############

%.exe: %.f
	${FC} ${FFLAGS} -o $@ $<

############# TARGETS #############

default: all

all: clean verify10.exe
#	@echo $(HOST)

clean:
	rm -f *.o *~ *.exe
