# Makefile

FC = mpif90
ifeq ($(METHOD), dbg)
FFLAGS = -O0 -g -Wall -Wextra -std=f2018 -pedantic -ffpe-trap=invalid,overflow,zero
BOUNDS = -fcheck=all
else 
FFLAGS = -O3
BOUNDS = 
endif
FFLAGS += -cpp
ifeq ($(strip $(USE_NVTX)),1)
FFLAGS += -D_USE_NVTX -L/opt/nvidia/Linux_x86_64/2022/cuda/lib64 -lnvToolsExt
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
