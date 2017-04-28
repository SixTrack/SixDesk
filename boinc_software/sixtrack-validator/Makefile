#!make

PROJ=/data/boinc/software/boinc
SIXT=/data/boinc/project/sixtrack/sixtrack-validator

INCL=-I$(PROJ) -I$(PROJ)/lib -I$(PROJ)/db -I$(PROJ)/sched -I/usr/include/mysql
LIBD=-rdynamic -L/usr/lib64/mysql -lmysqlclient -lcrypt -lnsl -lm -lssl -lcrypto -ldl -lz

CXX=g++  
CXXFLAGS=-g $(INCL)
LD=libtool
LDFLAGS=--tag=CXX --mode=link g++  -g -O2 -static 

OBJD=$(PROJ)/sched
#OBJD=$(SIXT)
LIBS = $(PROJ)/sched/libsched.la $(PROJ)/lib/libboinc_crypt.la $(PROJ)/lib/libboinc.la 

OBJS = sixtrack_bitwise_validator.o 
STDO = $(OBJD)/validator.o $(OBJD)/validate_util.o $(OBJD)/validate_util2.o  \
       $(OBJD)/credit.o
TARGET=sixtrack_validator

#def: $(TARGET)

%.o: %.C
	$(CXX) $(CXXFLAGS) -c $^ -o $@

$(TARGET): $(OBJS) $(STDO)
	$(LD) $(LDFLAGS) $(OBJS) $(STDO) $(LIBS) $(LIBD) -o $(TARGET)

#install: $(TARGET)
#	$(INSTALL) $(TARGET) $(PROJBIN)

clean:
	rm $(TARGET) $(OBJS)

