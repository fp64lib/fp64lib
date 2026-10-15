#
# Makefile to create libfp64.a on linux system
#
# Requires avr-toolchain
#
#
MCU = atmega328p

RM := rm -rf
XCC     = avr-gcc
OBJDUMP = avr-objdump
OBJCOPY = avr-objcopy
OBJSIZE = avr-size
OBJNM   = avr-nm
AR      = avr-gcc-ar
RANLIB  = avr-gcc-ranlib

FP64_ASM_SRCS := $(wildcard *.S)

FP64FLAGS= -mmcu=$(strip $(MCU)) -mrelax
FP64FLAGS += $(CFLAGS)

FP64_ASM_OBJECTS = $(patsubst %.S, %.o, $(FP64_ASM_SRCS))

OBJS = $(FP64_ASM_OBJECTS)

# All Target
all: libfp64-$(MCU).a

$(FP64_ASM_OBJECTS) : asmdef.h fp64def.h sectionname.h

%.o : %.S
	$(XCC) $< $(FP64FLAGS) -c -o $@

libfp64.a: $(patsubst %, libfp64.a(%), $(FP64_ASM_OBJECTS))
	$(RANLIB) $@

libfp64.a(%.o): %.o
	$(AR) cr $@ $<

libfp64-%.a:
	$(warning $(patsubst libfp64-%.a,%,$@))
	make clean-libfp64 libfp64.a MCU=$(MCU)
	ln libfp64.a $@

# Other Targets
clean: clean-libfp64
	-$(RM) $(wildcard libfp64-*.a)
	-@echo ' '

clean-libfp64:
	-$(RM) $(wildcard $(FP64_ASM_OBJECTS) libfp64.a)

.PHONY: all clean clean-libfp64
