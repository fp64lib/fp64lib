# Makefile to create libfp64-<mcu>.a
# Requires AVR GNU toolchain
#
# In order to build libfp64-<mcu>.a run
#     make MCU=<mcu>
#
# Default values are:
#     MCU    = atmega328p
#     XCC    = avr-gcc
#     CFLAGS =
#
# To make fp64lib available in a C/C++ or assembly program, pass
# the location of this folder with -L <path> and link with
#     avr-gcc ... -lfp64-<mcu>
#
# One way to use the fp64lib functions is by means of
#     #include "fp64lib.h"
# and adding this folder with -I <path> to the include paths.
#
# Notice that the availability of symbols like sin and sinl depends on
# command-line options like -mdouble=64/32 and -mlong-double=64/32.
#
# In order to show the sizes (including all dependencies) of some
# functions, use the size target:
#
# make size SYM='fp64_log fp64_log2' CFLAGS='-mno-relax'

MCU = atmega328p

RM := rm -rf
XCC     = avr-gcc
OBJDUMP = avr-objdump
OBJCOPY = avr-objcopy
OBJSIZE = avr-size
OBJNM   = avr-nm
AR      = avr-gcc-ar
RANLIB  = avr-gcc-ranlib

# Default target
all: libfp64-$(MCU).a

FP64FLAGS= -mrelax -I.
FP64FLAGS += $(CFLAGS)

FP64_ASM_SRCS := $(wildcard *.S)

FP64_ASM_OBJECTS = $(patsubst %.S, %-$(MCU).o, $(FP64_ASM_SRCS))

$(FP64_ASM_OBJECTS) : config.h asmdef.h sectionname.h fp64asm.h fp64def.h
$(FP64_ASM_OBJECTS) : $(MAKEFILE_LIST)

$(FP64_ASM_OBJECTS) : %-$(MCU).o : %.S
	$(XCC) -mmcu=$(MCU) $(FP64FLAGS) -c $< -o $@

libfp64-$(MCU).a: $(FP64_ASM_OBJECTS)
	$(AR) rcs $@ $^

libfp64.a: libfp64-$(MCU).a force
	cp $< $@

wlu = -Wl,-u,
SIZE_UNDEFS = $(patsubst %,$(wlu)%,$(SYM))

size: size-$(MCU).elf
	avr-size $<

size-$(MCU).elf: libfp64-$(MCU).a force
	$(XCC) -mmcu=$(MCU) -o $@ $(FP64FLAGS) -nostartfiles -Wl,--defsym,main=0 $(SIZE_UNDEFS) -L. -lfp64-$(MCU)

clean: clean-libfp64

clean-libfp64:
	-$(RM) $(wildcard libfp64*.a fp64_*.[iso] size*.elf)

.PHONY: all size force clean clean-libfp64
