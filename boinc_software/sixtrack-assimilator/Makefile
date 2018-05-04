#!make

PROJ=/share/boinc/software/boinc/boinc
SIXT=/usr/local/boinc/project/sixtrack/sixtrack-assimilator

INCL=-I$(PROJ) -I$(PROJ)/lib -I$(PROJ)/db -I$(PROJ)/sched -I/usr/include/mysql
LIBD=-rdynamic -L/usr/lib64/mysql -lmysqlclient -lcrypt -lnsl -lm -lssl -lcrypto -ldl -lz

CXX=g++  
CXXFLAGS=-g $(INCL)
LD=libtool
LDFLAGS=--tag=CXX --mode=link g++  -g -O2 -static 

OBJD=$(PROJ)/sched
LIBS = $(PROJ)/sched/libsched.la $(PROJ)/lib/libboinc_crypt.la $(PROJ)/lib/libboinc.la 

OBJS = sixtrack_assimilator.o 
STDO = $(OBJD)/assimilator.o $(OBJD)/validate_util.o
TARGET=sixtrack_assimilator

#def: $(TARGET)

%.o: %.C
	$(CXX) $(CXXFLAGS) -c $^ -o $@

$(TARGET): $(OBJS) $(STDO)
	$(LD) $(LDFLAGS) $(OBJS) $(STDO) $(LIBS) $(LIBD) -o $(TARGET)

#install: $(TARGET)
#	$(INSTALL) $(TARGET) $(PROJBIN)

clean:
	rm $(TARGET) $(OBJS)

