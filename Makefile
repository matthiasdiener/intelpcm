#
# Copyright (c) 2009-2015 Intel Corporation
# written by Roman Dementiev and Jim Harris
#

EXE = pcm-numa pcm-power pcm pcm-sensor pcm-msr pcm-memory pcm-tsx pcm-pcie pcm-core

all: $(EXE)

klocwork: $(EXE)

CXXFLAGS += -Wall -g -O3 -Wno-unknown-pragmas

# rely on Linux perf support (user needs CAP_SYS_ADMIN privileges), comment out to disable
ifneq ($(wildcard /usr/include/linux/perf_event.h),)
CXXFLAGS += -DPCM_USE_PERF
endif

UNAME:=$(shell uname)

ifeq ($(UNAME), Linux)
LIB= -pthread -lrt
CXXFLAGS += -std=c++0x
endif
ifeq ($(UNAME), Darwin)
LIB= -lpthread /usr/lib/libPcmMsr.dylib 
CXXFLAGS += -I/usr/include -IMacMSRDriver -std=c++0x
endif
ifeq ($(UNAME), FreeBSD)
CXX=c++
LIB= -lpthread -lc++
CXXFLAGS += -std=c++0x
endif

COMMON_OBJS = msr.o cpucounters.o pci.o client_bw.o utils.o
EXE_OBJS = $(addsuffix .o,$(EXE))
OBJS = $(COMMON_OBJS) $(EXE_OBJS)

# ensure 'make' does not delete the intermediate .o files
.PRECIOUS: $(OBJS)

-include $(OBJS:.o=.d)
%: %.o $(COMMON_OBJS)
	$(CXX) -o $@ $^ $(LIB)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $*.cpp -o $*.o
	@# the following lines generate dependency files for the
	@#  target object
	@# from http://scottmcpeak.com/autodepend/autodepend.html
	$(CXX) -MM $(CXXFLAGS) $*.cpp > $*.d
	@# these sed/fmt commands modify the .d file to add a target
	@#  rule for each .h and .cpp file with no dependencies;
	@# this will force 'make' to rebuild any objects that
	@#  depend on a file that has been renamed rather than
	@#  exiting with an error
	@mv -f $*.d $*.d.tmp
	@sed -e 's|.*:|$*.o:|' < $*.d.tmp > $*.d
	@sed -e 's/.*://' -e 's/\\$$//' < $*.d.tmp | fmt -1 | \
	  sed -e 's/^ *//' -e 's/$$/:/' >> $*.d
	@rm -f $*.d.tmp

nice:
	uncrustify --replace -c ~/uncrustify.cfg *.cpp *.h WinMSRDriver/Win7/*.h WinMSRDriver/Win7/*.c WinMSRDriver/WinXP/*.h WinMSRDriver/WinXP/*.c  PCM_Win/*.h PCM_Win/*.cpp  

clean:
	rm -rf *.x *.o *~ *.d $(EXE)

install:
	install $(EXE) /usr/local/bin
	for f in $(EXE); do chmod a+s /usr/local/bin/$$f ; done
