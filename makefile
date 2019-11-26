# powturbo  (c) Copyright 2016-2019
# Linux: "export CC=clang" "export CXX=clang". windows mingw: "set CC=gcc" "set CXX=g++" or uncomment the CC,CXX lines
CC ?= gcc
CXX ?= g++

DDEBUG=-DNDEBUG -s
#DDEBUG=-g

#------- OS/ARCH -------------------
ARCH=x86_64
ifneq (,$(filter Windows%,$(OS)))
  OS := Windows
  CC=gcc
  CXX=g++
else
  OS := $(shell uname -s)
  ARCH := $(shell uname -m)
ifneq (,$(findstring aarch64,$(CC)))
  ARCH = aarch64
else ifneq (,$(findstring powerpc64le,$(CC)))
  ARCH = ppc64le
endif
endif

ifeq ($(ARCH),ppc64le)
  CFLAGS=-mcpu=power9 -mtune=power9
else ifeq ($(ARCH),aarch64)
  CFLAGS+=-march=armv8-a
ifneq (,$(findstring clang, $(CC)))
  CFLAGS+=-march=armv8-a -falign-loops -fomit-frame-pointer
else
  CFLAGS+=-march=armv8-a
endif
  MSSE=-march=armv8-a
else
  CFLAGS=-march=native
  MSSE=-mssse3
endif

ifeq ($(OS),$(filter $(OS),Linux GNU/kFreeBSD GNU OpenBSD FreeBSD DragonFly NetBSD MSYS_NT Haiku))
LDFLAGS+=-lrt
endif

all: turbob64

ifneq ($(NSIMD),1)
MSSE+=-DUSE_SSE
ifeq ($(ARCH),x86_64)
MSSE+=-DUSE_AVX -DUSE_AVX2
endif
endif

ifeq ($(FULLCHECK),1)
DEFS+=-DB64CHECK
endif

turbob64c.o: turbob64c.c
	$(CC) -O3 $(MARCH) $(DEFS) -fstrict-aliasing -falign-loops $< -c -o $@ 

turbob64d.o: turbob64d.c
	$(CC) -O3 $(MARCH) $(DEFS) -fstrict-aliasing -falign-loops $< -c -o $@ 

turbob64sse.o: turbob64sse.c
	$(CC) -O3 $(MSSE) $(DEFS) -fstrict-aliasing -falign-loops $< -c -o $@ 

turbob64avx.o: turbob64sse.c
	$(CC) -O3 $(DEFS) -march=corei7-avx -mtune=corei7-avx -mno-aes -fstrict-aliasing -falign-loops $< -c -o turbob64avx.o 

turbob64avx2.o: turbob64avx2.c
	$(CC) -O3 -march=haswell -fstrict-aliasing -falign-loops $< -c -o $@ 

LIB=turbob64c.o turbob64d.o 
ifneq ($(NSIMD),1)
LIB+=turbob64sse.o 
ifeq ($(ARCH),x86_64)
LIB+=turbob64avx.o turbob64avx2.o
endif
endif

turbob64: $(LIB) turbob64.o
	$(CC) $(LIB) turbob64.o $(LDFLAGS) -o turbob64
 
.c.o:
	$(CC) -O3 $(CFLAGS)  $(MARCH) $< -c -o $@

clean:
	@find . -type f -name "*\.o" -delete -or -name "*\~" -delete -or -name "core" -delete -or -name "turbob64"

cleanw:
	del /S *.o