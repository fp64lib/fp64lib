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

FP64_ASM_PARTS  = fp64_10pown
FP64_ASM_PARTS += fp64_abs fp64_acosh fp64_addsf3x fp64_addsubAB fp64_asinx
FP64_ASM_PARTS += fp64_atan2 fp64_atanh fp64_atanx
FP64_ASM_PARTS += fp64_cbrt fp64_ceil fp64_class fp64_classify fp64_cmp
FP64_ASM_PARTS += fp64_cmpA fp64_cmp_sd2 fp64_cmp_1 fp64_cmpsd2 fp64_copysign 
FP64_ASM_PARTS += fp64_cosh fp64_cotan 
FP64_ASM_PARTS += fp64_debug fp64_disd fp64_divsf3x fp64_ds
FP64_ASM_PARTS += fp64_etoa fp64_exp10 fp64_exp2  fp64_expx
FP64_ASM_PARTS += fp64_fdim fp64_fixxdfsi fp64_floor fp64_fma fp64_fmax
FP64_ASM_PARTS += fp64_fmod fp64_fmodx fp64_frexp fp64_fsplit3 fp64_ftoa1 
FP64_ASM_PARTS += fp64_gesd2 fp64_getexp10
FP64_ASM_PARTS += fp64_hypot 
FP64_ASM_PARTS += fp64_ilogb fp64_inf fp64_inverse fp64_isBzero fp64_isfinite
FP64_ASM_PARTS += fp64_isinf fp64_isnan fp64_isNormal fp64_isSignMinus
FP64_ASM_PARTS += fp64_isZero 
FP64_ASM_PARTS += fp64_ldb_1 fp64_ldb_log2 fp64_ldb_pi2 fp64_ldexp fp64_log10
FP64_ASM_PARTS += fp64_log2 fp64_logx fp64_lrint fp64_lround fp64_lshift64 
FP64_ASM_PARTS += fp64_min fp64_minMag fp64_minNumber fp64_minNumMag
FP64_ASM_PARTS += fp64_modf fp64_movAB fp64_movAC fp64_movBA fp64_movBC 
FP64_ASM_PARTS += fp64_movCA fp64_mul64AB fp64_mulsd3x 
FP64_ASM_PARTS += fp64_nan fp64_negdf2 fp64_norm2 
FP64_ASM_PARTS += fp64_pi2 fp64_pow fp64_powserx fp64_powsoddx fp64_pretA
FP64_ASM_PARTS += fp64_pscA fp64_pscB 
FP64_ASM_PARTS += fp64_round
FP64_ASM_PARTS += fp64_sd fp64_shift fp64_sidf fp64_signbit fp64_sinx fp64_sqrt
FP64_ASM_PARTS += fp64_square fp64_sssd fp64_stackA fp64_stackB fp64_stackC
FP64_ASM_PARTS += fp64_strtod fp64_swapAB 
FP64_ASM_PARTS += fp64_tanh fp64_tanx fp64_tostring fp64_totalOrder fp64_trunc
FP64_ASM_PARTS += fp64_zero

FP64FLAGS= -mmcu=$(strip $(MCU)) -mrelax
FP64FLAGS += $(CFLAGS)

FP64_ASM_OBJECTS = $(patsubst %, %.o, $(FP64_ASM_PARTS))

OBJS = $(FP64_ASM_OBJECTS)

# All Target
all: libfp64-$(MCU).a

$(FP64_ASM_OBJECTS) : asmdef.h fp64def.h

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

