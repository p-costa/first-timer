# Makefile

FC = mpif90
ifeq ($(METHOD), dbg)
FFLAGS = -O0 -g -Wall -Wextra -pedantic -ffpe-trap=invalid,overflow,zero -std=f2018
BOUNDS = -fcheck=all
else 
FFLAGS = -O3
BOUNDS = 
endif
FFLAGS += -cpp
ifeq ($(strip $(USE_NVTX)),1)
NVHPC_HOME ?= /opt/nvidia/hpc_sdk/Linux_x86_64/2022
FFLAGS += -D_USE_NVTX -L$(NVHPC_HOME)/cuda/lib64 -lnvToolsExt
endif

EXEC = timeit.exe

default : $(EXEC)

all : default

$(EXEC) : main.o timer.o nvtx.o
	$(FC) $(FFLAGS) $(BOUNDS) $^ -o $@

%.o : %.f90
	$(FC) $(FFLAGS) $(BOUNDS) $< -c

clean :
	$(RM) $(EXEC) *.o *.mod

main.o : timer.o
timer.o : nvtx.o
nvtx.o :
