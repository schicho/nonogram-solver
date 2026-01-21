CFLAGS = -Wall -pedantic -std=c99 -c -O2 -flto=auto
CC = gcc

# Mimalloc support (optional)
# Set USE_MIMALLOC=1 to enable mimalloc allocator
# Example: make USE_MIMALLOC=1
USE_MIMALLOC ?= 0

# Detect mimalloc availability
ifeq ($(USE_MIMALLOC),1)
  MIMALLOC_AVAILABLE := $(shell pkg-config --exists mimalloc && echo 1 || echo 0)
  ifeq ($(MIMALLOC_AVAILABLE),1)
    MIMALLOC_CFLAGS := $(shell pkg-config --cflags mimalloc)
    MIMALLOC_LDFLAGS := $(shell pkg-config --libs mimalloc)
  else
    # Fallback: try to link with -lmimalloc directly
    MIMALLOC_LDFLAGS := -lmimalloc
    $(info Warning: pkg-config for mimalloc not found, trying direct linking)
  endif
  # Use -Wl,--no-as-needed to ensure mimalloc is actually linked
  LDFLAGS += -Wl,--no-as-needed $(MIMALLOC_LDFLAGS) -Wl,--as-needed
  $(info Building with mimalloc allocator)
else
  $(info Building with system allocator)
endif

solver: stacks.o solver.o solverio.o stocks.o presolver.o
	$(CC) -o nonograms solver.o stacks.o solverio.o stocks.o presolver.o $(LDFLAGS)

solver.o: solver.c solver.h stacks.h
	$(CC) $(CFLAGS) solver.c

presolver.o: presolver.c solver.h
	$(CC) $(CFLAGS) presolver.c

solverio.o: solverio.c solver.h stacks.h
	$(CC) $(CFLAGS) solverio.c

stacks.o: stacks.c stacks.h
	$(CC) $(CFLAGS) stacks.c
	
stocks.o: stocks.c solver.h
	$(CC) $(CFLAGS) stocks.c

PROFILE_CFLAGS = -Wall -pedantic -std=c99 -c -O2 -pg
PROFILE_LDFLAGS = -pg $(LDFLAGS)
OBJS = solver.o stacks.o solverio.o stocks.o presolver.o
PROF_OBJS = $(patsubst %.o,%.p.o,$(OBJS))

profile: nonograms-pg

nonograms-pg: $(PROF_OBJS)
	$(CC) $(PROFILE_LDFLAGS) -o nonograms-pg $(PROF_OBJS)

%.p.o: %.c
	$(CC) $(PROFILE_CFLAGS) -o $@ $<

clean-profile:
	rm -f *.p.o nonograms-pg gmon.out

clean:
	rm -f *.o *~

clean-solutions:
	rm puzzles/*.sol

.PHONY: clean clean-profile clean-solutions benchmark profile help

help:
	@echo "Nonogram Solver - Build Targets"
	@echo "================================"
	@echo ""
	@echo "Main targets:"
	@echo "  make              - Build the program with system allocator"
	@echo "  make USE_MIMALLOC=1 - Build with mimalloc allocator (if available)"
	@echo "  make benchmark    - Run benchmark test"
	@echo "  make profile      - Build profiling version"
	@echo "  make clean        - Remove build artifacts"
	@echo ""
	@echo "Mimalloc support:"
	@echo "  Set USE_MIMALLOC=1 to enable mimalloc allocator"
	@echo "  Example: make USE_MIMALLOC=1 benchmark"
	@echo ""

benchmark:
	./nonograms puzzles/p6.cfg > temp.sol || { echo "ERROR: nonograms execution failed" >&2; rm -f temp.sol; exit 1; }
	diff -q puzzles/p6.sol temp.sol >/dev/null || { echo "ERROR: output differs from puzzles/p6.sol" >&2; rm -f temp.sol; exit 1; }
	/usr/bin/time ./nonograms puzzles/p6.cfg -b > /dev/null
