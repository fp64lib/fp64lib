/*
 * fp64lib - testbed for 64 bit floating point library for arduino
 * *
 * Copyright (c) 2018-2020 by Uwe Bissinger
 *                                                                                                           //
 * Compiler: avr-gcc                                                                                          *
 *                                                                                                            *
 * Copyright:                                                                                                 *
 *      You may use this program free of charge for any purpose you wish provided you agree to the following  *
 *      License:                                                                                              *
 *      Warranty of Provenance and Disclaimer of Warranty. Licensor warrants that the copyright               *
 *      in and to the Original Work and the patent rights granted herein by Licensor are owned by the         *
 *      Licensor or are sublicensed to You under the terms of this License with the permission of the         *
 *      contributor(s) of those copyrights and patent rights. Except as expressly stated in the immediately   *
 *      preceding sentence, the Original Work is provided under this License on an "AS IS" BASIS and WITHOUT  *
 *      WARRANTY, either express or implied, including, without limitation, the warranties of                 *
 *      non-infringement, merchantability or fitness for a particular purpose. THE ENTIRE RISK AS TO THE      *
 *      QUALITY OF THE ORIGINAL WORK IS WITH YOU. This DISCLAIMER OF WARRANTY constitutes an essential part   *
 *      of this License. No license to the Original Work is granted by this License except under this         *
 *      disclaimer.                                                                                           *
 *                                                                                                            *
 *      Limitation of Liability. Under no circumstances and under no legal theory, whether in tort            *
 *      (including negligence), contract, or otherwise, shall the Licensor be liable to anyone for any        *
 *      indirect, special, incidental, or consequential damages of any character arising as a result of       *
 *      this License or the use of the Original Work including, without limitation, damages for loss of       *
 *      goodwill, work stoppage, computer failure or malfunction, or any and all other commercial damages     *
 *      or losses. This limitation of liability shall not apply to the extent applicable law prohibits such   *
 *      limitation.                                                                                           *
 *                                                                                                            *
 */

#define DEBUG
//#define DEBUG_LEVEL 1 
#define DEBUG_LEVEL 2
#define DEBUG_DUMP
// #define FAST				/* uncomment FAST to skip a lot of debugging output */

#ifdef ARDUINO_AVR_MEGA2560
#define MAX_TIMINGS		200
#else
#define MAX_TIMINGS		21
#endif

// the sequence of the #defines also defines the testing hierarchy:
// a codeblock may use all the functions tested in the codeblocks 
// above it, e.g. CHECK_ADD may use (and rely on) functions that 
// were already tested in CHECK_FN, CHECK_ISXXX and CHECK_DUMP
// Due to the codesize limitations of the AVR processor, not all 
// tests can be included in one test run. So selected parts have
// to be included, so uncomment the parts you want to test.
// #define CHECK_DUMP
// #define CHECK_ISXXX
// #define CHECK_FN
// #define CHECK_ADD
// #define CHECK_SUB
// #define CHECK_MULT
// #define CHECK_DIV
// #define CHECK_FMOD
// #define CHECK_CMP
// #define CHECK_CONV
// #define CHECK_TRIG
// #define CHECK_POWSER
// #define CHECK_LOG
// #define CHECK_EXP
// #define CHECK_10POWN
// #define CHECK_FTOA
// #define CHECK_ATOF
// #define CHECK_TOSTRING
// #define CHECK_TOINT
// #define CHECK_TOFLOATfp
// #define CHECK_LDEXP
// #define CHECK_FDIM
// #define CHECK_POW
// #define CHECK_HYPOT
// #define CHECK_FREXP
// #define CHECK_FMA
// #define CHECK_TRIGH
#define CHECK_ATAN2
// #define CHECK_PROXY

// as timing may take quiet some time, it can be switched on/off
// separately. If WITH_TIMING is #defined, then timing will be 
// included for all the CHECK_xxx parts selected above.
#define WITH_TIMING

int led = 13;

#include <avr/pgmspace.h>
#include "fp64lib.h"
#include "fp64debug.h"
#include "avr_f64.h"

// Some test numbers
#define f_NUMBER_NAN		float64_ONE_POSSIBLE_NAN_REPRESENTATION
#define f_NUMBER_2 			((float64_t)0x4000000000000000LLU) // 2.0
#define f_NUMBER_2_5		((float64_t)0x4004000000000000LLU) // 2.5
#define f_NUMBER_16			((float64_t)0x4030000000000000LLU) // 16.0
#define f_NUMBER_256		((float64_t)0x4070000000000000LLU) // 256.0
#define f_NUMBER_6 			((float64_t)0x4018000000000000LLU) // 6.0
#define f_NUMBER_10			((float64_t)0x4024000000000000LLU) // 10.0
#define f_MINUS_NUMBER_2 	((float64_t)0xC000000000000000LLU) // -2.0
#define f_MINUS_NUMBER_2_5 	((float64_t)0xC000400000000000LLU) // -2.5
#define f_NUMBER_0_5		((float64_t)0x3fe0000000000000LLU) // 0.5
#define f_NUMBER_0_25		((float64_t)0x3fd0000000000000LLU) // 0.25
#define f_NUMBER_0_125		((float64_t)0x3fc0000000000000LLU) // 0.125
#define f_NUMBER_LOG10  	((float64_t)0x40026bb1bbb55516LLU) // log(10.0) = 2.3025850929940459
#define f_NUMBER_180PI  	((float64_t)0x404ca5dc1a63c1f8LLU) // 180/PI    = 57.295779513082323
#define f_NUMBER_200PI  	((float64_t)0x404fd4bbab8b494cLLU) // 200/PI    = 63.661977236758133
#define f_NUMBER_01    		((float64_t)0x3FB999999999999ALLU) // 0.1
#define f_NUMBER_001    	((float64_t)0x3f847ae147ae147bLLU) // 0.01
#define f_NUMBER_100    	((float64_t)0x4059000000000000LLU) //100
#define f_NUMBER_60     	((float64_t)0x404e000000000000LLU) //60
#define f_NUMBER_6E_3   	((float64_t)0x3f789374bc6a7efaLLU) // 60 / 100 / 100 = 6E-3
#define f_NUMBER_27E_3  	((float64_t)0x3f9c71c71c71c71dLLU) // 100 / 60 / 60  = 0.02777777777777778
#define float64_NUMBER_PIO4	((float64_t)0x3fe921fb54442d18LLU)  // 3.1415926535897932/4
#define float64_MINUS_NUMBER_PIO2	((float64_t)0xbff921fb54442d18LLU)  // -3.1415926535897932/2
#define float64_MINUS_NUMBER_PIO4	((float64_t)0xbfe921fb54442d18LLU)  // -3.1415926535897932/4
//               A65544332 21100 
// digits of PI-3 243F6A88 85A30 8D3 13198A2E 03707 344 A4093822 299F31D0 082EFA98 EC4E6C89
// 	IEEE 753 0x400921FB544 42D18 469 898CC517 01B839A2 52049C11
//                          0x3ca1A6 2633145C 06E0E
//                               655 44332211 00 
			   
#define f_NUMBER_PIx		((float64_t)0x3ca1A62633145C07LLU)

#define d(x)		x,#x
#define ddump(x)	dump(d(x))
#define dddump(x)	ddump(x);__fp64_splitA(x);dump_debug( __fp64_debugA() );

typedef int (*i1ptr)(float64_t);
typedef long (*l1ptr)(float64_t);
typedef int8_t (*i2ptr)(float64_t, float64_t);
typedef float64_t (*f1ptr)(float64_t);
typedef float64_t (*f2ptr)(float64_t,float64_t);
typedef float64_t (*f1lptr)(long);
typedef char* (*f_to_string_ptr) (float64_t, uint8_t, uint8_t );


#ifdef MSC_VER
// Visual Studio needs function prototype, Arduino IDE does create these automatically
bool check_diff(float64_t res, float64_t exp_res);
void dump( float64_t r, const char *s );
void dump_debug( fp64_debug_t *xd );
void check_intop1( float64_t x, i1ptr f, const char *s, int exp_res, bool doPrint );
void check_longop1( float64_t x, l1ptr f, const char *s, long exp_res );
void check_intop2( float64_t x, float64_t y, i2ptr f, const char *s, int exp_res, bool doPrint );
void check_fop1( float64_t x, f1ptr f, const char *s, float64_t exp_res );
float64_t check_fop2( float64_t a, float64_t b, f2ptr f, const char *s, float64_t exp_res );
void dump_op2( int i, float64_t a, float64_t b, f2ptr f_new, f2ptr f_old, const char *s, int iFlags );
void timeItCommon( float64_t res, const char *s, bool time1, unsigned long time );
void timeItR( float64_t a, float64_t b, f2ptr f, const char *s, bool time1 );
void timeIt( float64_t a, float64_t b, f2ptr f, const char *s, bool time1 );
void timeIt1( float64_t a, f1ptr f, const char *s, bool time1 );
void dump_add( int i, float64_t a, float64_t b );
void dump_sub( int i, float64_t a, float64_t b );
void dump_mult( int i, float64_t a, float64_t b );
void dump_div( int i, float64_t a, float64_t b );
float64_t my_fsin(float64_t x);

float64_t f_gamma(float64_t zpar);
float64_t fp64_gamma(float64_t zpar);
#endif

#define F_NAN		0x80
#define F_MINFIN	0x40
#define F_PINFIN	0x20
#define	F_FINITE	0x10


const struct check_table1_t {
	float64_t x;
	int8_t	isNaN;
	int8_t isInf;
	int8_t isfinite;
}  check_table1[] PROGMEM = {
	{ float64_NUMBER_PLUS_ZERO, 0, 0, 1 },	//0 +0
	{ 0x8000000000000000LLU,    0, 0, 1 },	//1 -0
	{ float64_NUMBER_ONE ,		0, 0, 1 },	//2 +1
	{ float64_MINUS_NUMBER_ONE,	0, 0, 1 },	//3 -1
	{ f_NUMBER_NAN,				1, 0, 0 },	//4 NaN
	{ float64_PLUS_INFINITY,	0, 1, 0 },	//5 +Inf
	{ float64_MINUS_INFINITY,	0,-1, 0 },	//6 -Inf
	{ 0x3fffffffffffffffLLU, 	0, 0, 1 },	//7
	{ f_EULER_E, 				0, 0, 1 },	//8
	{ f_NUMBER_PI, 				0, 0, 1 },	//9
	{ 0x0010000000000000LLU,	0, 0, 1 },	//10 smallest normal number 1*2^-1022 = 2.22e-308
	{ 0x0018000000000000LLU,	0, 0, 1 },	//11: subnormal number 2^-1023 
	{ 0x0008000000000000LLU,	0, 0, 1 },	//12 subnormal number
	{ 0x0004000000000000LLU,	0, 0, 1 },	//13 subnormal number
	{ 0x0000000000000001LLU,	0, 0, 1 }	//14 smallest subnormal number
};
int check_table1_size = sizeof(check_table1) / sizeof( struct check_table1_t );
struct check_table1_t _ct1;
struct check_table1_t *get_check_table1(int i) {
	memcpy_P( &_ct1, &check_table1[i], sizeof(_ct1) );
	return &_ct1;
}

#define FLAGS_MULT	-1
#define FLAGS_ADD	0
#define FLAGS_SUB	1
#define FLAGS_DIV	2
#define FLAGS_FMOD	3
#define FLAGS_FMAX	4
#define FLAGS_FMIN	5
#define FLAGS_FDIM	6
#define FLAGS_POW	7
#define FLAGS_HYPOT	8
#define FLAGS_MAX	8

// TODO: Add test cases for x^integer
const struct check_mult_table_t {
	float64_t a;
	float64_t b;
	int8_t	isNaN;
	int8_t isInf;
	int8_t isfinite;
	uint8_t flags[FLAGS_MAX+1];
}  check_mult_table[] PROGMEM = {
	//     A						BASIS					A*B		 A+B	   A-B       A/B       fmod(A,B) fmax(A,B) fmin(A,B) fdim(A,B) pow(A,B)  hypot(A,B)        
	{ f_NUMBER_NAN,				f_NUMBER_NAN,				1, 0, 0, F_NAN   , F_NAN   , F_NAN   , F_NAN   , F_NAN   , F_NAN   , F_NAN   , F_NAN   , F_NAN      },	// 0: NaN op NaN = NaN
	{ f_NUMBER_NAN,				float64_NUMBER_ONE, 	 	1, 0, 0, F_NAN   , F_NAN   , F_NAN   , F_NAN   , F_FINITE, F_FINITE, F_NAN   , F_NAN   , F_NAN      },	// 1: NaN op 1 = NaN
	{ f_NUMBER_NAN,				float64_NUMBER_PLUS_ZERO,	1, 0, 0, F_NAN   , F_NAN   , F_NAN   , F_NAN   , F_FINITE, F_FINITE, F_NAN   , F_FINITE, F_NAN      },	// 2: NaN op 0 = NaN
	{ float64_PLUS_INFINITY,	float64_NUMBER_ONE, 		0, 1, 0, F_PINFIN, F_PINFIN, F_PINFIN, F_NAN   , F_PINFIN, F_FINITE, F_PINFIN, F_PINFIN, F_PINFIN   },	// 3: +Inf op 1 = -Inf
	{ float64_PLUS_INFINITY,	float64_NUMBER_PLUS_ZERO, 	1, 0, 0, F_PINFIN, F_PINFIN, F_NAN   , F_NAN   , F_PINFIN, F_FINITE, F_PINFIN, F_FINITE, F_PINFIN   },	// 4: +Inf*0 = Nan, +Inf+0 = +Inf, +Inf / 0 = NaN
	{ float64_MINUS_INFINITY,	float64_NUMBER_ONE, 		0,-1, 0, F_MINFIN, F_MINFIN, F_MINFIN, F_NAN   , F_FINITE, F_MINFIN, F_FINITE, F_MINFIN, F_PINFIN   },	// 5: -Inf op 1 = -Inf
	{ float64_MINUS_INFINITY,	float64_NUMBER_PLUS_ZERO, 	1, 0, 0, F_MINFIN, F_MINFIN, F_NAN   , F_NAN   , F_FINITE, F_MINFIN, F_FINITE, F_FINITE, F_PINFIN   },	// 6: -Inf*0 = Nan, -Inf+0 = -Inf, -Inf / 0 = NaN
	{ float64_NUMBER_PLUS_ZERO,	float64_NUMBER_PLUS_ZERO,	0, 0, 1, F_FINITE, F_FINITE, F_NAN   , F_NAN   , F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 7: 0*0=0, 0+0=0, 0/0 = NaN
	{ float64_NUMBER_PLUS_ZERO,	float64_NUMBER_ONE,			0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 8: 0*1=0, 0+1=1
	{ 0x3fffffffffffffffLLU,	0x3fffffffffffffffLLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   }, // 9: rounding, 1,99 op 1,99 = 3,99
	{ float64_NUMBER_ONE,		float64_NUMBER_ONE,			0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ float64_NUMBER_ONE,		float64_MINUS_NUMBER_ONE,	0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ float64_NUMBER_ONE,		f_EULER_E,					0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ float64_NUMBER_ONE,		f_NUMBER_PI,				0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ f_NUMBER_0_5,				f_NUMBER_0_5, 				0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ f_NUMBER_2,				f_NUMBER_2, 				0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ f_EULER_E,				f_NUMBER_PI,				0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ 0x7fefffffffffffffLLU,	0x3ff8000000000000LLU,		0, 1, 0, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_PINFIN, F_PINFIN   }, // 17: overflow for *
	{ 0xffefffffffffffffLLU,	0x3ff8000000000000LLU,		0, -1,0, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_NAN   , F_PINFIN   },	// 18: -overflow for *
	{ 0x0010000000000000LLU,	f_NUMBER_0_5,				0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 19: underflow
	{ 0x0010000000000000LLU,	f_NUMBER_0_25,				0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 20: underflow
	{ 0x0018000000000000LLU,	f_NUMBER_0_5,				0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 21: underflow
	{ 0x0018000000000000LLU,	f_NUMBER_0_25,				0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 22: underflow
	{ 0x0000000000000002LLU,	f_NUMBER_0_5,				0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 23: underflow becoming smallest subnormal number
	{ 0x0000000000000001LLU,	f_NUMBER_0_5,				0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 24: underflow becoming 0
	{ 0x0000000000000001LLU,	0x0000000000000001LLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 25: worst case underflow 
	{ 0x4340000000000000LLU,	float64_NUMBER_ONE,			0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 26: checking maximum precision for add
	{ 0x4340000000000000LLU,	f_NUMBER_2,					0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 27: checking maximum precision for add
	{ 0x433fffffffffffffLLU,	float64_NUMBER_ONE,			0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 28: checking maximum precision for add
	{ float64_NUMBER_ONE,		f_NUMBER_2,					0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ float64_NUMBER_ONE,		f_MINUS_NUMBER_2,			0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ float64_MINUS_NUMBER_ONE,	f_NUMBER_2,					0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 31: -1^2 = 1
	{ float64_MINUS_NUMBER_ONE,	f_MINUS_NUMBER_2,			0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_NAN   , F_FINITE   },
	{ 0x3ff6772B34400000LLU,	0x3ffa592148cfb84dLLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ 0x3ff6D17435C00000LLU,	0x3ffa592148cfb84dLLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ 0x3ff727BC55E00000LLU,	0x3ffa592148cfb84dLLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ f_NUMBER_PI,				float64_NUMBER_PIO2,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ f_NUMBER_PI,				float64_NUMBER_PIO4,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ f_NUMBER_PI,				float64_MINUS_NUMBER_PIO2,	0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ f_NUMBER_PI,				float64_MINUS_NUMBER_PIO4,	0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ float64_NUMBER_2PI,		float64_NUMBER_PIO2,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ float64_NUMBER_2PI,		float64_MINUS_NUMBER_PIO2,	0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },
	{ 0x3557F1FB6F109359LLU,	0x4202A05F20000000LLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 42: 10^-51 / 10^10
	{ 0x0010000000000000LLU,	0x000FFFFFFFFFFFFFLLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 43: smallest number and biggest subnormal number
	{ 0x0010000000000000LLU,	0x0000000000000001LLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 44: smallest number and smallest subnormal number
	{ 0x000FFFFFFFFFFFFFLLU,	0x0000000000000001LLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 45: smallest subnormal number and smallest subnormal number
	{ 0x0008000000000000LLU,	f_NUMBER_0_5,				0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 46: underflow
	{ 0x0004000000000000LLU,	f_NUMBER_0_5,				0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 47 underflow
	{ 0x3fffffffffffffffLLU,	f_NUMBER_2,					0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },  // 48 rounding, 1,99 op 2 = 3,99
	{ float64_PLUS_INFINITY,	float64_MINUS_INFINITY, 	0, -1, 0,F_NAN,    F_PINFIN, F_NAN,    F_NAN   , F_PINFIN, F_MINFIN, F_PINFIN, F_FINITE, F_PINFIN   },	// 49: +Inf op 1 = -Inf
	{ float64_NUMBER_ONE,		float64_NUMBER_PLUS_ZERO,	0, 0, 1, F_FINITE, F_FINITE, F_PINFIN, F_NAN   , F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 50: 0*1=0, 0+1=1
	{ 0x4076300000000000LLU,	float64_NUMBER_PIO2,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 51: edge case for fmod regarding precision
	{ 0xc000000000000000LLU,    0x4008000000000000LLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 52: -2^3 = -8
	{ 0xc000000000000000LLU,    0x4008000000000001LLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_NAN,    F_FINITE   },	// 53: -2^(3+2^-51) = -8
	{ 0xc000000000000000LLU,    0x4000000000000000LLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 54: -2^2= -4
	{ 0xbff0000000000010LLU,    0x4340000000000000LLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_NAN,	 F_FINITE   },	// 55: -2^9007199254740992/3 = NaN
	{ 0xbff0000000000010LLU,    0x433fffffffffffffLLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 56: -2^9007199254740991(last number with full 53 bit precision, should return negative result)
	{ 0xbff0000000000010LLU,    0x433ffffffffffffeLLU,		0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   },	// 57: -2^9007199254740990 (should return positive result)
	{ f_EULER_E,				f_NUMBER_2,					0, 0, 1, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE, F_FINITE   }
	};
int check_mult_table_size = sizeof(check_mult_table) / sizeof( struct check_mult_table_t );

int testPassed = 0;
int testFailed = 0;
int testPrec[8];
int testSign = 0;


struct check_mult_table_t _p1;
struct check_mult_table_t *get_mult_table(int i) {
	memcpy_P( &_p1, &check_mult_table[i], sizeof(_p1) );
	return &_p1;
}

#if defined(CHECK_CONV) || defined(CHECK_TOFLOAT)
const float check_vals[] PROGMEM = {
	3.14f, -1.0f, 1.0f, 1e10f, 1e-10f, 
	1e37f, 1e-37f, 
	1e38f, 
	1e39f, 	// overflow, will be replaced with +INF by compiler
	-1e39f, // overflow, will be replaced with -INF by compiler
	1e-38f, 
	1e-39f, 
	1e-44f, // subnormal number
	1e-45f, // subnormal number
	1e-46f, // absolute underflow, will be replaced with 0 by compiler
	((float) 0x7fffffff)
};
int size_vals = sizeof(check_vals) / sizeof(float);
float _val1;
float get_check_vals(int i) {
	memcpy_P( &_val1, &check_vals[i], sizeof(_val1) );
	return _val1;
}
#endif

#if defined(CHECK_TRIG) || defined(CHECK_LOG) || defined(CHECK_EXP) || defined(CHECK_FN)
float64_t my_fmod( float64_t x, float64_t y );
const float64_t check_trig_vals[] PROGMEM = {
	f_NUMBER_NAN,				
    float64_PLUS_INFINITY,	
    float64_MINUS_INFINITY,	
    float64_NUMBER_PLUS_ZERO,	
    float64_NUMBER_ONE,		
    float64_MINUS_NUMBER_ONE,		
	f_NUMBER_PI,
	float64_NUMBER_2PI,
	float64_NUMBER_PIO2,
	float64_NUMBER_PIO4,
	float64_MINUS_NUMBER_PIO2,
	float64_MINUS_NUMBER_PIO4,
    f_NUMBER_0_5,	
	f_NUMBER_2,
	f_MINUS_NUMBER_2,
    f_EULER_E,				
    0x7fefffffffffffffLLU,	
    0xffefffffffffffffLLU,	
    0x0010000000000000LLU,	
    0x0010000000000000LLU,	
    0x0018000000000000LLU,	
    0x0018000000000000LLU,	
    0x0000000000000002LLU,	
    0x0000000000000001LLU,	
    0x0000000000000001LLU,	
    0x4340000000000000LLU,	
    0x433fffffffffffffLLU,	
    0x3ff6772B34400000LLU,	
    0x3ff6D17435C00000LLU,	
    0x3ff727BC55E00000LLU,
	0x4036000000000000LLU, //22
	0x4076300000000000LLU, //355
	0x3ff921fb54200000LLU  //1.5707963262684643268585205078125 
};
int size_trig_vals = sizeof(check_trig_vals) / sizeof(float64_t);
float64_t _val2;
float64_t get_check_trig_vals(int i) {
	memcpy_P( &_val2, &check_trig_vals[i], sizeof(_val2) );
	return _val2;
}
#endif

#if defined(CHECK_TOFLOAT) || defined(CHECK_FTOA) || defined(CHECK_ATOF) || defined(CHECK_TOSTRING) || defined(CHECK_TOINT)
const struct ftoa_table1_t {
	float64_t x;
	int8_t 	isSubnormal;
}  ftoa_table1[] PROGMEM = {
	{ f_NUMBER_NAN				, false	},	// 0
	{ float64_PLUS_INFINITY	 	, false	},	// 1
	{ float64_MINUS_INFINITY	, false	},	// 2
	{ float64_NUMBER_PLUS_ZERO  , false	},	// 3
	{ f_NUMBER_2 				, false	}, 	// 4
	{ f_NUMBER_0_5 				, false	},	// 5
	{ f_NUMBER_0_25 			, false	}, 	// 6 
	{ f_NUMBER_0_125 			, false	},	// 7
	{ float64_NUMBER_ONE 		, false	},	// 8
	{ float64_MINUS_NUMBER_ONE	, false	},	// 9
	{ 0x3fffffffffffffffLLU 	, false	},	//10
	{ f_EULER_E 				, false	},	//11
	{ f_NUMBER_PI 				, false	},	//12
	{ 0x0010000000000000LLU	 	, false	},	//13 smallest normal number 1*2^-1022 = 2.22e-308
	{ 0x0018000000000000LLU	 	, false	},	//14: normal number 1,5*2^-1022  = 3,33e-308
	{ 0x0008000000000000LLU	 	, true	},	//15: subnormal number 0,5*2^-1022 = 2^-1023 = 1.11e-308
	{ 0x0004000000000000LLU	 	, true  },	//16 subnormal number
	{ 0x0000000000000001LLU	 	, true  },	//17 smallest subnormal number
	{ 0x64B0000000000000LLU		, false }, 	//18 2^588=1.013e177, here log10=177,006 and 588*0,301=176,988
	{ 0xB94CD1E6922D3528LLU		, false },	//19 -1.110103111185E-32 needs correction for first digit
	{ 0x750710EABA00BAB8LLU		, false },	//20 5.4115311284833E+255 special case exponent = 255
	{ 0x433fffffffffffffLLU		, false },	//21  9007199254740991
	{ 0x4340000000000000LLU		, false },	//22  9007199254740992 last number with full 53 bit precision
	{ 0x4340000000000001LLU		, false },	//23  9007199254740994
	{ 0x434fffffffffffffLLU		, false },	//24 18014398509481982
	{ 0x4350000000000000LLU		, false },	//25 18014398509481984
	{ 0x4350000000000001LLU		, false },	//26 18014398509481988
	{ f_NUMBER_01				, false },	//27 0.1 rounded up
	{ 0x3FB9999999999999LLU		, false },  //28 0.1 rounded down
	{ f_NUMBER_001				, false },	//29 0.01
	{ 0xC1DF378C7CA24FCCLLU		, false }, 	//30 -2094936562.5361204 a negative number that might round up 
	{ 0x3fefffffffffffc9LLU		, false } 	//31 0.999999999999993893773364, a number where correct rounding must occur for 15 digits 
};
int ftoa_table1_size = sizeof(ftoa_table1) / sizeof( struct ftoa_table1_t );
#endif

#if defined(CHECK_ATOF)
const struct atof_table1_t {
	const char *s;
	uint8_t		endPos;
	float64_t	expRes;
}  atof_table1[] PROGMEM = {
	{ NULL,		0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "",		0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "A",		0,	f_NUMBER_NAN },	// 0
	{ "X",		0,	f_NUMBER_NAN },	// 0
	{ "N",		0,	f_NUMBER_NAN },	// 0
	{ "+N",		0,	f_NUMBER_NAN },	// 0
	{ "+NaN",	0,	f_NUMBER_NAN },	// 0
	{ "0000",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "+0000",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "-0000",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "12",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "123",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1234",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "12345",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "123456",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1234567",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "12345678",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "123456789",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1234567890",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "12345678901",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "123456789012",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1234567890123",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "12345678901234",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "123456789012345",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1234567890123456",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "12345678901234567",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "123456789012345678",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1234567890123456789",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1.2",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1.23",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1E3",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1E10",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1E100",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1E200",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1E255",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1E256",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1E257",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1E300",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1E308",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1E310",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1E320",	0,	float64_NUMBER_PLUS_ZERO },	// 0
	{ "1E330",	0,	float64_NUMBER_PLUS_ZERO }	// 0
	// { "1E",		0,	f_NUMBER_NAN }	// 0
	// { "-1E",	0,	f_NUMBER_NAN },	// 0
	// { "1E-",	0,	f_NUMBER_NAN },	// 0
	// { ".",		0,	f_NUMBER_NAN },	// 0
	// { "1E.",	0,	f_NUMBER_NAN },	// 0
	// { "1E",		0,	f_NUMBER_NAN }	// 0
};
int atof_table1_size = sizeof(atof_table1) / sizeof( struct atof_table1_t );
#endif

bool isSubnormal( float64_t x ) {
	return ( ((x & 0x7fffffffffffffffLLU) != 0x0000000000000000LLU) 
		  && (((x >> 48) & 0x7fff) < 0x0010) );
}

struct check_mult_table_t *get_mult_tableFlags(int i, int j) {
	memcpy_P( &_p1, &check_mult_table[i], sizeof(_p1) );
	if( j !=  FLAGS_MULT) {
		_p1.isNaN 	= (_p1.flags[j] & F_NAN) ? 1 : 0;
		_p1.isfinite= (_p1.flags[j] & F_FINITE) ? 1 : 0;
		_p1.isInf	= (_p1.flags[j] & F_PINFIN) ? 1 : 
					  (_p1.flags[j] & F_MINFIN) ? -1 : 0;
	}
	return &_p1;
}

struct timing_t {
	const char *label;
	long time1;
	long time2;
} timings[MAX_TIMINGS];
int timingEntry = 0;

float64_t createRandom() {
	float64_t res;
	uint8_t *p;

	p = (uint8_t*) &res;
	for( int i = 0; i < 8; i++ ) {
		*p++ = (uint8_t) random(256);
	}
	return res;
}

// create a random number with |x| < 2^64
float64_t createRandom64() {
	float64_t res;
	uint8_t *p;

	p = (uint8_t*) &res;
	for( int i = 0; i < 6; i++ ) {
		*p++ = (uint8_t) random(256);
	}
	
	// create exponent 
	uint16_t exp = random(64) + 0x3ff;
	int sign = random(2);
	if( sign )
		exp |= 0x800;
	uint8_t low = ((exp & 0xf) << 4) + random(16);
	uint8_t high = (exp >> 4);
	*p++ = low;
	*p++ = high;
	
	return res;
}

void hexDump( const char *s, uint8_t n ) {
	char s2[2] = { ' ', '\0' };
	Serial.print( toHex4( (uint16_t) s ) );
	Serial.print( " " );
	for( int i = 0; i < n; i++ ) {
		Serial.print( toHex2( (uint8_t) s[i] ) );
		Serial.print( " " );
	}
	for( int i = 0; i < n; i++ ) {
		s2[0] = isPrintable( s[i] ) ? s[i] : '.';
		Serial.print( s2 );
	}
	Serial.println();
}

bool check(bool ok) {
	if( ok ) {
		testPassed++;
		Serial.print( F("OK  ") );
	} else {
		testFailed++;
		Serial.print( F("ERR ") );
	}
	return( ok );
}

bool check_diff(float64_t res, float64_t exp_res) {
	bool ok = res == exp_res;
	if( !ok && fp64_isnan(res) && fp64_isnan(exp_res) )
		// override ok, as there are many representations for NaN
		ok = true;
	if( !ok && (isSubnormal(res) != isSubnormal(exp_res)) ) {
		check( ok = true );
		Serial.print( F("OVERRIDE subn ") );
	} else
		check(ok);
	
	if( !ok && fp64_isfinite(res) && fp64_isfinite(exp_res) ) {

		Serial.print( isSubnormal(res) ); 
		Serial.print( F(" ") );
		Serial.print( isSubnormal(exp_res) ); 
		Serial.print( F(" ") );
	
		if( fp64_signbit( res ) != fp64_signbit( exp_res ) ) {
			Serial.print( F("sign ") );
			testSign++;
		}
		long long diff = f_abs(res) - f_abs(exp_res); // use long subtraction
		if( diff < 0LL )
			diff = -diff;
		if( diff > 64LL ) {
			Serial.print( F(">7ulp ") );
			testPrec[7]++;
		} else if( diff > 32LL ) {
			Serial.print( F("7ulp ") );
			testPrec[6]++;
		} else if( diff > 16LL ) {
			Serial.print( F("6ulp ") );
			testPrec[5]++;
		} else if( diff > 8LL ) {
			Serial.print( F("5ulp ") );
			testPrec[4]++;
		} else if( diff > 4LL ) {
			Serial.print( F("4ulp ") );
			testPrec[3]++;
		} else if( diff > 2LL ) {
			Serial.print( F("3ulp ") );
			testPrec[2]++;
		} else if( diff > 1LL ) {
			Serial.print( F("2ulp ") );
			testPrec[1]++;
		} else {
			Serial.print( F("1ulp ") );
			testPrec[0]++;
		}
		Serial.print( (long) diff , HEX);
		Serial.print( F(" ") );
	}
	return( ok );
}

char *toHex2( uint8_t n)  {
	static char res[3];
	uint8_t d = n >> 4;
	res[0] = d + (d < 10 ? '0' : 'A'-10);
	d = n & 0x0f;
	res[1] = d + (d < 10? '0' : 'A'-10);
	res[2] = 0;
	return res;
}

char *toHex4( uint16_t n ) {
	static char res[5];
	char *q = res;
	char *p = toHex2( n >> 8 );
	*q++ = *p++;
	*q++ = *p++;
	p = toHex2( n & 0xff );
	*q++ = *p++;
	*q++ = *p++;
	*q++ = *p++;
	return( res );
}

void dump( float64_t r, const char *s ) {
  unsigned char *ur =  ((unsigned char *)&r)+7;
  Serial.print(F("((float64_t)0x"));
  for( int i = 0; i < 8; i++ )
		Serial.print( toHex2( *ur-- ));
  Serial.print(F("LLU), //"));
  Serial.print(f_to_string(r,(uint8_t)20,(uint8_t)2));
  if( isSubnormal(r) )
	  Serial.print(F(" subn"));
  Serial.print(F(" "));
  Serial.println(s);
}

void dumpInt( int x, const char *s) {
  Serial.print( x );
  Serial.print(F(":"));
  Serial.println(s);
}

void dumpLong( uint8_t* p, const char *s ) {
	Serial.print(s);
	Serial.print(F(" 0x"));
	p += 7;
	for( int i = 0; i < 8; i++ )
		Serial.print(toHex2(*p--));
	Serial.print(F(" "));
}

#if defined(CHECK_CONV) || defined(CHECK_TOINT) || defined(CHECK_FN) || defined(CHECK_CMP)
// libc for arduino does not include any
// function to convert a long long to a
// string, so we have to include our own
// simple version for unsigned and signed numbers
char *convertULL( unsigned long long x ) {
	static char s[30];
	char *p = s;
	
	*p++ = ' '; // insert space for sign
	do {
		uint8_t digit = x % 10ULL;
		x = x / 10ULL;
		*p++ = digit + '0';	
	} while( x > 0ULL );
	*p-- = '\0';
	// Serial.print("r"); Serial.print(s);Serial.print("r");
	
	for( char *q = s+1; q < p; q++, p-- ) {
		char c = *q;
		*q = *p;
		*p = c;
	}
	
	return s;
}

char *convertLL( long long x ) {
	if( x < 0LL ) {
		char *s = convertULL( -x );
		*s = '-';
		return s;
	} else
		return convertULL( x );
}
#endif

void dump_debug( fp64_debug_t *xd ) {
	//String sreg = "ITHSVNZC ";
	char sreg[] = "ITHSVNZC ";
	//Serial.print( "SREG 0x" );
	if( xd->count < 100 )
		Serial.print( xd->count < 10 ? F("00") : F("0") );
	Serial.print( xd->count );
	Serial.print( F(" SREG ") );
	Serial.print( toHex2(xd->sreg));
	Serial.print( " " );
	for( int i = 0; i < 8; i++ ) {
		if( !(xd->sreg & (0x80 >> i)) )
			sreg[i] = sreg[i]+32;
	}
	Serial.print( sreg );
	//Serial.print( "S" );
	//Serial.print( xd->sign ); 
	Serial.print( xd->sign & 0x80 ? F("sub ") : F("add ") );
	Serial.print( F(" r7:0x") );
	Serial.print( toHex2(xd->r7) );
	Serial.print( xd->sign & 0x01 ? F(" -") : F(" +") );
	Serial.print( F("0x") );
	for( int i = 0; i < 7; i++ )
		Serial.print(toHex2(xd->m[i]));
	Serial.print("e");
	Serial.print(toHex4(xd->exp));
	Serial.print(" ");
	Serial.print( xd->exp );
	Serial.print( F(" r0:0x") );
	Serial.print( toHex2(xd->r0) );
	Serial.print( fp64_debug_isT(xd) ? F(" -") : F(" +"));
	Serial.print( fp64_debug_isC(xd) ? 
		(fp64_debug_isZ(xd) ? F("Inf") : F("NaN"))  :
		(fp64_debug_isZ(xd) ? F("finite zero"):F("finite")) );
	Serial.println();
}
	
void check_intop1( float64_t x, i1ptr f, const char *s, int exp_res, bool doPrint ) {
	int res = (*f)(x);
	if( doPrint) {
		dddump( x );
	}
	if( check( res == exp_res ) ) {
		Serial.print( res );
		Serial.print( F("==") );
	} else {
		Serial.print( res );
		Serial.print( F("!=") );
	}
	Serial.print( exp_res );
	Serial.print(F(" "));
	Serial.print(s);
	Serial.println();
}

void check_longop1( float64_t x, l1ptr f, const char *s, long exp_res ) {
	dddump( x );
	struct fp64_debug_t* xd = __fp64_debugAB();
	long res = (*f)(x);
	dump_debug( xd ); // dump intermediate result			
	dump_debug( xd+1 );
	
	if( check( res == exp_res ) ) {
		Serial.print( res );
		Serial.print( F("==") );
	} else {
		Serial.print( res );
		Serial.print( F("!=") );
	}
	Serial.print( exp_res );
	Serial.print(F(" "));
	Serial.print(s);
	Serial.println();
}

void check_intop2( float64_t x, float64_t y, i2ptr f, const char *s, int exp_res, bool doPrint ) {
	struct fp64_debug_t* xd = __fp64_debugAB();
	int res = (*f)(x, y);
	dump_debug( xd ); // dump intermediate result			
	dump_debug( xd+1 );
	if( doPrint) {
		dddump( x );
		dddump( y );
	}
	bool ok = res == exp_res;
	if( !ok && (isSubnormal(x) || isSubnormal(y)) ) {
		check( ok = true );
		Serial.print( res );
		Serial.print( F(" OVERRIDE subn ") );
	} else if( check( res == exp_res ) ) {
		Serial.print( res );
		Serial.print( F("==") );
	} else {
		Serial.print( res );
		Serial.print( F("!=") );
	}
	Serial.print( exp_res );
	Serial.print(F(" "));
	Serial.print(s);
	Serial.println();
	Serial.println();
}

bool check_res( float64_t x, float64_t res, const char *s, float64_t exp_res ) {
#ifndef FAST
	dddump( x );
	dddump( res );
	dddump( exp_res );
#endif
	bool ok = res == exp_res;
	if( fp64_isfinite(res) && fp64_isfinite( exp_res ) ) {
		if( !ok && ((isSubnormal(res) != isSubnormal(exp_res) ) ||
					(isSubnormal(x) && exp_res == 0x0000000000000000LLU) )) {
			check( ok = true );
			Serial.print( F("OVERRIDE subn ") );
		} else
			check_diff( res, exp_res );
	} else if( isSubnormal(x) ) {
		if( ok )
			check( ok );
		else {
			check( ok = true );
			Serial.print( F("OVERRIDE subn ") );
		}
	} else if( fp64_isnan(res) || fp64_isnan(exp_res) ) {
		Serial.print( "NaN" ); Serial.print(fp64_isnan(res)); Serial.print(fp64_isnan(exp_res));
		check( fp64_isnan(res) == fp64_isnan(exp_res) );
	} else {
		Serial.print( "Inf" ); Serial.print(fp64_isinf(res)); Serial.print(fp64_isinf(exp_res));
		check( fp64_isinf(res) == fp64_isinf(exp_res) );
	}
	Serial.println( s );
	return ok;
}

void check_fop1( float64_t x, f1ptr f, const char *s, float64_t exp_res ) {
	struct fp64_debug_t* xd = __fp64_debugAB();
	float64_t res = (*f)(x);
#ifndef FAST
	dump_debug( xd ); // dump intermediate result			
	dump_debug( xd+1 ); // dump intermediate result			
	// dump_debug( xd+2 ); // dump intermediate result			
#endif
	check_res( x, res, s, exp_res );
}

float64_t check_fop2( float64_t a, float64_t b, f2ptr f, const char *s, float64_t exp_res ) {
	//__fp64_split3(a,b);
	struct fp64_debug_t* xd = __fp64_debugAB();
	float64_t res = (*f)(a,b);
#ifndef FAST
	dump_debug( xd ); // dump intermediate result			
	dump_debug( xd+1 );
	dddump( a );
	dddump( b );
	dddump( res );
	dddump( exp_res );
#endif
	bool ok = res == exp_res;
	if( fp64_isfinite(res) && fp64_isfinite(exp_res) ) {
		if( !ok && 
			(isSubnormal(a) || isSubnormal(b)) && 
			(exp_res == float64_NUMBER_PLUS_ZERO || isSubnormal(res)) ) {
			check( ok = true );
			Serial.print( F(" OVERRIDE subn ") );
		} else
			check_diff( res, exp_res );
	} else {
		ok = fp64_isfinite(res) == fp64_isfinite(exp_res);
		if( !ok && (isSubnormal(a) || isSubnormal(b)) ) {
			check( ok = true );
			Serial.print( F(" OVERRIDE subn ") );
		} else {
			check( ok );
		}
	}
	Serial.println( s );
	return res;
}

float64_t dump_op2( int i, float64_t a, float64_t b, f2ptr f_new, f2ptr f_old, const char *s, int iFlags ) {
	float64_t res, res2;

	res2 = (*f_old)( a, b );
	Serial.print(i);
	Serial.println(":");
	// dddump(a);
	// dddump(b);
	res = check_fop2( a, b, f_new, s, res2 );
	struct check_mult_table_t *p = get_mult_tableFlags(i, iFlags);
	check_intop1( res, fp64_isinf, 		"isinf", 	p->isInf, false );
	check_intop1( res, fp64_isnan, 		"isnan", 	p->isNaN, false );
	check_intop1( res, fp64_isfinite, 	"isfinite", p->isfinite, false );
	Serial.println();
	return( res );
}

#ifdef WITH_TIMING
void addTiming1( const char *label, long time1 ) {
	if( timingEntry < MAX_TIMINGS ) {
		timings[timingEntry].label = label;
		timings[timingEntry].time1 = time1;
	}
}

void addTiming2( const char *label, long time2 ) {
	if( timingEntry < MAX_TIMINGS )
		timings[timingEntry++].time2 = time2;
}

void dumpTimings() {
	char s[60];
	Serial.println( F("-------- timings ---------") );
		sprintf( s, "%30s %8s %8s %8s ", "function", "fp64lib", "avr_f64", "diff" );
		Serial.println( s );
	for( int i = 0; i < timingEntry; i++ ) {
		sprintf( s, "%30s %8ld %8ld ", timings[i].label, timings[i].time1, timings[i].time2 );
		Serial.print( s );
		Serial.print( (float)(timings[i].time1 - timings[i].time2) * 100.0 / (float) timings[i].time2 );
		Serial.println( F("%") );
	}
}	

void timeItCommon( float64_t res, const char *s, bool time1, unsigned long time ) {
	Serial.print( time );
	Serial.print( F(" ") );
	Serial.println(s);
	ddump( res );	
	if( time1 )
		addTiming1( s, time );
	else
		addTiming2( s, time );
}

// time an operation that is recursevely applied to itself
void timeItR( float64_t a, float64_t b, f2ptr f, const char *s, bool time1 ) {
	float64_t res;
	unsigned long start;
	
	res = a;
	start = micros();
	for( int i = 0; i < 1000; i++ ) {
		res = (*f)( res, b );
	}
	timeItCommon( res, s, time1, micros() - start );
}

// time an operation with always the same two operands
void timeIt( float64_t a, float64_t b, f2ptr f, const char *s, bool time1 ) {
	float64_t res;
	unsigned long start;
	
	start = micros();
	for( int i = 0; i < 1000; i++ ) {
		res = (*f)( a, b );
	}
	timeItCommon( res, s, time1, micros() - start );
}

// time an operation with always the same one operand
void timeIt1( float64_t a, f1ptr f, const char *s, bool time1 ) {
	float64_t res;
	unsigned long start;
	
	if( f == NULL ) {
		Serial.print(F("ERROR: called with null pointer"));
		return;
	}
	ddump( a );
	start = micros();
	for( int i = 0; i < 1000; i++ ) {
		res = (*f)( a );
	}
	timeItCommon( res, s, time1, micros() - start );
}

void timeItLong( float64_t x, l1ptr f1, l1ptr f2, const char *s ) {
	// cannot use timeIt operations as result are strings
	unsigned long start;
	long res;
	start = micros();
	for( int i = 0; i < 1000; i++ ) {
			res = (*f1)( x );
	}
	timeItCommon( x, s, true, micros() - start );
	start = micros();
	for( int i = 0; i < 1000; i++ ) {
			res = (*f2)( x );
	}
	timeItCommon( x, s, false, micros() - start );
}
#endif

#ifdef CHECK_ISXXX
void check_isnan() {
	// check isNAN
	Serial.println("--------- check isNAN ---------");
	dumpInt( fp64_isnan( float64_ONE_POSSIBLE_NAN_REPRESENTATION ), "isnan(possible_NAN)" );
	dumpInt( fp64_isnan( __fp64_nan()), "isnan(__fp64_nan())");
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.println(i);
		float64_t x = get_check_table1(i)->x;
		check_intop1(x, fp64_isnan, "fp64_isnan", get_check_table1(i)->isNaN, true );
		if( x == float64_ONE_POSSIBLE_NAN_REPRESENTATION )
			// override as f_isnan does not work correctly
			check_intop1(x, fp64_isnan, "fp64_isnan", true, true );
		else
			check_intop1(x, fp64_isnan, "fp64_isnan", f_isnan(x), true );
	}	
}

void check_isinf() {
	// check isInf
	Serial.println(F("--------- check fp64_isinf---------"));
	dddump( float64_PLUS_INFINITY );
	dumpInt( fp64_isinf( float64_PLUS_INFINITY ), "fp64_isinf(+inf)" );
	dddump( float64_MINUS_INFINITY );
	dumpInt( fp64_isinf( float64_MINUS_INFINITY ), "fp64_isinf(-inf)" );
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.println(i);
		check_intop1(get_check_table1(i)->x, fp64_isinf, "fp64_isinf", get_check_table1(i)->isInf, true );
	}
}

void check_isfinite() {
	// check isfinite
	Serial.println(F("--------- check fp64_isfinite ---------"));
	dddump( float64_EULER_E );
	dddump( float64_NUMBER_PI );
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.println(i);
		float64_t x = get_check_table1(i)->x;
		check_intop1(x, fp64_isfinite, "fp64_isfinite", get_check_table1(i)->isfinite, true );
		int exp_res = f_finite(x);
		check_intop1(x, fp64_isfinite, "fp64_isfinite", exp_res, true );
	}
}

void check_signbit() {
	// check signbit
	Serial.println(F("--------- check signbit ---------"));
	for( int i = 0; i < check_table1_size; i++ ) {
		// avr_f64 lib does not have a signbit function, so we use code out of the 
		// internal function f_fplit64 to extract to extract the sign
		int f_sign = ((get_check_table1(i)->x)>>63) & 1;
		check_intop1(get_check_table1(i)->x, fp64_signbit, "signbit", f_sign, true );
	}
}

void check_fpclassify() {
	Serial.println("--------- check fp64_classify ---------");
	for( int i = 0; i < check_table1_size; i++ ) {
		float64_t x = get_check_table1(i)->x;
		int res2;
		if( get_check_table1(i)->isNaN )
			res2 = FP_NAN;
		else if( get_check_table1(i)->isInf )
			res2 = FP_INFINITE;
		else if( x == float64_NUMBER_PLUS_ZERO || x == 0x8000000000000000LLU )
			res2 = FP_ZERO;
		else if( isSubnormal(x) )
			res2 = FP_SUBNORMAL;
		else
			res2 = FP_NORMAL;
		check_intop1(x, fp64_classify, "fp64_classify", res2, true );
	}
}

void check_isxxx() {
	check_isnan();
	check_isinf();
	check_isfinite();
	check_signbit();
	check_fpclassify();
}

#endif

#ifdef CHECK_ADD
void dump_add( int i, float64_t a, float64_t b ) {
	dump_op2( i, a, b, fp64_add, f_add, "f_add", FLAGS_ADD );
}

void check_add() {
	float64_t a, b;
	
	Serial.println(F("--------- check + ---------"));

	for( int i = 0; i < check_mult_table_size; i++ ) {
	// for( int i = 0; i < 6; i++ ) {
		a = get_mult_table(i)->a;
		b = get_mult_table(i)->b;
		dump_add( i, a, b );
		dump_add( i, b, a );
	}

#ifdef WITH_TIMING	
	Serial.println(F("--------- timing + ---------"));
	timeItR( f_EULER_E,f_NUMBER_2,fp64_add, "fp64_add", true);
	timeItR( f_EULER_E,f_NUMBER_2,f_add, "f_add", false);

	a = get_mult_table(23)->a;
	b = get_mult_table(23)->b;
	timeIt( a, b, fp64_add, "fp64_add subn", true);

	a = get_mult_table(23)->a;
	b = get_mult_table(23)->b;
	timeIt( a, b, f_add, "f_add subn", false);	
#endif
}
#endif

#if defined(CHECK_SUB) || defined(CHECK_FDIM)
// there is an error in f_sub:
// when b is +INF, f_sub returns +INF instead of -INF
// simalar for b == -INF: f_sub returns -INF instead of +INF
float64_t my_sub( float64_t a, float64_t b ) {
	if( fp64_isinf(b) )
		return( b ^ 0x8000000000000000LLU );
	else
		return( f_sub(a,b) );
}
#endif
#ifdef CHECK_SUB
void dump_sub( int i, float64_t a, float64_t b ) {
	dump_op2( i, a, b, fp64_sub, my_sub, "f_sub", FLAGS_SUB );
}

void check_sub() {
	float64_t a, b;
	float64_t res, res2;
	
	Serial.println(F("--------- check - ---------"));

	for( int i = 0; i < check_mult_table_size; i++ ) {
	// for( int i = 43; i < 46; i++ ) {
		a = get_mult_table(i)->a;
		b = get_mult_table(i)->b;
		dump_sub( i, a, b );
		dump_sub( i, b, a );
	}

#ifdef WITH_TIMING	
	Serial.println(F("--------- timing - ---------"));
	timeItR( f_EULER_E,f_NUMBER_2,fp64_sub, "fp64_sub", true);
	timeItR( f_EULER_E,f_NUMBER_2,f_sub, "f_sub", false);

	a = get_mult_table(23)->a;
	b = get_mult_table(23)->b;
	timeIt( a, b, fp64_sub, "fp64_sub subn", true);

	a = get_mult_table(23)->a;
	b = get_mult_table(23)->b;
	timeIt( a, b, f_sub, "f_sub subn", false);	
	
	res2 = a = f_EULER_E;
	b = f_NUMBER_2;
	for( int i = 0; i < 5; i++ ) {
		Serial.println( i );
		res2 = f_sub(a,b);
		res = check_fop2( a, b, fp64_sub, "loop -2",  res2 );
		a = res;
	}
#endif
}
#endif

#ifdef CHECK_MULT
float64_t dump_mult( int i, float64_t a, float64_t b ) {
	float64_t res = dump_op2( i, a, b, fp64_mul, f_mult, "fp64_mul", FLAGS_MULT );
	return( res );
}

void check_mult() {
	float64_t a, b, res, res2;
	
	Serial.println(F("--------- check * ---------"));
	struct fp64_debug_t* xd = __fp64_debugAB();
	a = 0x3FFFFFFFFFFFFFFFLLU;
	b = 0x3FFFFFFFFFFFFFFFLLU;
	res = fp64_mul(a,b);
	dump_debug( xd ); // dump intermediate result			
	dump_debug( xd+1 );
	res2 = f_mult(a,b);
	ddump( res );
	ddump( res2 );
	check_diff( res, res2 ); Serial.println( F("fp64_mul") );
	
	for( int i = 0; i < check_mult_table_size; i++ ) {
		a = get_mult_table(i)->a;
		b = get_mult_table(i)->b;
		res = dump_mult( i, a, b );
		res2 = dump_mult( i, b, a );
		check_diff( res, res2 ); Serial.println( F("fp64_mul") );
		Serial.println();
	}
	
	// check handling of subnormals downwards
	a = 0x0020000000000000LLU;
	b = f_NUMBER_0_5;
	for( int i = 0; i < 54; i++ ) {
		Serial.print( i );
		Serial.println(F(": subn"));
		ddump( a );
		ddump( b );
		res = fp64_mul( a, b );
		dump_debug( xd ); // dump intermediate result			
		dump_debug( xd+1 );
		res2 = a >> 1;
		ddump( res );
		ddump( res2 );
		check_diff( res, res2 );  Serial.println( F("fp64_mul subn") );
		a = res2;
		Serial.println();
	}

	// check handling of subnormals upwards
	a = 0x8000000000000001LLU;
	b = f_NUMBER_2;
	for( int i = 0; i < 53; i++ ) {
		Serial.print( i );
		Serial.println(F(": subn"));
		ddump( a );
		ddump( b );
		res = fp64_mul( a, b );
		dump_debug( xd ); // dump intermediate result			
		dump_debug( xd+1 );
		res2 = a << 1 | 0x8000000000000000LLU;;
		ddump( res );
		ddump( res2 );
		check_diff( res, res2 );  Serial.println( F("fp64_mul subn") );
		a = res2;
		Serial.println();
	}

#ifdef WITH_TIMING
	Serial.println(F("--------- timing * ---------"));
	timeItR( f_EULER_E,f_NUMBER_2,fp64_mul, "fp64_mul", true);
	timeItR( f_EULER_E,f_NUMBER_2,f_mult, "f_mult", false);

	a = get_mult_table(23)->a;
	b = get_mult_table(23)->b;
	timeIt( a, b, fp64_mul, "fp64_mul subn", true);

	a = get_mult_table(23)->a;
	b = get_mult_table(23)->b;
	timeIt( a, b, f_mult, "f_mult subn", false);
#endif
	
}
#endif

#ifdef CHECK_DIV
void dump_div( int i, float64_t a, float64_t b ) {
	dump_op2( i, a, b, fp64_div, f_div, "f_div", FLAGS_DIV );
}

void check_div() {
	float64_t a, b;
	
	Serial.println(F("--------- check / ---------"));

	for( int i = 0; i < check_mult_table_size; i++ ) {
	//for( int i = 0; i < 13; i++ ) {
		a = get_mult_table(i)->a;
		b = get_mult_table(i)->b;
		dump_div( i, a, b );
		//dump_div( i, b, a );
	}

#ifdef WITH_TIMING
	Serial.println(F("--------- timing / ---------"));
	timeItR( f_EULER_E,f_NUMBER_2,fp64_div, "fp64_div", true);
	timeItR( f_EULER_E,f_NUMBER_2,f_div, "f_div", false);
	timeItR( 0x7fefffffffffffffLLU, f_EULER_E,fp64_div, "fp64_div", true);
	timeItR( 0x7fefffffffffffffLLU, f_EULER_E,f_div, "f_div", false);

	a = get_mult_table(23)->a;
	b = get_mult_table(23)->b;
	timeIt( a, b, fp64_div, "fp64_div subn", true);

	a = get_mult_table(23)->a;
	b = get_mult_table(23)->b;
	timeIt( a, b, f_div, "f_div subn", false);
#endif
}
#endif

#ifdef CHECK_FMOD
float64_t my_fmod( float64_t x, float64_t y ) {
	return f_mod( x, y, NULL );
}

void dump_fmod( int i, float64_t a, float64_t b ) {
	dump_op2( i, a, b, fp64_fmod, my_fmod, "fp64_fmod", FLAGS_FMOD );
}

void check_fmod() {
	float64_t a, b, res, res2, diff, diff2, n2;
	unsigned long n;
	
	Serial.println(F("--------- check fmod ---------"));

	for( int i = 0; i < check_mult_table_size; i++ ) {
	//for( int i = 0; i < 13; i++ ) {
		a = get_mult_table(i)->a;
		b = get_mult_table(i)->b;
		dump_fmod( i, a, b );
		// dump_fmod( i, b, a );
	}
	
	// dump_fmod( 99, 	0x4076300000000000LLU, float64_NUMBER_PIO2 );
	dddump( f_NUMBER_PIx );
	a = fp64_fmodn( 0x4076300000000000LLU, float64_NUMBER_PIO2, &n );
	ddump( a );
	ddump( fp64_sin(a) );
	b = fp64_int32_to_float64( n );
	b = fp64_mul( b, f_NUMBER_PIx );
	ddump( b );
    a = fp64_sub( a, b );
	ddump( a );
	ddump( fp64_sin(a) );
	Serial.println( (int)&n, HEX );
	
	Serial.println( F("Testing fp64_fmodx_pi2") );
	n = 99999999;
	struct fp64_debug_t* xd = __fp64_debugAB();
	a = float64_NUMBER_PIO2;
	ddump( a );
	ddump( fp64_sin(a) );
	a = fp64_fmodx_pi2( a, &n );
	dump_debug( xd );
	dump_debug( xd+1 );
	dump_debug( xd+2 );
	ddump( a );
	ddump( fp64_sin(a) );
	Serial.println( n );
	
	n = 99999999;
	a = 0x4076300000000000LLU;
	ddump( a );
	ddump( fp64_sin(a) );
	a = fp64_fmodx_pi2( a, &n );
	dump_debug( xd );
	dump_debug( xd+1 );
	dump_debug( xd+2 );
	ddump( a );
	ddump( fp64_sin(a) );
	Serial.println( n );
	
	// for( int j = 3; j < 12; j++ ) {
	for( int j = 3; j < 1; j++ ) {
		a = float64_NUMBER_ONE;
		b = fp64_inverse( fp64_int32_to_float64(j) ); // 1/j
		struct fp64_debug_t* xd = __fp64_debugAB();
		for( int i = 0; i < 9; i++ ) {
			Serial.println( i );
			ddump( a );
			ddump( b );
			res = fp64_fmodn( a, b, &n );
			dump_debug( xd );
			dump_debug( xd+1 );
			res2 = f_mod( a, b, &n2 );
			ddump( res );
			ddump( res2 );
			check_diff( res, res2 ); Serial.println( "fp64_fmodn" );
			Serial.print( n, HEX ); Serial.print( " " ); Serial.print( n ); Serial.println( " n");
			ddump( n2 );
			diff = fp64_mul( b, fp64_uint32_to_float64(n) );
			diff2 = f_mult( b, n2 );
			ddump( diff );
			ddump( diff2 );
			check_diff( diff, diff2 );  Serial.println( "fp64_fmodn" );
			res = fp64_sub( a, diff );
			res2 = f_sub( a, diff2 );
			ddump( res );
			ddump( res2 );
			check_diff( res, res2 );  Serial.println( "fp64_fmodn" );
			Serial.println();
			a = fp64_mul( a, f_NUMBER_10 );
		}
		Serial.println();
	}

#ifdef WITH_TIMING
	Serial.println(F("--------- timing fmod ---------"));
	timeIt( f_NUMBER_100, f_NUMBER_6E_3, fp64_fmod, "fp64_fmod", true);
	timeIt( f_NUMBER_100, f_NUMBER_6E_3, my_fmod, "f_mod", false);
#endif	
}
#endif

#ifdef CHECK_CMP
void check_cmp() {
	float64_t a, b;
	int8_t exp_res;
	
	Serial.println(F("--------- check fp64_compare (<,=,>) ---------"));

	for( int i = 0; i < check_mult_table_size; i++ ) {
		Serial.print(i);
		Serial.println(":");
		a = get_mult_table(i)->a;
		b = get_mult_table(i)->b;
		exp_res = f_compare( a, b );
		if( fp64_isnan(a) || fp64_isnan(b) ) {
			Serial.println( "OVERRIDE NaN fp64_compare");
			exp_res = 1;
		}
		check_intop2( a, b, fp64_compare, "fp64_compare", exp_res, true );
		exp_res = f_compare( b, a );
		if( fp64_isnan(a) || fp64_isnan(b) ) {
			Serial.println( "OVERRIDE NaN fp64_compare");
			exp_res = 1;
		}
		check_intop2( b, a, fp64_compare, "fp64_compare", exp_res, true );
	}
	
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_compare ---------"));
	timeIt( f_NUMBER_100, f_NUMBER_6E_3, fp64_compare, "fp64_compare", true);
	timeIt( f_NUMBER_100, f_NUMBER_6E_3, f_compare, "f_compare", false);
#endif
}

float64_t my_fmax( float64_t a, float64_t b ) {
	// we have to handle the special cases for ourselves,
	// as f_compares returns 0 for these
	if( fp64_isnan(a) )
		return(b);
	else if( fp64_isnan(b) )
		return(a);
	// if( (int64_t)a >= (int64_t)b )
	if( f_compare(a,b) > 0 )
		return( a );
	else
		return( b );
}

void check_fmax() {
	float64_t a, b;
	
	Serial.println(F("--------- check fp64_fmax ---------"));

	for( int i = 0; i < check_mult_table_size; i++ ) {
		Serial.print(i);
		Serial.println(":");
		a = get_mult_table(i)->a;
		b = get_mult_table(i)->b;
		dump_op2( i, a, b, fp64_fmax, my_fmax, "fp64_fmax", FLAGS_FMAX );
		dump_op2( i, b, a, fp64_fmax, my_fmax, "fp64_fmax", FLAGS_FMAX );
	}
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_fmax ---------"));
	timeIt( f_NUMBER_100, f_NUMBER_6E_3, fp64_fmax, "fp64_fmax", true);
	timeIt( f_NUMBER_100, f_NUMBER_6E_3, my_fmax, "my_fmax", false);
#endif	
}

float64_t my_fmin( float64_t a, float64_t b ) {
	if( fp64_isnan(a) )
		return(b);
	else if( fp64_isnan(b) )
		return(a);
	if( f_compare(a,b) < 0 )
		return( a );
	else
		return( b );
}

void check_fmin() {
	float64_t a, b;
	
	Serial.println(F("--------- check fp64_fmin ---------"));

	for( int i = 0; i < check_mult_table_size; i++ ) {
		Serial.print(i);
		Serial.println(":");
		a = get_mult_table(i)->a;
		b = get_mult_table(i)->b;
		dump_op2( i, a, b, fp64_fmin, my_fmin, "fp64_fmin", FLAGS_FMIN );
		dump_op2( i, b, a, fp64_fmin, my_fmin, "fp64_fmin", FLAGS_FMIN );
	}
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_fmin ---------"));
	timeIt( f_NUMBER_100, f_NUMBER_6E_3, fp64_fmin, "fp64_fmin", true);
	timeIt( f_NUMBER_100, f_NUMBER_6E_3, my_fmin, "my_fmin", false);
#endif	
}

void check_compare() {
	check_cmp();
	check_fmax();
	check_fmin();
}
#endif

#ifdef CHECK_CONV
void check_sd() {
	
	Serial.println(F("--------- check fp64_sd ---------"));
	struct fp64_debug_t* xd = __fp64_debugAB();
	for( int i = 0; i < size_vals; i++ ) {
		Serial.print( i );
		Serial.println(":");
		float64_t res = fp64_sd( get_check_vals(i) );
		float64_t res2 = f_sd( get_check_vals(i) );
		dump_debug( xd );
		ddump( res );
		ddump( res2);
		check( res == res2 );
		Serial.println( "fp64_sd" );
		Serial.println();
	}
}

// as check_didf_core routine checks the conversion, 
// we can't rely on the conversion function to work correctly
// so we have to pass the delta argument both as long long 
// and as float64_t
void check_didf_core( long long delta1, float64_t delta2 ) {
	// didf does not have a avr_f64 counterpart, 
	// so we can only check, whether the result
	// is similar, if the calculations would be done
	// in float64_t - and we have to check the 
	// output manually
	Serial.print(F("--------- check fp64_int64_to_float64 ")); 
	Serial.print( convertLL(delta1) );
	Serial.println(F(" ---------"));
	
	long long x = 0LL;
	float64_t res2 = float64_NUMBER_PLUS_ZERO;
	struct fp64_debug_t* xd = __fp64_debugAB();
	for( int i = 0; i < 244; i++ ) {
		Serial.print( i );
		Serial.println(":");
		float64_t res = fp64_int64_to_float64( x );
		dump_debug( xd );
		dumpLong( (uint8_t*) &x, "x:" );
		Serial.print( convertLL(x) );
		Serial.println();
		ddump( res );
		ddump( res2 );
		check_diff( res, res2 );
		Serial.println( F("fp64_int64_to_float64") );
		Serial.println();
		x = x + delta1;
		res2 = f_add( res2, delta2 );
		if( i % 4 == 3 ) {
			x = x << 1;
			res2 = f_mult( res2, f_NUMBER_2);
		}
	}
}

void check_didf() {
	check_didf_core( 1LL, float64_NUMBER_ONE );
	check_didf_core( -1LL, float64_MINUS_NUMBER_ONE );
}

void check_sidf_core( long delta ) {
	Serial.print(F("--------- check fp64_long_to_float64 ")); 
	Serial.print( delta );
	Serial.println(F(" ---------"));
	
	 long x = 0L;
	struct fp64_debug_t* xd = __fp64_debugAB();
	for( int i = 0; i < 116; i++ ) {
		Serial.print( i );
		Serial.println(":");
		float64_t res = fp64_long_to_float64( x );
		dump_debug( xd );
		float64_t res2 = f_long_to_float64( x );
		Serial.print( F("x: 0x") );
		Serial.print( x, HEX );
		Serial.print( F(" ") );
		Serial.println( x );
		ddump( res );
		ddump( res2 );
		check_diff( res, res2 );
		Serial.println( F("fp64_long_to_float64") );
		Serial.println();
		x = x + delta;
		if( i % 4 == 3 ) {
			x = x << 1;
		}
	}
}

void check_sssd_core( int16_t delta ) {
	Serial.print(F("--------- check fp64_long_to_float64 ")); 
	Serial.print( delta );
	Serial.println(F(" ---------"));
	
	int16_t x = 0;
	struct fp64_debug_t* xd = __fp64_debugAB();
	for( int i = 0; i < 52; i++ ) {
		Serial.print( i );
		Serial.println(":");
		float64_t res = __fp64sssd( x );
		dump_debug( xd );
		float64_t res2 = f_long_to_float64( (long) x );
		Serial.print( F("x: 0x") );
		Serial.print( x, HEX );
		Serial.print( F(" ") );
		Serial.println( x );
		ddump( res );
		ddump( res2 );
		check_diff( res, res2 );
		Serial.println( F("__fp64sssd") );
		Serial.println();
		x = x + delta;
		if( i % 4 == 3 ) {
			x = x << 1;
		}
	}
}


void timeIt1l( long a, f1lptr f, const char *s, bool time1 ) {
	float64_t res;
	unsigned long start;
	
	if( f == NULL ) {
		Serial.print(F("ERROR: called with null pointer"));
		return;
	}
	Serial.print( F("a: ") );
	Serial.println( a );
	start = micros();
	for( int i = 0; i < 1000; i++ ) {
		res = (*f)( a );
	}
	timeItCommon( res, s, time1, micros() - start );
}

void check_sidf() {
	long a;
	check_sidf_core( 1L );
	check_sidf_core( -1L );

	Serial.print(F("--------- timing fp64_long_to_float64 ---------"));
	a = 1L;
	timeIt1l( a, fp64_long_to_float64, "fp64_long_to_float64", true);
	timeIt1l( a, f_long_to_float64, "f_long_to_float64", false);
	a = 0x123L;
	timeIt1l( a, fp64_long_to_float64, "fp64_long_to_float64", true);
	timeIt1l( a, f_long_to_float64, "f_long_to_float64", false);
	a = 0x12345L;
	timeIt1l( a, fp64_long_to_float64, "fp64_long_to_float64", true);
	timeIt1l( a, f_long_to_float64, "f_long_to_float64", false);
	a = -a;
	timeIt1l( a, fp64_long_to_float64, "fp64_long_to_float64", true);
	timeIt1l( a, f_long_to_float64, "f_long_to_float64", false);
	a = 0x1234567L;
	timeIt1l( a, fp64_long_to_float64, "fp64_long_to_float64", true);
	timeIt1l( a, f_long_to_float64, "f_long_to_float64", false);
	
}

void check_uint64_to_float64() {
	// didf does not have a avr_f64 counterpart, 
	// so we can only check, whether the result
	// is similar, if the calculations would be done
	// in float64_t - and we have to check the 
	// output manually
	Serial.print(F("--------- check fp64_uint64_to_float64  ---------"));
	
	unsigned long long x = 0ULL;
	float64_t res2 = float64_NUMBER_PLUS_ZERO;
	struct fp64_debug_t* xd = __fp64_debugAB();
	for( int i = 0; i < 248; i++ ) {
		Serial.print( i );
		Serial.println(":");
		float64_t res = fp64_uint64_to_float64( x );
		dump_debug( xd );
		dumpLong( (uint8_t*) &x, "x:" );
		Serial.print( convertULL(x) );
		Serial.println();
		ddump( res );
		ddump( res2 );
		check_diff( res, res2 );
		Serial.println( F("fp64_uint64_to_float64") );
		Serial.println();
		x = x + 1ULL;
		res2 = f_add( res2, float64_NUMBER_ONE );
		if( i % 4 == 3 ) {
			x = x << 1;
			res2 = f_mult( res2, f_NUMBER_2);
		}
	}
}

void check_unsidf() {
	// sidf does not have a avr_f64 counterpart, 
	// so we can only check, whether the result
	// is similar, if the calculations would be done
	// in float64_t - and we have to check the 
	// output manually
	Serial.print(F("--------- check fp64_uint32_to_float64  ---------"));
	
	unsigned long  x = 0UL;
	float64_t res2 = float64_NUMBER_PLUS_ZERO;
	struct fp64_debug_t* xd = __fp64_debugAB();
	for( int i = 0; i < 120; i++ ) {
		Serial.print( i );
		Serial.println(":");
		float64_t res = fp64_uint32_to_float64( x );
		dump_debug( xd );
		Serial.print( F("x: 0x") );
		Serial.print( x, HEX );
		Serial.print( F(" ") );
		Serial.println( x );
		ddump( res );
		ddump( res2 );
		check_diff( res, res2 );
		Serial.println( F("fp64_uint32_to_float64") );
		Serial.println();
		x++;
		res2 = f_add( res2, float64_NUMBER_ONE );
		if( i % 4 == 3 ) {
			x = x << 1;
			res2 = f_mult( res2, f_NUMBER_2);
		}
	}
}

void check_conv() {
	check_sd();
	check_didf();
	check_uint64_to_float64();
	check_sidf();
	check_unsidf();
	check_sssd_core(1);
	check_sssd_core(-1);
}
#endif

#ifdef CHECK_TRIG
void check_trig_values( f1ptr f, f1ptr fexp, const char *s ) {

	for( int i = 0; i < size_trig_vals; i++ ) {
	// for( int i = 0; i < 7; i++ ) {
		Serial.print( i );
		Serial.println(F(": special value"));
		float64_t x = get_check_trig_vals(i);
		float64_t res2 = (*fexp)( x );
		ddump( res2 );
		if( fp64_isfinite(x) ) {
			float64_t q = fp64_div(x,float64_NUMBER_PIO2);
			ddump( q );
			// float64_t r = fp64_fmod(x,float64_NUMBER_PIO2);
			// ddump( r );
			// float64_t r2 = f_mod(x,float64_NUMBER_PIO2,NULL);
			// ddump( r2 );
		}
		check_fop1(x, f, s, res2 );
		Serial.println();
	}
	Serial.println();
}

void check_trig_sequence( f1ptr f, f1ptr fexp, const char *s, bool goNegative ) {
	float64_t x, phi;

	x = fp64_mul( float64_NUMBER_PI, f_NUMBER_2 );
	phi = fp64_div( x, f_NUMBER_256 );
	x = fp64_sub( fp64_neg(x), phi );
	// phi = fp64_div( float64_NUMBER_PI, f_NUMBER_6 );
	ddump( phi );
	Serial.println();
	for( int i = -256-1; i < 256+2; i++ ) {
	// for( int i = -12; i < 13; i++ ) {
		Serial.println( goNegative ? -i : i);
		if( fp64_isfinite(x) ) {
			float64_t q = fp64_div(x,float64_NUMBER_PIO2);
			ddump( q );
			// float64_t r = fp64_fmod(x,float64_NUMBER_PIO2);
			// ddump( r );
			// float64_t r2 = f_mod(x,float64_NUMBER_PIO2,NULL);
			// ddump( r2 );
		}
		check_fop1(x, f, s, (*fexp)( x ) );
		Serial.println();
		if( goNegative )
			x = fp64_sub( x, phi );
		else
			x = fp64_add( x, phi );
	}
}

void check_trig_sequence2( f1ptr f, f1ptr fexp, const char *s) {
	float64_t x, phi;

	phi = fp64_div( float64_NUMBER_ONE, f_NUMBER_256 );
	phi = f_NUMBER_01;
	ddump( phi );
	Serial.println();
	x = fp64_sub( float64_MINUS_NUMBER_ONE, phi );
	// for( int i = -256-1; i < 256+2; i++ ) {
	for( int i = -11; i < 12; i++ ) {
		Serial.println(i);
		check_fop1(x, f, s, (*fexp)( x ) );
		Serial.println();
		x = fp64_add( x, phi );
	}
}

void check_trig_all( f1ptr f, f1ptr fexp, const char *s, bool isArc ) {
#ifdef WITH_TIMING
	float64_t phi;
	char s2[18] = "f_";
#endif
	
	Serial.print(F("--------- check ")); Serial.print( s ); Serial.println(F(" ---------"));
	check_trig_values( f, fexp, s );
	if( isArc )
		check_trig_sequence2( f, fexp, s);
	else {
		check_trig_sequence( f, fexp, s, false );
		// check_trig_sequence( f, fexp, s, true );
	}

#ifdef WITH_TIMING
	Serial.print(F("--------- timing ")); Serial.print( s ); Serial.println(F(" ---------"));
	phi = isArc ? f_NUMBER_0_5 : fp64_div( float64_NUMBER_PI, f_NUMBER_6);
	timeIt1( phi, f, s, true);
	strcat( s2, s+5 );		// build f_xxxx out of fp64_xxxx
	timeIt1( phi, fexp, s2, false);
	
	phi = isArc ? fp64_inverse(fp64_sqrt(f_NUMBER_2)) : fp64_div( float64_NUMBER_2PI, f_NUMBER_6);
	timeIt1( phi, f, s, true);
	strcat( s2, "1" );		// build f_xxxx out of fp64_xxxx
	timeIt1( phi, fexp, s2, false);

	phi = f_NUMBER_100;
	timeIt1( phi, f, s, true);
	strcat( s2, "2" );		// build f_xxxx out of fp64_xxxx
	timeIt1( phi, fexp, s2, false);
#endif
}

// needed for timings as f_sin is a macro and not a function
float64_t my_fsin(float64_t x) {
	return f_sin(x);
}

void check_sin() {
	check_trig_all( fp64_sin, my_fsin, "fp64_sin", false );
}

// needed for timings as f_cos is a macro and not a function
float64_t my_fcos(float64_t x) {
	return f_cos(x);
}
void check_cos() {
	check_trig_all( fp64_cos, my_fcos, "fp64_cos", false );
}

// needed for timings as f_tan is a macro and not a function
float64_t my_ftan(float64_t x) {
	return f_tan(x);
}
void check_tan() {
	check_trig_all( fp64_tan, my_ftan, "fp64_tan", false );
}

// needed for timings as f_tan is a macro and not a function
float64_t my_fatan(float64_t x) {
	return f_arctan(x);
}
void check_atan() {
	check_trig_all( fp64_atan, my_fatan, "fp64_atan", false );
}

// needed for timings as f_tan is a macro and not a function
float64_t my_fasin(float64_t x) {
	return f_arcsin(x);
}

void check_asin() {
	check_trig_all( fp64_asin, my_fasin, "fp64_asin", true );
}

// needed for timings as f_acos is a macro and not a function
float64_t my_facos(float64_t x) {
	return f_arccos(x);
}
void check_acos() {
	check_trig_all( fp64_acos, my_facos, "fp64_acos", true );
}

float64_t my_inv(float64_t x) {
	return( x );
}

float64_t fp_invsin(float64_t x) {
	return(fp64_asin(fp64_sin(x)));
}

float64_t fp_invcos(float64_t x) {
	return(fp64_acos(fp64_cos(x)));
}

float64_t fp_invtan(float64_t x) {
	return(fp64_atan(fp64_tan(x)));
}

void check_inv() {
	check_trig_all( fp_invsin, my_inv, "fp64_asin(sin)", true );
	check_trig_all( fp_invcos, my_inv, "fp64_acos(cos)", true );
	check_trig_all( fp_invtan, my_inv, "fp64_atan(tan)", true );
}

void check_trig() {
	// check_sin();
	check_tan();
	// check_asin();
	// check_acos();
	check_atan();
	// check_cos();
	// check_inv();
}
#endif

#ifdef CHECK_POWSER
float64_t my_powser( float64_t x, int maxPow ) {
	float64_t res = f_div( x, f_long_to_float64( (long) ((maxPow % 2 == 0) ? -maxPow : maxPow) ) );
	dump( x, "x avr" );
	ddump( res );
	for( int i = maxPow-1; i > 0; i-- ) {
		float64_t ci = f_div( float64_NUMBER_ONE, f_long_to_float64( (long) i ) );
		ddump( ci );
		if( i % 2 == 0 ) {
			res = f_sub( res, ci );
			dump( res, "res-ci" );
		} else {
			res = f_add( res, ci );
			dump( res, "res+ci" );
		}
		res = f_mult( res, x );
		dump( res, "res*x" );
	}
	return( res );
}

float64_t my_fp64powser( float64_t x, int maxPow ) {
	float64_t res = fp64_div( x, f_long_to_float64( (long) ((maxPow % 2 == 0) ? -maxPow : maxPow) ) );
	dump( x, "x fp64" );
	for( int i = maxPow-1; i > 0; i-- ) {
		float64_t ci = fp64_div( float64_NUMBER_ONE, f_long_to_float64( (long) i ) );
		ddump( ci );
		if( i % 2 == 0 ) {
			res = fp64_sub( res, ci );
			dump( res, "res-ci" );
		} else {
			res = fp64_add( res, ci );
			dump( res, "res+ci" );
		}
		res = fp64_mul( res, x );
		dump( res, "res*x" );
	}
	return( res );
}

void check_powser1() {
	float64_t res, x, phi;
	f1ptr farr[3] = { __fp64_check_powser1, __fp64_check_powser2, __fp64_check_powser3 };
	f1ptr f;
	
	// extern uint8_t* __fp64_saveZ;

	Serial.println(F("--------- check __fp64_powser ---------"));
	struct fp64_debug_t* xd = __fp64_debugAB();
	for( int j = 1; j < 4; j++ ) {
		Serial.print(F("--- polynom of power ") ); Serial.println(j);
		phi = f_NUMBER_0_125;
		ddump( phi );
		Serial.println();
		x = f_MINUS_NUMBER_2_5;
		f = farr[j-1];
		for( int i = -20; i < 21; i++ ) {
			Serial.println(i);
			res = (*f)( x );
			dump_debug( xd );
			dump_debug( xd+1 );
			ddump( res );
			check_fop1(x, f, "__fp64_powser vs my_powser", my_powser(x, j) );
			check_fop1(x, f, "__fp64_powser vs my_fp64powser", my_fp64powser(x, j) );
			Serial.println();
			x = fp64_add( x, phi );
			Serial.println();
		}
	}
}


float64_t my_powsodd( float64_t x, int maxPow ) {
	float64_t x2 = f_mult( x, x );
	float64_t res = my_powser( x2, maxPow );
	res = f_mult( res, x );
	return( res );
}

void check_powsodd() {
	float64_t x, phi;

	Serial.println(F("--------- check __fp64_powsodd ---------"));
	struct fp64_debug_t* xd = __fp64_debugAB();
	phi = f_NUMBER_0_125;
	ddump( phi );
	Serial.println();
	x = f_MINUS_NUMBER_2_5;
	for( int i = -20; i < 21; i++ ) {
		Serial.println(i);
		__fp64_check_powsodd3( x );
		dump_debug( xd );
		dump_debug( xd+1 );
		check_fop1(x, __fp64_check_powsodd3, "__fp64_powsodd3", my_powsodd(x, 3) );
		//check_fop1(x, f, "__fp64_powser", my_fp64powser(x, 3) );
		Serial.println();
		x = fp64_add( x, phi );
		Serial.println();
	}
}

float64_t my_powserlog( float64_t x, int maxPow ) {
	float64_t res = f_div( f_NUMBER_2, f_long_to_float64( (long) (maxPow*2+1) ) );
	dump( x, "x" );
	dump( res, "ci" );
	for( int i = maxPow-1; i >= 0; i-- ) {
		res = f_mult( res, x );
		// dump( res, "res*x" );

		float64_t ci = f_div( f_NUMBER_2, f_long_to_float64( (long) (i*2+1) ) );
		// ddump( ci );

		res = f_add( res, ci );
		// dump( res, "res+ci" );
	}
	return( res );
}

float64_t my_powsoddlog( float64_t x, int maxPow ) {
	float64_t x2 = f_mult( x, x );
	float64_t res = my_powserlog( x2, maxPow );
	res = f_mult( res, x );
	dump( res, "res*x" );
	return( res );
}

float64_t my_fp64log( float64_t x, int maxPow ) {
	float64_t y1 = fp64_add( x, float64_NUMBER_ONE );
	ddump( y1 );
	float64_t y2 = fp64_sub( x, float64_NUMBER_ONE );
	ddump( y2 );
	float64_t y = fp64_div( y2, y1 );
	ddump( y );
	return( my_powsoddlog( y, maxPow ) );
}

float64_t my_fp64log2( float64_t x ) {
	float64_t y1 = f_add( x, float64_NUMBER_ONE );
	dump( y1, "y1=x+1" );
	float64_t y2 = f_sub( x, float64_NUMBER_ONE );
	dump( y2, "y2=x-1" );
	float64_t y = fp64_div( y2, y1 );
	dump( y, "y=(x-1)/(x+1)" );
	return( __fp64_check_powslog( y ) );
}

void check_powser2() {
	float64_t res, x, phi;
	Serial.println(F("--------- check __fp64_powser2 ---------"));
	phi = f_NUMBER_0_125;
	ddump( phi );
	Serial.println();
	x = f_NUMBER_0_5;
	// float64_t x2 = f_add( x, float64_NUMBER_ONE );
	for( int j = 1; j < 20; j++ ) {
		Serial.println(j);
		res = my_fp64log( x, j );
		float64_t res2 = f_log( x );
		ddump( res );
		ddump( res2 );
		check_diff( res, res2 );
		Serial.println();
		Serial.println();
	}
}

void check_powslog() {
	float64_t res, x, phi;

	Serial.println(F("--------- check check_powslog ---------"));
	struct fp64_debug_t* xd = __fp64_debugAB();
	phi = f_NUMBER_0_125;
	ddump( phi );
	ddump( f_log(f_NUMBER_2) );
	Serial.println();
	x = phi;
	for( int i = 0; i < 11; i++ ) {
		Serial.println(i);
		res = my_fp64log2( x );
		dump_debug( xd );
		dump_debug( xd+1 );
		ddump( res );
		check_fop1(x, my_fp64log2, "__fp64_powslog", f_log(x) );
		Serial.println();
		check_fop1(x, my_fp64log2, "__fp64_powslog", my_fp64log(x, 16) );
		Serial.println();
		x = fp64_add( x, phi );
		Serial.println();
	}
}

float64_t my_fp64powser17( float64_t x ) {
	return my_powserexp(x, 17);
}

void check_powserexp() {
	float64_t res, x, phi, exp_res;

	Serial.println(F("--------- check my_powserexp ---------"));
	// x = float64_NUMBER_ONE;
	// for( int i = 14; i < 21; i++ ) {
		// Serial.println(i);
		// check_fop1(x, __fp64_check_powserexp, "my_powserexp", my_powserexp(x, i) );
		// check_fop1(x, __fp64_check_powserexp, "__fp64_check_powserexp", f_EULER_E );
		// Serial.println();
	// }

	struct fp64_debug_t* xd = __fp64_debugAB();
	phi = f_NUMBER_0_125;
	ddump( phi );
	Serial.println();
	x = f_MINUS_NUMBER_2_5;
	for( int i = -20; i < 21; i++ ) {
		Serial.println(i);
		ddump(x);
		exp_res = my_powserexp(x, 17);
		ddump( exp_res );
		res = __fp64_check_powserexp( x );
		dump_debug( xd );
		dump_debug( xd+1 );
		ddump( res );
		check_fop1(x, __fp64_check_powserexp, "__fp64_check_powserexp", exp_res );
		//check_fop1(x, f, "__fp64_powser", my_fp64powser(x, 3) );
		Serial.println();
		x = fp64_add( x, phi );
		Serial.println();
	}
	
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_powser ---------"));
	phi = float64_NUMBER_ONE;
	timeIt1( phi, __fp64_check_powserexp, "__fp64_check_powserexp", true);
	timeIt1( phi, my_fp64powser17, "my_fp64powser17" , false);
	Serial.println();
	
	phi = f_MINUS_NUMBER_2;
	timeIt1( phi, __fp64_check_powserexp, "__fp64_check_powserexp", true);
	timeIt1( phi, my_fp64powser17, "my_fp64powser17" , false);
	Serial.println();
#endif
}

void check_powser() {
	check_powser1();
	check_powsodd();
	check_powser2();
	check_powserexp();
	check_powslog();
}
#endif

#ifdef CHECK_LOG
void check_ln_core(f1ptr f, f1ptr fexp, const char *s ) {
	float64_t res2, x, phi;

	Serial.print(F("--------- check ")); Serial.print( s ); Serial.println(F(" ---------"));
	for( int i = 0; i < size_trig_vals; i++ ) {
	// for( int i = 0; i < 7; i++ ) {
		Serial.print( i );
		Serial.println(F(": special value"));
		float64_t x = get_check_trig_vals(i);
		float64_t res2 = (*fexp)( x );
		// ddump( res2 );
		check_fop1(x, f, s, res2 );
		Serial.println();
	}
	Serial.println();

	phi = f_NUMBER_01;
	ddump( phi );
	ddump( (*fexp)(f_NUMBER_2) );
	Serial.println();
	x = float64_NUMBER_ONE;
	for( int i = 0; i < 21; i++ ) {
		Serial.println(i);
		check_fop1(x, f, s, (*fexp)(x) );
		Serial.println();
		x = fp64_add( x, phi );
		Serial.println();
	}

	phi = f_NUMBER_01;
	ddump( phi );
	dump( (*fexp)(f_NUMBER_2), "f_log(2)" );
	Serial.println();
	x = f_NUMBER_100;
	for( int i = 0; i < 161; i++ ) {
		Serial.println(i);
		check_fop1(x, f, s, (*fexp)(x) );
		Serial.println();
		x = fp64_add( x, phi );
		Serial.println();
	}

	// check subnormal numbers
	x = 0x0058000000000000LLU;
	res2 = (*fexp)(x);
	phi = (*fexp)(f_NUMBER_2);
	ddump( phi );
	for( int i = 0; i < 4+52; i++ ) {
		Serial.print(i);
		Serial.println(F(": subnormal value"));
		check_fop1(x, f, s, res2 );
		Serial.println();
		x = fp64_mul( x, f_NUMBER_0_5 );
		res2 = fp64_sub( res2, phi );
		Serial.println();
	}
	
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_log ---------"));
	phi = float64_NUMBER_PI;;
	timeIt1( phi, f, s, true);
	timeIt1( phi, (*fexp), "f_log" , false);
	Serial.println();
	
	phi = f_NUMBER_001;
	timeIt1( phi, f, s, true);
	timeIt1( phi, (*fexp), "f_log" , false);
	Serial.println();

	phi = f_NUMBER_100;
	timeIt1( phi, f, s, true);
	timeIt1( phi, (*fexp), "f_log" , false);
	Serial.println();
#endif
}

void check_ln() {
	check_ln_core( fp64_log, f_log, "fp64_log" );
}

float64_t my_log10( float64_t x ) {
	return( f_mult( f_log(x), 0x3fdbcb7b1526e50dLLU ) );
}

void check_log10() {
	float64_t res2, x, phi;

	Serial.println(F("--------- check fp64_log10 ---------"));
	for( int i = 0; i < size_trig_vals; i++ ) {
	// for( int i = 0; i < 1; i++ ) {
		Serial.print( i );
		Serial.println(F(": special value"));
		float64_t x = get_check_trig_vals(i);
		check_fop1(x, fp64_log10, "fp64_log10", my_log10( x ) );
		Serial.println();
	}
	Serial.println();

	phi = f_NUMBER_01;
	ddump( phi );
	dump( my_log10(f_NUMBER_2), "my_log10(2)" );
	Serial.println();
	x = float64_NUMBER_ONE;
	for( int i = 0; i < 21; i++ ) {
		Serial.println(i);
		check_fop1(x, fp64_log10, "fp64_log10", my_log10(x) );
		Serial.println();
		x = fp64_add( x, phi );
		Serial.println();
	}

	phi = f_NUMBER_01;
	ddump( phi );
	dump( my_log10(f_NUMBER_2), "my_log10(2)" );
	Serial.println();
	x = f_NUMBER_100;
	for( int i = 0; i < 161; i++ ) {
		Serial.println(i);
		check_fop1(x, fp64_log10, "fp64_log10", my_log10(x) );
		Serial.println();
		x = fp64_add( x, phi );
		Serial.println();
	}

	// check subnormal numbers
	x = 0x0058000000000000LLU;
	res2 = my_log10(x);
	phi = my_log10(f_NUMBER_2);
	ddump( phi );
	for( int i = 0; i < 4+52; i++ ) {
		Serial.print(i);
		Serial.println(F(": subnormal value"));
		check_fop1(x, fp64_log10, "fp64_log10", res2 );
		Serial.println();
		x = fp64_mul( x, f_NUMBER_0_5 );
		res2 = fp64_sub( res2, phi );
		Serial.println();
	}
	
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_log10 ---------"));
	phi = float64_NUMBER_PI;;
	timeIt1( phi, fp64_log10, "fp64_log10", true);
	timeIt1( phi, my_log10, "my_log10" , false);
	Serial.println();
	
	phi = f_NUMBER_001;
	timeIt1( phi, fp64_log10, "fp64_log10", true);
	timeIt1( phi, my_log10, "my_log10" , false);
	Serial.println();

	phi = f_NUMBER_100;
	timeIt1( phi, fp64_log10, "fp64_log10", true);
	timeIt1( phi, my_log10, "my_log10" , false);
	Serial.println();
#endif
}

void check_log() {
	check_ln();
	check_log10();
}
#endif

#if defined(CHECK_POWSER) || defined(CHECK_EXP)
float64_t my_powserexp( float64_t x, int maxPow ) {
	float64_t ci = float64_NUMBER_ONE;
	for( int i = 2; i < maxPow; i++ ) {
		ci = fp64_mul( ci, f_long_to_float64( (long) i ) );
	}
	ci = fp64_inverse(ci);
	float64_t res = float64_NUMBER_PLUS_ZERO;
	// ddump( x );
	// ddump( res );
	for( int i = maxPow-1; i > 0; i-- ) {
		// ddump( ci );

		res = fp64_add( res, ci );
		// dump( res, "res+ci" );

		res = fp64_mul( res, x );
		// dump( res, "res*x" );
		ci = fp64_mul( ci, f_long_to_float64( (long) i ) );
	}
	res = fp64_add( res, float64_NUMBER_ONE );
	// ddump( res );
	return( res );
}
#endif 

#ifdef CHECK_EXP
float64_t my_exp10( float64_t x ) {
	float64_t res = f_pow( f_NUMBER_10, x );
	return res;
}

void check_exp10() {
	float64_t res, res2, x, phi;

	Serial.println(F("--------- check fp64_exp10  ---------"));
	struct fp64_debug_t* xd = __fp64_debugAB();
	dump_debug( xd );
	Serial.println( (unsigned int) xd, HEX );
	for( int i = 0; i < size_trig_vals; i++ ) {
	// for( int i = 0; i < 1; i++ ) {
		Serial.print( i );
		Serial.println(F(": special value"));
		x = get_check_trig_vals(i);
		res = fp64_exp10( x );
		dump_debug( xd );
		dump_debug( xd+1 );
		res2 = my_exp10( x );
		check_fop1(x, fp64_exp10 , "fp64_exp10 ", res2 );
		Serial.println();
	}
	
	x = float64_NUMBER_PLUS_ZERO;
	for( int8_t i = 0; i < 19; i++ ) {
		for( int8_t j = 1; j > -3; j-=2 ) {
		   Serial.print( i*j );
		   Serial.println(F(": range"));
		   res = fp64_exp10( x );
		   dump_debug( xd );
		   dump_debug( xd+1 );
		   res2 = my_exp10( x );
		   check_fop1(x, fp64_exp10 , "fp64_exp10 ", res2 );
		   Serial.println();
		   x = fp64_neg(x);
		}
		x = f_add( x, float64_NUMBER_ONE );
	}
	
	x = f_long_to_float64(305);
	for( int i = 305; i < 325; i++ ) {
		for( int8_t j = 1; j > -3; j-=2 ) {
		   Serial.print( i*j );
		   Serial.println(F(": overflow/underflow"));
		   res = fp64_exp10( x );
		   dump_debug( xd );
		   dump_debug( xd+1 );
		   res2 = my_exp10( x );
		   check_fop1(x, fp64_exp10 , "fp64_exp10 ", res2 );
		   Serial.println();
		   x = fp64_neg(x);
		}
		x = f_add( x, float64_NUMBER_ONE );
	}
	
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_exp10 ---------"));
	phi = float64_NUMBER_PI;;
	timeIt1( phi, fp64_exp10, "fp64_exp10", true);
	timeIt1( phi, my_exp10, "my_exp10" , false);
	Serial.println();
	
	phi = f_MINUS_NUMBER_2;
	timeIt1( phi, fp64_exp10, "fp64_exp10", true);
	timeIt1( phi, my_exp10, "my_exp10" , false);
	Serial.println();

	phi = f_NUMBER_100;
	timeIt1( phi, fp64_exp10, "fp64_exp10", true);
	timeIt1( phi, my_exp10, "my_exp10" , false);
	Serial.println();
#endif 
}

void check_expe() {
	float64_t res, res2, x, phi;
	x = float64_NUMBER_ONE;
	for( int i = 2; i < 18; i++ ) {
		x = fp64_mul( x, f_long_to_float64( (long) i ) );
		res = fp64_inverse( x );
		Serial.println( i );
		ddump( res );
		ddump( x );
	}

	Serial.println(F("--------- check fp64_exp  ---------"));
	struct fp64_debug_t* xd = __fp64_debugAB();
	dump_debug( xd );
	Serial.println( (unsigned int) xd, HEX );
	for( int i = 0; i < size_trig_vals; i++ ) {
	// for( int i = 0; i < 1; i++ ) {
		Serial.print( i );
		Serial.println(F(": special value"));
		x = get_check_trig_vals(i);
		res = fp64_exp( x );
		dump_debug( xd );
		dump_debug( xd+1 );
		res2 = f_exp( x );
		check_fop1(x, fp64_exp , "fp64_exp ", res2 );
		Serial.println();
	}
	
	Serial.println();
	phi = f_log( f_NUMBER_2 );
	// x = f_long_to_float64( (long) -745 );
	// check_fop1(x, fp64_exp , "fp64_exp ", f_log(x) );
	// for( int i = -52; i < 2; i++ ) {
	x = (float64_t) 0xC086232BDD7ABCD2LLU; // -708.3964185322640787489945068955421447754
	check_fop1(x, fp64_exp , "fp64_exp ", f_exp(x) );
	for( int i = 0; i > -54; i-- ) {
		Serial.print( i );
		Serial.println(F(": subnormal check"));
		res = fp64_exp( x );
		// dump_debug( xd );
		// dump_debug( xd+1 );
		Serial.println();
		if( i < 0 )				 
			res2 = (float64_t)(0x00080000000000BALLU >> (-i-1));
			// res2 = (float64_t)(0x000923D731D37621LLU >> (-i-1));
			// res2 = (float64_t)(0x000923D731D3779ALLU >> (-i-1));
		else
			res2 = f_exp( x );
		check_fop1(x, fp64_exp , "fp64_exp ", res2 );
		Serial.println();

		x = fp64_sub( x, phi );
	}
	Serial.println();

#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_exp ---------"));
	phi = float64_NUMBER_PI;;
	timeIt1( phi, fp64_exp, "fp64_exp", true);
	timeIt1( phi, f_exp, "f_exp" , false);
	Serial.println();
	
	phi = f_MINUS_NUMBER_2;
	timeIt1( phi, fp64_exp, "fp64_exp", true);
	timeIt1( phi, f_exp, "f_exp" , false);
	Serial.println();

	phi = f_NUMBER_100;
	timeIt1( phi, fp64_exp, "fp64_exp", true);
	timeIt1( phi, f_exp, "f_exp" , false);
	Serial.println();
#endif 
}

void check_exp() {
	// check_expe();
	check_exp10();
}
#endif

#ifdef CHECK_10POWN
extern "C" { 
int16_t f_10HochN(int64_t n, uint64_t *res);
uint64_t approx_high_uint64_word_of_uint64_mult_uint64(uint64_t *x, uint64_t *y, uint8_t signed_mult);
int8_t f_shift_left_until_bit63_set(uint64_t *w);
void f_split64(float64_t *x, uint8_t * f_sign, int16_t * f_ex, 
						uint64_t *frac, uint8_t lshift);
}

void check_pown() {
	float64_t res, res2, pot, r;
	int16_t x, x2;
		
	Serial.println(F("--------- check __fp64_domul64AB  ---------"));
	// for i = 29 & 30 approx_high_uint64_word_of_uint64_mult_uint64() does not
	// correctly round, i.e. 0x813F 3978 F894 0984 * 0xA = 0x5 0C78 3EB9 B5C8 5F28
	// which is truncated to 0x50C783EB9B5C85F2
	// _fp64_domul64AB does correct rounding to 0x50C7 83EB 9B5C 85F3
	pot = ((uint64_t)10)<<60; //0xa000000000000000LLU;
	res2 = 0x8000000000000000LLU;
	for( int i = 1; i < 31; i++ ) {
		res = res2;
		res = __fp64_domul64AB( res, pot );
		res2 = approx_high_uint64_word_of_uint64_mult_uint64(&res2, &pot, 0);
		Serial.println( i );
		ddump( res );
		ddump( res2 );
		check_diff( res, res2 );
		Serial.println();
		f_shift_left_until_bit63_set( &res );
		f_shift_left_until_bit63_set( &res2 );
		ddump( res );
		ddump( res2 );
		check_diff( res, res2 );
		Serial.println();
		Serial.println();
	}
		
	Serial.println( (uint16_t) &x2, HEX );
	float64_t ctl1 = float64_NUMBER_ONE; // powers of 10
	float64_t ctl2 = float64_NUMBER_ONE; // powers of 1/10
	volatile float64_t ctl_10_pow_10 = float64_NUMBER_ONE;
	for( int i = 0; i < 10; i++ )
		ctl_10_pow_10 = fp64_mul( ctl_10_pow_10, f_NUMBER_10 );
	ddump( ctl_10_pow_10 ); // 10^10
	
	Serial.println(F("--------- check fp64_10pown  ---------"));
	struct fp64_debug_t* xd = __fp64_debugAB();
	// for( int i = -300; i < 311; ) {
	for( int i = 0; i < 311; ) {
	// for( int i = 1; i < 311;  i += i ) {
		uint8_t f_sign;
		int16_t f_ex;
		uint64_t frac;
		// two passes for +i and -i
		for( int j = 0; j < 2; j++ ) {
			Serial.println( i );
		
			x = 0x1234; // magic value to check whether base 2 exponent was returned
			res = fp64_10pown( i, &x );
			dump_debug( xd );
			dump_debug( xd+1 );
			if( i >= 0 ) {
				ddump( ctl1 );
				f_split64(&ctl1, &f_sign, &f_ex, &frac, 11);
			} else {
				ddump( ctl2 );
				f_split64(&ctl2, &f_sign, &f_ex, &frac, 11);
			}
			ddump( frac );
			ddump( res );

			x2 = f_10HochN( (int64_t) i, &res2);
			ddump( res2 );
			
			check_diff( res, res2 );
			Serial.println();
	
			check( x == x2 );
			Serial.print( x );
			Serial.print(F(" "));
			Serial.println( x2 );
			Serial.println();
			i = -i;
		}
		if( i < -20 || (i > 50 && i < 250 )  || (i > 260 && i < 300) ) {
			i += 10;
			ctl1 = fp64_mul( ctl1, ctl_10_pow_10 );
			ctl2 = fp64_div( ctl2, ctl_10_pow_10 );
			ddump( ctl2 ); // 10^-i
		} else {
			i++;
			ctl1 = fp64_mul( ctl1, f_NUMBER_10 );
			ctl2 = fp64_mul( ctl2, f_NUMBER_01 );
		}
	}	
}

#endif

#ifdef CHECK_FTOA
void check_ftoa() {
	struct ftoa_table1_t entry;
	float64_t r;

	Serial.println(F("--------- check fp64_to_decimalExp ---------"));
	struct fp64_debug_t* xd = __fp64_debugAB();
	// for( int i = 26; i < ftoa_table1_size; i++ ) {
	for( int i = 0; i < 100; i++ ) {
		// ddump( ftoa_table1[i].x );
		// float64_t r = ftoa_table1[i].x;
		// memcpy_P( &r, &ftoa_table1[i].x, sizeof(r) );
		// get either a pre-selected number or create a random number
		if( i < ftoa_table1_size ) {
			memcpy_P( &entry, &ftoa_table1[i], sizeof(entry) );
		} else {
			entry.x = createRandom();
			entry.isSubnormal = (((entry.x >> 48) & 0x7fff) < 0x0001 );
		}
			
		r = entry.x;
		for( int prec = 17; prec > ((i > ftoa_table1_size) ? 16 : 0); prec-- ) {
			int16_t exp, exp2;
			Serial.print( i );
			Serial.print(F(": prec:"));
			Serial.println(prec);
			ddump( r );
			exp = exp2 = 999;
			char *res = fp64_to_decimalExp( r, (uint8_t) prec, false, &exp );
			// Serial.println( (uint16_t) &exp, HEX );
			Serial.print( "res  = |" ); Serial.print( res ); Serial.println("|");
			char *res2 = f_to_decimalExp( r, (uint8_t) prec, false, &exp2 );
			Serial.print( "res2 = |" ); Serial.print( res2 ); Serial.println("|");
			dump_debug( xd );
			dump_debug( xd+1 );
			hexDump( res-4, 25+4 );
			if( entry.isSubnormal ) {
				check( true );
				Serial.print(F(" OVERRIDE subnormal "));
				Serial.print( strcmp(res, res2 ) );
			} else {
				if( exp == exp2 ) {
					check( exp == exp2 );
				} else if( exp2 == 999 ) {
					check( true );
					Serial.print( F("OVERRIDE as avr does not set exp ") );
				} else
					check( exp == exp2 );
				Serial.print( F("exp: " ) ); Serial.print( exp ); 
				Serial.print( " " );Serial.print( exp2 ); Serial.println( F(" fp64_to_decimalExp") );
				check( strcmp(res, res2 ) == 0 );
				Serial.print( strcmp(res, res2 ) );
			}
			Serial.println( F("fp64_to_decimalExp") );
		}
		Serial.println();
		Serial.println();
	}

#ifdef WITH_TIMING	
	// time conversion to string, 
	// cannot use timeIt operations as result are strings
	unsigned long start;
	for( int i = 12; i < ftoa_table1_size; i += 6 ) {
		memcpy_P( &entry, &ftoa_table1[i], sizeof(entry) );
		r = entry.x;
		uint8_t prec = 17;
		for( int j = 0; j < 2; j++ ) {
			start = micros();
			for( int i = 0; i < 1000; i++ ) {
					char *res = fp64_to_decimalExp( r, prec, false, NULL );
			}
			timeItCommon( r, "fp64_to_decimalExp", true, micros() - start );
			start = micros();
			for( int i = 0; i < 1000; i++ ) {
					char *res2 = f_to_decimalExp( r, prec, false, NULL );
			}
			timeItCommon( r, "fp64_to_decimalExp", false, micros() - start );
			r = f_div( float64_MINUS_NUMBER_ONE, r );
		}
	}
#endif 
}
#endif

#ifdef CHECK_ATOF
void check_atof() {
	struct ftoa_table1_t entry;
	struct atof_table1_t entry2;
	float64_t r, res, res2, d1, d2;
	char *endp1, *endp2;
	char str[32];
	char str1[] = "fp64";
	char str2[] = "avr";

	Serial.println(F("--------- check __fp64_atof ---------"));
	struct fp64_debug_t* xd = __fp64_debugAB();
	// first check some special case that will not return a valid number
	for( int i = 0; i < atof_table1_size; i++ ) {
		Serial.println( i );
		memcpy_P( &entry2, &atof_table1[i], sizeof(entry) );
		const char *s = entry2.s;
		if( s )
			strcpy( str, s );
		Serial.print( "s = |" ); Serial.print( s ); Serial.print("|"); Serial.println( (uint16_t) &str, HEX );
		endp1 = str1;
		endp2 = str2;
		res = fp64_strtod( s ? str : NULL, &endp1 );
		dump_debug( xd );
		dump_debug( xd+1 );
		ddump( res );
		res2 = f_strtod( s ? str : NULL, &endp2 );
		ddump( res2 );
		check_diff( res, res2 );
		Serial.println( F("fp64_atof") );
		
		Serial.print( "endp1 @" ); Serial.print( (uint16_t) &endp1, HEX ); Serial.print( " = |" ); Serial.print( endp1 ); Serial.print("|"); Serial.println( (uint16_t) endp1, HEX );
		Serial.print( "endp2 @" ); Serial.print( (uint16_t) &endp2, HEX ); Serial.print( " = |" ); Serial.print( endp2 ); Serial.print("|"); Serial.println( (uint16_t) endp2, HEX );
		check( endp1 == endp2 );
		Serial.println( F("fp64_atof") );
		Serial.println();
	}	
	
	// for( int i = 0; i < ftoa_table1_size; i++ ) {
	for( int i = 0; i < 100; i++ ) {
		// get either a pre-selected number or create a random number
		if( i < ftoa_table1_size ) {
			memcpy_P( &entry, &ftoa_table1[i], sizeof(entry) );
		} else {
			entry.x = createRandom();
			entry.isSubnormal = isSubnormal( entry.x );
		}
			
		Serial.print( i );
		Serial.println(F(":"));
		r = entry.x;
		
		// two runs: first using avr_f64 string conversion, second with ours
		// to see different handling for subnormals
		char *s = f_to_string(r,(uint8_t)20,(uint8_t)2);
		for( int j = 0; j < 2; j++ ) {
			ddump( r );
			Serial.print( "s   = |" ); Serial.print( s ); Serial.println("|");
			strcpy( str, s );
			Serial.print( "str = |" ); Serial.print( str ); Serial.println("|");
			// hexDump( str, 25 ); Serial.println();
			endp1 = str1;
			endp2 = str2;
			res = fp64_strtod( str, &endp1 );
			dump_debug( xd );
			dump_debug( xd+1 );
			ddump( res );
			res2 = f_strtod( str, &endp2 );
			ddump( res2 );
			d1 = fp64_abs(fp64_sub( r, res ));
			d2 = fp64_abs(fp64_sub( r, res2 ));
			if( entry.isSubnormal ) {
				// avr_f64 cannot handle subnormals, so results cannot be compared
				check( true );	
				Serial.print(F(" subnormal fp64_atof"));
				ddump( d1 );
				if( j > 0 ) // check makes only sense when there was an input string != "0"
					check_diff( r, res );
			} else {
				if( res != res2 ) {
					// check which result is close to original value
					if( fp64_compare( d1, d2 ) < 0 ) {
						ddump(d1);
						ddump(d2);
						check( true );	
						Serial.print(F("OVERRIDE due to better approximation "));
					} else {
						check_diff( res, res2 ); 
					}
				} else {
					check_diff( res, res2 ); 
				}
			}
			Serial.println( F("fp64_atof") );

			Serial.print( "endp1 @" ); Serial.print( (uint16_t) &endp1, HEX ); Serial.print( " = |" ); Serial.print( endp1 ); Serial.print("|"); Serial.println( (uint16_t) endp1, HEX );
			Serial.print( "endp2 @" ); Serial.print( (uint16_t) &endp2, HEX ); Serial.print( " = |" ); Serial.print( endp2 ); Serial.print("|"); Serial.println( (uint16_t) endp2, HEX );
			check( endp1 == endp2 );
			Serial.println( F("fp64_atof") );
			// check_diff( r, res ); 
			// ddump( d1 );
			// check_diff( r, res2 );
			// ddump( d2 );
			Serial.println();
			s = fp64_to_decimalExp( r, (uint8_t) 17, false, NULL );
		}
	}
	
#ifdef WITH_TIMING
	// time conversion to string, 
	// cannot use timeIt operations as result are strings
	unsigned long start;
	for( int i = 12; i < ftoa_table1_size; i += 6 ) {
		memcpy_P( &entry, &ftoa_table1[i], sizeof(entry) );
		r = entry.x;
		for( int prec = 5; prec < 25; prec += 5 ) {
			char *s = f_to_string(r,(uint8_t)prec,(uint8_t)2);
			Serial.print( "s   = |" ); Serial.print( s ); Serial.println("|");
			strcpy( str, s );
			Serial.print( "str = |" ); Serial.print( str ); Serial.println("|");
			start = micros();
			for( int j = 0; j < 1000; j++ ) {
				res = fp64_strtod( str, &endp1 );
			}
			timeItCommon( res, "fp64_strtod", true, micros() - start );
			Serial.print( "str = |" ); Serial.print( str ); Serial.println("|");
			start = micros();
			for( int j = 0; j < 1000; j++ ) {
				res2 = f_strtod( str, &endp2 );
			}
			timeItCommon( res2, "fp64_strtod", false, micros() - start );
		}
	}
#endif
}
#endif

#ifdef CHECK_TOSTRING
char *my_to_string(float64_t x, uint8_t max_nr_chars, uint8_t max_leading_mantisse_zeros) {
	int8_t sign;
	int16_t exp10 = 0;
	char *s;
	uint8_t nrd;			// number of digits available
	uint8_t prec;			// precision for call to f_to_decimalExp
	uint8_t below1 = false;	// true if number will be formatted as "0.mmm"
	uint8_t above1 = false;	// true is number will be formatted as "mmm.mmm"
	uint8_t pos, endPos;	// endPos = end of significand, start of exponent
	
	sign = fp64_signbit( x );
	nrd = sign ? max_nr_chars-1 : max_nr_chars;
	s = fp64_to_decimalExp(x, 1, 0, &exp10); // just to get exponent
	Serial.println(s);
	Serial.print( "exp10: " ); Serial.println( exp10 );
	// detect NaN and Inf and 0
	if( s[0] == 'N' || s[0] == 'I' || s[1] == 'I' || x == 0 )
		return( s );
	int exp2 = ((x & 0x7ff0000000000000ULL) >> 52) - 0x3ff;
	Serial.print( "exp2: " ); Serial.println( exp2 );
	if( exp2 < 0 ) {
		// check whether number does not have too many leading 0
		if( -exp10 <= max_leading_mantisse_zeros ) {
			// number can be formatted as "0.mmmm" 
			prec = nrd + exp10 - 1;
			if( exp10 == 0 )
				prec--;
			below1 = true;
		}
	} else if( exp10 < nrd ) {
		// number does not have too many digits before "."
		if( exp10 == nrd - 1 )
			prec = nrd;
		else 
			prec = nrd - 1;
		above1 = true;
	}
	
	if( !(above1 || below1) ) {
		// no special case, format number as exponential
		uint8_t expDigits = (abs(exp10) < 10 ? 1 : (abs(exp10) < 100 ? 2 : 3));
		uint8_t minD = expDigits + 3; // +3 for at least 1 digit, "E" and exponent sign
		prec = (nrd < minD) ? 0 : nrd - minD;
	}
	
	// limit prec to senseful range, important to keep pointer safely in allocated area
	prec = (prec < 1) ? 1 : ((prec > 17) ? 17 : prec);
	Serial.print( " prec: 0x" ); Serial.println( prec, HEX );
	s = fp64_to_decimalExp(x, prec, 0, &exp10); // get number
	Serial.println(s);

	if( sign )
		s++;

	if( below1 && exp10 == 0 ) {
		// case 0.99999 got rounded to 1.0 --> we are no longer below 1
		below1 = false;
		above1 = true;
		prec--;
	}
	
	Serial.print( "exp10: 0x" ); Serial.print( exp10, HEX );
	Serial.print( " prec: 0x" ); Serial.print( prec, HEX );
	Serial.print( " nrd: 0x" ); Serial.print( nrd, HEX );
	Serial.print( " rFlags: 0x" ); Serial.print( (sign?0x80:0x00)+(above1?0x02:0x00)+(below1?0x01:0x00), HEX );
	Serial.println();

	if( below1 ) {
		// format number as "0.mmmm"
		// copy number downwards
		prec = nrd + exp10 - 1;
		if( prec > 17 )
			prec = 17;
		
		uint8_t zeroes = -(exp10+1);
		pos = prec - exp10;
		endPos = pos + 1;
		
		Serial.print( " prec: 0x" ); Serial.print( prec, HEX );
		Serial.print( " zeroes: 0x" ); Serial.print( zeroes, HEX );
		Serial.print( "   pos: 0x" ); Serial.print( pos, HEX );
		Serial.print( " endPos: 0x" ); Serial.print( endPos, HEX );
		Serial.print( " s[pos]: " ); Serial.print(s+pos);
		Serial.print( " s[endPos]: " ); Serial.println(s+endPos);

		// create continous stream of digits
		s[1] = s[0];
		for( ; prec > 0 ; )
			s[pos--] = s[prec--];
		// now fill up the zeroes
		for( ; zeroes > 0; zeroes-- )
			s[pos--] = '0';
		// add "0."
		s[pos--] = '.';
		s[pos--] = '0';
	} else if (above1 ) {
		// format number as "mmm.mmm"
		// input is "m.mmmmmmEeee" with prec digits before E
		// so we just have to move the "." to the right position
		pos = 1;	// start at "."
		endPos = pos + prec;
		
		for( int i = 0; i < exp10; i++ ) {
			s[pos] = s[pos+1];
			pos++;
		}
		// Serial.print("s:"); Serial.println(s);
		// now insert the ".", but only of the digits after "." still fit into max_nr_chars
		if( exp10 != prec - 1 ) {
			s[pos] = '.';
		} else {
			// digits after '.' do not fit in, so terminate the string one character earlier
			s[pos] = '\0';
			endPos = 0;		// no removing of trailing zeroes
		}
	} else {
		// remove trailing zeroes
		endPos = prec + 1;
		pos = endPos;
	}
	// remove trailing zeroes
	if( endPos ) {
		while( s[--endPos] == '0' )
			;
		if( s[endPos] == '.' )
			endPos--;
		if( below1 || above1 )
			s[++endPos] = '\0';
		else {
			// copy exponent part
			do {
				s[++endPos] = s[pos++];
			} while( s[pos-1] != '\0' );
		}
	}

	if( sign )
		s--;
	return( s );
}

void check_case ( float64_t x, f_to_string_ptr f1, f_to_string_ptr f2, const char *s1, const char*s2, uint8_t max_chars, uint8_t max_zero ) {
	char *res1, *res2;
	char str[32], str2[32];
	int len1, len2;

	struct fp64_debug_t* xd = __fp64_debugAB();
	ddump( x );
	// res1 = my_to_string( r1, max_chars, 3 );
	res1 = (*f1)( x, max_chars, max_zero );
	dump_debug( xd );
	dump_debug( xd+1 );
	if( res1 ) {
		len1 = strlen( res1 );
		Serial.print( "res1 = |" ); Serial.print( res1 ); Serial.print("|"); Serial.println( len1 );
		strcpy( str, res1 ); 	// save result
	} else {
		len1 = -1;
		Serial.print( "res1 = |(NULL)|"); Serial.println( len1 );
		strcpy( str, "" ); 	// save result
	}
	res2 = (*f2)( x, max_chars, max_zero );
	len2 = strlen( res2 );
	strcpy( str2, res2 ); 	// save result
	Serial.print( "res2 = |" ); Serial.print( res2 ); Serial.print("|"); Serial.println( len2 );
	if( strcmp(str,str2) != 0 ) {
		if( isSubnormal(x) && len2 == 1 && len1 > len2 ) {
			check( true );
			Serial.print( F("OVERRIDE subn " ));
		} else if( (len1 == max_chars) && (len2 < max_chars) ) {
			check( true );
			Serial.print( F("OVERRIDE due to better matching strlen " ));
		} else if ( len1 < len2 && f_strtod( str, NULL ) == f_strtod( str2, NULL ) ) {
			check( true );
			Serial.print( F("OVERRIDE due to shorter conversion ") );
		} else {
			check( strcmp(str,str2) == 0 );
		}
	} else {
		check( strcmp(str,str2) == 0 );
	}
	Serial.println( s1 );
	check( len1 <= max_chars && len1 >= 0 );
	Serial.print( F("strlen ") );
	Serial.println( s1 );
}	

// compare two to_string implementations f1 & f2
void check_to_string_f( f_to_string_ptr f1, f_to_string_ptr f2, const char *s1, const char*s2 ) {
	float64_t r1, r2;
	struct ftoa_table1_t entry;
	uint8_t max_chars = 8;
	uint8_t max_zero = 3;

	Serial.print(F("--------- check " ));
	Serial.print( s1 );
	Serial.print(F(" vs. "));
	Serial.print( s2 );
	Serial.println(F("	---------"));
	
	Serial.println(F("	--------- check basic functionality ---------"));
	r1 = f_NUMBER_PI;
	r2 = f_NUMBER_PI;
	// check from +-PI to +-PI*10^+-12 and then for 1 
	for( int k = 0; k < 2; k++ ) {
		for( int i = 0; i < 12; i++ ) {
		// for( int i = 0; i < 4; i++ ) {
			for( int j = 0; j < 2; j++ ) {
				Serial.print( i ); Serial.println( j ? F(": neg") : F(": pos") );
				check_case( r1, f1, f2, s1, s2, max_chars, max_zero );
				check_case( r2, f1, f2, s1, s2, max_chars, max_zero );
				r1 = fp64_sub( float64_NUMBER_PLUS_ZERO, r1 );
				r2 = fp64_sub( float64_NUMBER_PLUS_ZERO, r2 );
				Serial.println();
			}
		
			r1 = fp64_mul( r1, f_NUMBER_10 );
			r2 = f_div( r2, f_NUMBER_10 );
		}
	r1 = float64_NUMBER_ONE;	// now use 1 to see whether truncating of trailing 0s works
	r2 = float64_NUMBER_ONE;
	}
	
	Serial.println(F("	--------- check special cases ---------"));
	// for( int i = 0; i < 100; i++ ) {
	for( int i = 0; i < ftoa_table1_size; i++ ) {
	// get either a pre-selected number or create a random number
		if( i < ftoa_table1_size ) {
			memcpy_P( &entry, &ftoa_table1[i], sizeof(entry) );
		} else {
			entry.x = createRandom();
			entry.isSubnormal = (((entry.x >> 48) & 0x7fff) < 0x0001 );
		}
			
		r1 = entry.x;
		for( int prec = 17; prec > ((i > ftoa_table1_size) ? 16 : 0); prec-- ) {
			Serial.print( i );
			Serial.print(F(": prec:"));
			Serial.println(prec);
			check_case( r1, f1, f2, s1, s2, prec+3, (uint8_t) prec );
			Serial.println();
		}
		Serial.println();
	}
#ifdef WITH_TIMING	
	// time conversion to string, 
	// cannot use timeIt operations as result are strings
	unsigned long start;
	for( int i = 12; i < ftoa_table1_size; i += 6 ) {
		memcpy_P( &entry, &ftoa_table1[i], sizeof(entry) );
		r1 = entry.x;
		max_chars = 15;
		max_zero = 8;
		for( int j = 0; j < 2; j++ ) {
			start = micros();
			for( int i = 0; i < 1000; i++ ) {
					char *res = (*f1)( r1, max_chars, max_zero );
			}
			timeItCommon( r1, s1, true, micros() - start );
			start = micros();
			for( int i = 0; i < 1000; i++ ) {
					char *res = (*f2)( r1, max_chars, max_zero );
			}
			timeItCommon( r1, s1, false, micros() - start );
			r1 = f_div( float64_MINUS_NUMBER_ONE, r1 );
		}
	}
#endif 

}

void check_to_string() {
	// check_to_string_f( my_to_string, f_to_string, "my_to_string", "f_to_string" );
	// check_to_string_f( ffp64_to_string, my_to_string, "ffp64_to_string", "my_to_string" );
	check_to_string_f( ffp64_to_string, f_to_string, "ffp64_to_string", "f_to_string" );
}
#endif

#ifdef CHECK_TOINT
void check_to_int8() {
	float f1, f2;
	float64_t r1, r2;
	int8_t i1, i2; 

	Serial.println("	--------- check basic functionality int8 ---------");
	struct fp64_debug_t* xd = __fp64_debugAB();
	f1 = 1.0;
	r1 = float64_NUMBER_ONE;
	// check for all exponents from 2^0 to 2^64 
	for( int i = 0; i < 65; i++ ) {
		Serial.println( i );
		// check for positive and negative numbers
		for( int j = 0; j < 2; j++ ) {
			f2 = f1 - 1.0;
			r2 = fp64_sub(r1, float64_NUMBER_ONE);
			// check for x-1, x and x+1 --> improper handling of overflow can be detected
			for( int k = -1; k < 2; k++ ) {
				Serial.print( i ); Serial.print( j ? F(": neg ") : F(": pos ") ); Serial.println(k);
				Serial.print( f2 ); Serial.print( " " ); ddump(r2);
				i1 = fp64_to_int8( r2 );
				dump_debug( xd );
				dump_debug( xd+1 );
				i2 = (int8_t) f2;
				if( i1 != i2 && fabs(f2) > 128.0 ) {
					check( true );
					Serial.print( F("OVERRIDE due to different overflow handling ") );
				} else 
					check( i1 == i2 );
				Serial.print( i1 ); Serial.print( " " ); Serial.print( i2 );
				Serial.println( F(" fp64_to_int8") );
				f2 = f2 + 1.0;
				r2 = fp64_add( r2, float64_NUMBER_ONE );
			}
			f1 = -f1;
			r1 = fp64_sub( float64_NUMBER_PLUS_ZERO, r1 );
		}
		
		Serial.println(); 
		r1 = fp64_mul( r1, f_NUMBER_2 );
		f1 = f1 * 2.0;
		Serial.println(); 
	}
}

void check_to_uint8() {
	float f1, f2;
	float64_t r1, r2;
	uint8_t i1, i2; 

	Serial.println("	--------- check basic functionality uint8 ---------");
	struct fp64_debug_t* xd = __fp64_debugAB();
	f1 = 1.0;
	r1 = float64_NUMBER_ONE;
	// check for all exponents from 2^0 to 2^64 
	for( int i = 0; i < 65; i++ ) {
		Serial.println( i );
		// check for positive and negative numbers
		for( int j = 0; j < 2; j++ ) {
			f2 = f1 - 1.0;
			r2 = fp64_sub(r1, float64_NUMBER_ONE);
			// check for x-1, x and x+1 --> improper handling of overflow can be detected
			for( int k = -1; k < 2; k++ ) {
				Serial.print( i ); Serial.print( j ? F(": neg ") : F(": pos ") ); Serial.println(k);
				Serial.print( f2 ); Serial.print( " " ); ddump(r2);
				i1 = fp64_to_uint8( r2 );
				dump_debug( xd );
				dump_debug( xd+1 );
				i2 = (uint8_t) f2;
				if( i1 != i2 && fabs(f2) > 256.0 ) {
					check( true );
					Serial.print( F("OVERRIDE due to different overflow handling ") );
				} else 
				check( i1 == i2 );
				Serial.print( i1 ); Serial.print( " " ); Serial.print( i2 );
				Serial.println( F(" fp64_to_uint8") );
				f2 = f2 + 1.0;
				r2 = fp64_add( r2, float64_NUMBER_ONE );
			}
			f1 = -f1;
			r1 = fp64_sub( float64_NUMBER_PLUS_ZERO, r1 );
		}
		
		Serial.println(); 
		r1 = fp64_mul( r1, f_NUMBER_2 );
		f1 = f1 * 2.0;
		Serial.println(); 
	}
}

void check_to_int16() {
	float f1, f2;
	float64_t r1, r2;
	int16_t i1, i2; 

	Serial.println("	--------- check basic functionality int16 ---------");
	struct fp64_debug_t* xd = __fp64_debugAB();
	f1 = 1.0;
	r1 = float64_NUMBER_ONE;
	// check for all exponents from 2^0 to 2^64 
	for( int i = 0; i < 65; i++ ) {
		Serial.println( i );
		// check for positive and negative numbers
		for( int j = 0; j < 2; j++ ) {
			f2 = f1 - 1.0;
			r2 = fp64_sub(r1, float64_NUMBER_ONE);
			// check for x-1, x and x+1 --> improper handling of overflow can be detected
			for( int k = -1; k < 2; k++ ) {
				Serial.print( i ); Serial.print( j ? F(": neg ") : F(": pos ") ); Serial.println(k);
				Serial.print( f2 ); Serial.print( " " ); ddump(r2);
				i1 = fp64_to_int16( r2 );
				dump_debug( xd );
				dump_debug( xd+1 );
				i2 = (int16_t) f2;
				if( i1 != i2 && fabs(f2) > 256.0 ) {
					check( true );
					Serial.print( F("OVERRIDE due to different overflow handling ") );
				} else 
					check( i1 == i2 );
				Serial.print( i1 ); Serial.print( " " ); Serial.print( i2 );
				Serial.println( F(" fp64_to_int16") );
				f2 = f2 + 1.0;
				r2 = fp64_add( r2, float64_NUMBER_ONE );
			}
			f1 = -f1;
			r1 = fp64_sub( float64_NUMBER_PLUS_ZERO, r1 );
		}
		
		Serial.println(); 
		r1 = fp64_mul( r1, f_NUMBER_2 );
		f1 = f1 * 2.0;
		Serial.println(); 
	}
	
}

void check_to_uint16() {
	float f1, f2;
	float64_t r1, r2;
	uint16_t i1, i2; 

	Serial.println("	--------- check basic functionality uint16 ---------");
	struct fp64_debug_t* xd = __fp64_debugAB();
	f1 = 1.0;
	r1 = float64_NUMBER_ONE;
	// check for all exponents from 2^0 to 2^64 
	for( int i = 0; i < 65; i++ ) {
		Serial.println( i );
		// check for positive and negative numbers
		for( int j = 0; j < 2; j++ ) {
			f2 = f1 - 1.0;
			r2 = fp64_sub(r1, float64_NUMBER_ONE);
			// check for x-1, x and x+1 --> improper handling of overflow can be detected
			for( int k = -1; k < 2; k++ ) {
				Serial.print( i ); Serial.print( j ? F(": neg ") : F(": pos ") ); Serial.println(k);
				Serial.print( f2 ); Serial.print( " " ); ddump(r2);
				i1 = fp64_to_uint16( r2 );
				dump_debug( xd );
				dump_debug( xd+1 );
				i2 = (uint16_t) f2;
				if( i1 != i2 && fabs(f2) > 65536.0 ) {
					check( true );
					Serial.print( F("OVERRIDE due to different overflow handling ") );
				} else 
					check( i1 == i2 );
				Serial.print( i1 ); Serial.print( " " ); Serial.print( i2 );
				Serial.println( F(" fp64_to_uint16") );
				f2 = f2 + 1.0;
				r2 = fp64_add( r2, float64_NUMBER_ONE );
			}
			f1 = -f1;
			r1 = fp64_sub( float64_NUMBER_PLUS_ZERO, r1 );
		}
		
		Serial.println(); 
		r1 = fp64_mul( r1, f_NUMBER_2 );
		f1 = f1 * 2.0;
		Serial.println(); 
	}
}

void check_to_int32() {
	float f1, f2;
	float64_t r1, r2;
	int32_t i1, i2; 

	Serial.println("	--------- check basic functionality int32 ---------");
	struct fp64_debug_t* xd = __fp64_debugAB();
	f1 = 1.0;
	r1 = float64_NUMBER_ONE;
	// check for all exponents from 2^0 to 2^64 
	for( int i = 0; i < 65; i++ ) {
		Serial.println( i );
		// check for positive and negative numbers
		for( int j = 0; j < 2; j++ ) {
			r2 = fp64_sub(r1, float64_NUMBER_ONE);
			// check for x-1, x and x+1 --> improper handling of overflow can be detected
			for( int k = -1; k < 2; k++ ) {
				f2 = (k < 0) ? f1 - 1.0 : ((k > 0) ? f1 + 1.0 : f1 );
				Serial.print( i ); Serial.print( j ? F(": neg ") : F(": pos ") ); Serial.println(k);
				Serial.print( f2 ); Serial.print( " " ); ddump(r2);
				i1 = fp64_to_int32( r2 );
				dump_debug( xd );
				dump_debug( xd+1 );
				i2 = (int32_t) f2;
				if( i1 != i2 && fabs(f2) > 32768.0*65536.0 ) {
					check( true );
					Serial.print( F("OVERRIDE due to different overflow handling ") );
				} else if ( i1 != i2 && f2 == f1 && k != 0 ) {
					check( true );
					Serial.print( F("OVERRIDE as precision of float is exceeded ") );
				} else
					check( i1 == i2 );
				Serial.print( i1 ); Serial.print( " " ); Serial.print( i2 );
				Serial.println( F(" fp64_to_int32") );
				r2 = fp64_add( r2, float64_NUMBER_ONE );
			}
			f1 = -f1;
			r1 = fp64_sub( float64_NUMBER_PLUS_ZERO, r1 );
		}
		
		Serial.println(); 
		r1 = fp64_mul( r1, f_NUMBER_2 );
		f1 = f1 * 2.0;
		Serial.println(); 
	}
	
}

void check_to_uint32() {
	float f1, f2;
	float64_t r1, r2;
	uint32_t i1, i2; 

	Serial.println("	--------- check basic functionality uint32 ---------");
	struct fp64_debug_t* xd = __fp64_debugAB();
	f1 = 1.0;
	r1 = float64_NUMBER_ONE;
	// check for all exponents from 2^0 to 2^64 
	for( int i = 0; i < 65; i++ ) {
		Serial.println( i );
		// check for positive and negative numbers
		for( int j = 0; j < 2; j++ ) {
			r2 = fp64_sub(r1, float64_NUMBER_ONE);
			// check for x-1, x and x+1 --> improper handling of overflow can be detected
			for( int k = -1; k < 2; k++ ) {
				f2 = (k < 0) ? f1 - 1.0 : ((k > 0) ? f1 + 1.0 : f1 );
				Serial.print( i ); Serial.print( j ? F(": neg ") : F(": pos ") ); Serial.println(k);
				Serial.print( f2 ); Serial.print( " " ); ddump(r2);
				i1 = fp64_to_uint32( r2 );
				dump_debug( xd );
				dump_debug( xd+1 );
				i2 = (uint32_t) f2;
				if( i1 != i2 && fabs(f2) > 65536.0*65536.0 ) {
					check( true );
					Serial.print( F("OVERRIDE due to different overflow handling ") );
				} else if ( i1 != i2 && f2 == f1 && k != 0 ) {
					check( true );
					Serial.print( F("OVERRIDE as precision of float is exceeded ") );
				} else
					check( i1 == i2 );
				Serial.print( i1 ); Serial.print( " " ); Serial.print( i2 );
				Serial.println( F(" fp64_to_uint32") );
				r2 = fp64_add( r2, float64_NUMBER_ONE );
			}
			f1 = -f1;
			r1 = fp64_sub( float64_NUMBER_PLUS_ZERO, r1 );
		}
		
		Serial.println(); 
		r1 = fp64_mul( r1, f_NUMBER_2 );
		f1 = f1 * 2.0;
		Serial.println(); 
	}
}

#ifdef WITH_TIMING
void check_to_long_timing( float64_t x ) {
	timeItLong( x, fp64_float64_to_long, f_float64_to_long, "fp64_float64_to_long" );
}
#endif 

void check_to_long() {
	float64_t r, r1, r2;
	long i1, i2; 
	struct ftoa_table1_t entry;

	Serial.println("	--------- check basic functionality fp64_float64_to_long ---------");
	struct fp64_debug_t* xd = __fp64_debugAB();
	r1 = float64_NUMBER_ONE;
	// check for all exponents from 2^0 to 2^64 
	for( int i = 0; i < 65; i++ ) {
		Serial.println( i );
		// check for positive and negative numbers
		for( int j = 0; j < 2; j++ ) {
			r2 = fp64_sub(r1, float64_NUMBER_ONE);
			// check for x-1, x and x+1 --> improper handling of overflow can be detected
			for( int k = -1; k < 2; k++ ) {
				Serial.print( i ); Serial.print( j ? F(": neg ") : F(": pos ") ); Serial.println(k);
				ddump(r2);
				i1 = fp64_float64_to_long( r2 );
				dump_debug( xd );
				dump_debug( xd+1 );
				i2 = f_float64_to_long( r2 );
				check( i1 == i2 );
				Serial.print( i1 ); Serial.print( " " ); Serial.print( i2 );
				Serial.println( F(" fp64_float64_to_long") );
				r2 = fp64_add( r2, float64_NUMBER_ONE );
			}
			// f1 = -f1;
			r1 = fp64_sub( float64_NUMBER_PLUS_ZERO, r1 );
		}
		
		Serial.println(); 
		r1 = fp64_mul( r1, f_NUMBER_2 );
		Serial.println(); 
	}
	
	Serial.println("	--------- check special cases fp64_float64_to_long ---------");
	// for( int i = 0; i < ftoa_table1_size; i++ ) {
	for( int i = 0; i < 1000; i++ ) {
		// get either a pre-selected number or create a random number
		if( i < ftoa_table1_size ) {
			memcpy_P( &entry, &ftoa_table1[i], sizeof(entry) );
		} else {
			entry.x = createRandom64();
			entry.isSubnormal = isSubnormal( entry.x );
		}
			
		Serial.print( i );
		Serial.println(F(":"));
		r = entry.x;
		ddump( r );
		
		i1 = fp64_float64_to_long( r );
		dump_debug( xd );
		dump_debug( xd+1 );
		i2 = f_float64_to_long( r );
		
		check( i1 == i2 );
		Serial.print( i1 ); Serial.print( " " ); Serial.print( i2 );
		Serial.println( F(" fp64_float64_to_long") );
		Serial.println(); 
	}

#ifdef WITH_TIMING
	Serial.println("--------- timing fp64_float64_to_long ---------");
	r = float64_NUMBER_PI;
	check_to_long_timing( r );
	Serial.println();
	
	r = f_sub( float64_NUMBER_PLUS_ZERO, f_NUMBER_180PI );
	check_to_long_timing( r );
	Serial.println();

	r = f_div( f_NUMBER_180PI, f_NUMBER_27E_3);
	check_to_long_timing( r );
	Serial.println();
#endif
}

void check_to_int64() {
	float f1, f2;
	float64_t r1, r2;
	int64_t i1, i2; 

	Serial.println("	--------- check basic functionality int64 ---------");
	struct fp64_debug_t* xd = __fp64_debugAB();
	f1 = 1.0;
	r1 = float64_NUMBER_ONE;
	// check for all exponents from 2^0 to 2^64 
	for( int i = 0; i < 65; i++ ) {
		Serial.println( i );
		// check for positive and negative numbers
		for( int j = 0; j < 2; j++ ) {
			r2 = fp64_sub(r1, float64_NUMBER_ONE);
			// check for x-1, x and x+1 --> improper handling of overflow can be detected
			for( int k = -1; k < 2; k++ ) {
				f2 = (k < 0) ? f1 - 1.0 : ((k > 0) ? f1 + 1.0 : f1 );
				Serial.print( i ); Serial.print( j ? F(": neg ") : F(": pos ") ); Serial.println(k);
				Serial.print( f2 ); Serial.print( " " ); ddump(r2);
				i1 = fp64_to_int64( r2 );
				dump_debug( xd );
				dump_debug( xd+1 );
				i2 = (int64_t) f2;
				if( i1 != i2 && fabs(f2) > 32768.0*65536.0*65536.0 ) {
					check( true );
					Serial.print( F("OVERRIDE due to different overflow handling ") );
				} else if ( i1 != i2 && f2 == f1 && k != 0 ) {
					check( true );
					Serial.print( F("OVERRIDE as precision of float is exceeded ") );
				} else
					check( i1 == i2 );
				Serial.print( convertLL(i1) ); Serial.print( " " ); Serial.print( convertLL(i2) );
				Serial.println( F(" fp64_to_int64") );
				r2 = fp64_add( r2, float64_NUMBER_ONE );
			}
			f1 = -f1;
			r1 = fp64_sub( float64_NUMBER_PLUS_ZERO, r1 );
		}
		
		Serial.println(); 
		r1 = fp64_mul( r1, f_NUMBER_2 );
		f1 = f1 * 2.0;
		Serial.println(); 
	}
	
}

void check_to_uint64() {
	float f1, f2;
	float64_t r1, r2;
	uint64_t i1, i2; 

	Serial.println("	--------- check basic functionality uint64 ---------");
	struct fp64_debug_t* xd = __fp64_debugAB();
	f1 = 1.0;
	r1 = float64_NUMBER_ONE;
	// check for all exponents from 2^0 to 2^64 
	for( int i = 0; i < 65; i++ ) {
		Serial.println( i );
		// check for positive and negative numbers
		for( int j = 0; j < 2; j++ ) {
			r2 = fp64_sub(r1, float64_NUMBER_ONE);
			// check for x-1, x and x+1 --> improper handling of overflow can be detected
			for( int k = -1; k < 2; k++ ) {
				f2 = (k < 0) ? f1 - 1.0 : ((k > 0) ? f1 + 1.0 : f1 );
				Serial.print( i ); Serial.print( j ? F(": neg ") : F(": pos ") ); Serial.println(k);
				Serial.print( f2 ); Serial.print( " " ); ddump(r2);
				i1 = fp64_to_uint64( r2 );
				dump_debug( xd );
				dump_debug( xd+1 );
				i2 = (uint64_t) f2;
				if( i1 != i2 && fabs(f2) > 65536.0*65536.0*65536.0 ) {
					check( true );
					Serial.print( F("OVERRIDE due to different overflow handling ") );
				} else if ( i1 != i2 && f2 == f1 && k != 0 ) {
					check( true );
					Serial.print( F("OVERRIDE as precision of float is exceeded ") );
				} else
					check( i1 == i2 );
				Serial.print( convertULL(i1) ); Serial.print( " " ); Serial.print( convertULL(i2) );
				Serial.println( F(" fp64_to_uint64") );
				r2 = fp64_add( r2, float64_NUMBER_ONE );
			}
			f1 = -f1;
			r1 = fp64_sub( float64_NUMBER_PLUS_ZERO, r1 );
		}
		
		Serial.println(); 
		r1 = fp64_mul( r1, f_NUMBER_2 );
		f1 = f1 * 2.0;
		Serial.println(); 
	}
}

void check_to_int() {
	// use typecasts of float as reference
	// check_to_int8();
	// check_to_uint8();
	// check_to_int16();
	// check_to_uint16();
	// check_to_int32();
	// check_to_uint32();
	// check_to_int64();
	// check_to_uint64();
	
	// use avr_f64 f_float64_to_long as reference
	check_to_long();
}
#endif

#ifdef CHECK_TOFLOAT
void dump_float( float f ) {
	uint8_t *p;
	
	p = (uint8_t*) &f;
	Serial.print( "0x" );
	for( int i = 3; i >= 0; i-- ) {
		Serial.print( toHex2( p[i] ) );
	}
	Serial.print( " " );
	char s[50];
	dtostrf(f, 12, 7, s);
	Serial.print( s ); Serial.print(" "); Serial.println(f);
}

#ifdef WITH_TIMING
void check_to_float_timing( float64_t x ) {
	// cannot use timeIt operations as result are floats
	unsigned long start;
	float res;
	start = micros();
	for( int i = 0; i < 1000; i++ ) {
			res = fp64_ds( x );
	}
	timeItCommon( x, "fp64_ds", true, micros() - start );
	start = micros();
	for( int i = 0; i < 1000; i++ ) {
			res = f_ds( x );
	}
	timeItCommon( x, "fp64_ds", false, micros() - start );
}
#endif 

void check_to_float() {
	float f1, f2, f;
	struct ftoa_table1_t entry;
	float64_t r, r1, r2;
	
	Serial.println(F("--------- check fp64_ds ---------"));
	struct fp64_debug_t* xd = __fp64_debugAB();
	for( int i = 0; i < ftoa_table1_size; i++ ) {
	// for( int i = 0; i < 100; i++ ) {
		// get either a pre-selected number or create a random number
		if( i < ftoa_table1_size ) {
			memcpy_P( &entry, &ftoa_table1[i], sizeof(entry) );
		} else {
			entry.x = createRandom64();
			entry.isSubnormal = isSubnormal( entry.x );
		}
			
		Serial.print( i );
		Serial.println(F(":"));
		r = entry.x;
		ddump( r );
		f1 = fp64_ds( r );
		dump_debug( xd );
		dump_float(f1);
		f2 = f_ds( r );
		dump_float(f2);
		if( f1 != f2 && !isfinite(f2) && !isinf(f2) ) {
			check( true );
			Serial.print(F("OVERRIDE due to different representation of NaN "));
		} else if( f1 != f2 && f1 == 0.0 && (i == 13 || i == 14)) {
			check( true );
			Serial.print(F("OVERRIDE due to incorrect handling of underflow "));
		} else 
			check( f1 == f2 );
		Serial.println( "fp64_ds" );
		Serial.println();
	}
	Serial.println();
	
	Serial.println(F("	--------- check basic functionality fp64_ds ---------"));
	r1 = float64_NUMBER_ONE;
	// check for all exponents from 2^0 to 2^128 
	for( int i = 0; i < 129; i++ ) {
		Serial.println( i );
		// check for positive and negative numbers
		for( int j = 0; j < 2; j++ ) {
			// check for x-1, x and x+1 --> improper handling of overflow can be detected
			for( int k = ((i<25) ? -1 : 0); k < ((i<25) ? 2 : 1); k++ ) {
				Serial.print( i ); Serial.print( j ? F(": neg ") : F(": pos ") ); Serial.println(k);
				switch( k ) {
				case -1: r2 = fp64_sub(r1, float64_NUMBER_ONE); break;
				case  0: r2 = r1; break;
				case  1: r2 = fp64_add(r1, float64_NUMBER_ONE); break;
				}
				ddump(r2);
				f1 = fp64_ds( r2 );
				dump_debug( xd );
				dump_float(f1);
				f2 = f_ds( r2 );
				dump_float(f2);
				check( f1 == f2 );
				Serial.println( "fp64_ds" );
			}
			r1 = fp64_sub( float64_NUMBER_PLUS_ZERO, r1 );
		}
		Serial.println(); 
		r1 = fp64_mul( r1, f_NUMBER_2 );
		Serial.println(); 
	}

	r1 = float64_NUMBER_ONE;
	r = 0x3e80000000000000LLU;
	// ddump(r);
	// check for all exponents from 2^0 to 2^-155 (includes subnormal numbers) 
	for( int i = 0; i < 155; i++ ) {
		Serial.println( i );
		// ddump( r );
		// ddump( r1 );
		// check for positive and negative numbers
		for( int j = 0; j < 2; j++ ) {
			// check for x-1, x and x+1 --> improper handling of overflow can be detected
			for( int k = -1; k < 2; k++ ) {
				Serial.print( i ); Serial.print( j ? F(": neg ") : F(": pos ") ); Serial.println(k);
				switch( k ) {
				case -1: r2 = f_sub(r1, r); break;
				case  0: r2 = r1; break;
				case  1: r2 = f_add(r1, r); break;
				}
				ddump(r2);
				f1 = fp64_ds( r2 );
				dump_debug( xd );
				dump_float(f1);
				f2 = f_ds( r2 );
				dump_float(f2);
				if( f1 != f2 && i >= 149 && f1 == 0.0 ) {
					check( true );
					Serial.print(F("OVERRIDE due to incorrect handling of underflow "));
				} else
					check( f1 == f2 );
				Serial.println( "fp64_ds" );
			}
			r1 = fp64_sub( float64_NUMBER_PLUS_ZERO, r1 );
		}
		Serial.println(); 
		r1 = f_div( r1, f_NUMBER_2 );
		r = f_div( r, f_NUMBER_2 );
		Serial.println(); 
	}

#ifdef WITH_TIMING
	Serial.println("--------- timing fp64_ds ---------");
	r = float64_NUMBER_PI;
	check_to_float_timing( r );
	Serial.println();
	
	r = f_sub( float64_NUMBER_PLUS_ZERO, f_NUMBER_180PI );
	check_to_float_timing( r );
	Serial.println();

	r = 0x3788000000000000LLU;
	check_to_float_timing( r );
	Serial.println();
#endif 
}
#endif

#ifdef CHECK_FN
void check_abs() {
	// check abs
	Serial.println(F("--------- check abs ---------"));
	for( int i = 0; i < check_table1_size; i++ ) {
		check_fop1(get_check_table1(i)->x, fp64_abs, "fp64_abs", f_abs(get_check_table1(i)->x) );
	}
}

void check_inv() {
	// check inverse
	Serial.println(F("--------- check inverse ---------"));
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.print(i);
		Serial.println(":");
		float64_t res = fp64_inverse(get_check_table1(i)->x);
		float64_t exp_res = f_div(float64_NUMBER_ONE,get_check_table1(i)->x);
		check_fop1(get_check_table1(i)->x, fp64_inverse, "fp64_inverse", exp_res );
		res = fp64_inverse(res);
		exp_res = f_div(float64_NUMBER_ONE,exp_res);
		dump( res, "1/res" );
		dump( exp_res, "1/exp_res" );
		Serial.println();
	}
}

void check_sqrt() {	
	// check sqrt
	Serial.println(F("--------- check sqrt ---------"));
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.print(i);
		Serial.println(":");
		float64_t exp_res = f_sqrt(get_check_table1(i)->x);
		check_fop1(get_check_table1(i)->x, fp64_sqrt, "fp64_sqrt", exp_res );
		float64_t res =fp64_sqrt(get_check_table1(i)->x);
		res = fp64_mul(res,res);
		exp_res = f_mult(exp_res,exp_res);
		dump(res,"delta res");
		dump(exp_res, "delta res2");
		Serial.println();
	}
#ifdef WITH_TIMING
	Serial.println(F("--------- timing sqrt ---------"));
	timeIt1( f_NUMBER_2, fp64_sqrt, "fp64_sqrt", true);
	timeIt1( f_NUMBER_2, f_sqrt, "f_sqrt", false);
#endif
}

void check_sqr() {
	// check square
	Serial.println(F("--------- check square ---------"));
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.print(i);
		Serial.println(":");
		float64_t x = get_check_table1(i)->x;
		float64_t res = fp64_square(x);
		float64_t exp_res = f_mult(x, x);
		ddump(x);
		ddump(exp_res);
		check_fop1( x, fp64_square, "fp64_square", exp_res );
		res = fp64_square(x);
		dump( res, "res" );
		dump( exp_res, "exp_res" );
		Serial.println();
	}
}

void check_cut() {
	float64_t r;
	
	// check fp64_cut_noninteger_fraction
	Serial.println(F("--------- check fp64_cut_noninteger_fraction ---------"));
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.println(i);
		r = get_check_table1(i)->x;
		check_fop1(r, fp64_cut_noninteger_fraction, "fp64_cut_noninteger_fraction", f_cut_noninteger_fraction(r) );
		Serial.println();
	}
	r = float64_NUMBER_PI;
	for( int i = 0; i < 18; i ++ ) {
		Serial.println(i);
		check_fop1(r, fp64_cut_noninteger_fraction, "fp64_cut_noninteger_fraction", f_cut_noninteger_fraction(r) );
		Serial.println();
		r = f_mult( r, f_NUMBER_10 );
	}
	
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_cut_noninteger_fraction ---------"));
	r = float64_NUMBER_PI;
	timeIt1( r, fp64_cut_noninteger_fraction, "fp64_cut_noninteger_fraction", true);
	timeIt1( r, f_cut_noninteger_fraction, "fp64_cut_noninteger_fraction" , false);
	Serial.println();
	
	r = f_NUMBER_001;
	timeIt1( r, fp64_cut_noninteger_fraction, "fp64_cut_noninteger_fraction", true);
	timeIt1( r, f_cut_noninteger_fraction, "fp64_cut_noninteger_fraction" , false);
	Serial.println();

	r = f_mult( float64_NUMBER_PI, f_NUMBER_100 );
	timeIt1( r, fp64_cut_noninteger_fraction, "fp64_cut_noninteger_fraction", true);
	timeIt1( r, f_cut_noninteger_fraction, "fp64_cut_noninteger_fraction" , false);
	Serial.println();

	r = f_mult( r, f_NUMBER_100 );
	r = f_mult( r, f_NUMBER_100 );
	timeIt1( r, fp64_cut_noninteger_fraction, "fp64_cut_noninteger_fraction", true);
	timeIt1( r, f_cut_noninteger_fraction, "fp64_cut_noninteger_fraction" , false);
	Serial.println();

#endif
}

float64_t my_ceil(float64_t x) {
	int16_t f_ex = x>>52;
	bool sign = f_ex & 2048;
	f_ex &= 2047;
	unsigned long long mask = 0x7fffffffffffffff;
	unsigned long long frac;
	
	if( x == 0x0000000000000000LLU )
		return( x );
	else if( sign ) 
		return( f_cut_noninteger_fraction(x) );
	else {
		if( f_ex < 1023+52 && f_ex >= 1023 ) 
			mask = 0x000fffffffffffff >> (f_ex-1023);
		else if( f_ex >= 1023+52 )
			mask = 0;
		frac = x & mask;
		if( frac ) 
		// if( f_ex <1023+52 && frac ) 
			// return( f_cut_noninteger_fraction( f_add(x,float64_NUMBER_ONE) ) );
			return( f_add(f_cut_noninteger_fraction(x), float64_NUMBER_ONE) );
		else
			return( f_cut_noninteger_fraction(x) );
	}
}

void check_ceil() {
	float64_t r;
	
	// check fp64_ceil
	Serial.println(F("--------- check fp64_ceil ---------"));
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.println(i);
		r = get_check_table1(i)->x;
		check_fop1(r, fp64_ceil, "fp64_ceil", my_ceil(r) );
		Serial.println();
	}
	r = float64_NUMBER_PI;
	for( int i = 0; i < 18; i ++ ) {
		Serial.println(i);
		check_fop1(r, fp64_ceil, "fp64_ceil", my_ceil(r) );
		Serial.println();
		r = f_mult( r, f_NUMBER_10 );
	}
	r = f_sub(float64_NUMBER_PLUS_ZERO, float64_NUMBER_PI);
	for( int i = 0; i < 18; i ++ ) {
		Serial.println(i);
		check_fop1(r, fp64_ceil, "fp64_ceil", my_ceil(r) );
		Serial.println();
		r = f_mult( r, f_NUMBER_10 );
	}
	
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_ceil ---------"));
	r = float64_NUMBER_PI;
	timeIt1( r, fp64_ceil, "fp64_ceil", true);
	timeIt1( r, my_ceil, "fp64_ceil" , false);
	Serial.println();
	
	r = f_NUMBER_001;
	timeIt1( r, fp64_ceil, "fp64_ceil", true);
	timeIt1( r, my_ceil, "fp64_ceil" , false);
	Serial.println();

	r = f_mult( float64_NUMBER_PI, f_NUMBER_100 );
	timeIt1( r, fp64_ceil, "fp64_ceil", true);
	timeIt1( r, my_ceil, "fp64_ceil" , false);
	Serial.println();

	r = f_mult( r, f_NUMBER_100 );
	r = f_mult( r, f_NUMBER_100 );
	timeIt1( r, fp64_ceil, "fp64_ceil", true);
	timeIt1( r, my_ceil, "fp64_ceil" , false);
	Serial.println();

#endif
}

float64_t my_floor(float64_t x) {
	if( x == 0x0000000000000000LLU || x == 0x8000000000000000LLU )
		return x;
	float64_t res = my_ceil( x ^ 0x8000000000000000LLU );
	if( res != 0x0000000000000000LLU )
		res^= 0x8000000000000000LLU;
	return res;
}

void check_floor() {
	float64_t r;
	
	// check fp64_floor
	Serial.println(F("--------- check fp64_floor ---------"));
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.println(i);
		r = get_check_table1(i)->x;
		check_fop1(r, fp64_floor, "fp64_floor", my_floor(r) );
		Serial.println();
	}
	r = float64_NUMBER_PI;
	for( int i = 0; i < 18; i ++ ) {
		Serial.println(i);
		check_fop1(r, fp64_floor, "fp64_floor", my_floor(r) );
		Serial.println();
		r = f_mult( r, f_NUMBER_10 );
	}
	r = f_sub(float64_NUMBER_PLUS_ZERO, float64_NUMBER_PI);
	for( int i = 0; i < 18; i ++ ) {
		Serial.println(i);
		check_fop1(r, fp64_floor, "fp64_floor", my_floor(r) );
		Serial.println();
		r = f_mult( r, f_NUMBER_10 );
	}
	
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_floor ---------"));
	r = float64_NUMBER_PI;
	timeIt1( r, fp64_floor, "fp64_floor", true);
	timeIt1( r, my_floor, "fp64_floor" , false);
	Serial.println();
	
	r = f_NUMBER_001;
	timeIt1( r, fp64_floor, "fp64_floor", true);
	timeIt1( r, my_floor, "fp64_floor" , false);
	Serial.println();

	r = f_mult( float64_NUMBER_PI, f_NUMBER_100 );
	timeIt1( r, fp64_floor, "fp64_floor", true);
	timeIt1( r, my_floor, "fp64_floor" , false);
	Serial.println();

	r = f_mult( r, f_NUMBER_100 );
	r = f_mult( r, f_NUMBER_100 );
	timeIt1( r, fp64_floor, "fp64_floor", true);
	timeIt1( r, my_floor, "fp64_floor" , false);
	Serial.println();

#endif
}

float64_t my_round(float64_t x) {
	bool sign = x >> 63;
	
	if( sign ) 
		return( x == 0x8000000000000000LLU ? x : f_cut_noninteger_fraction(f_sub(x,f_NUMBER_0_5) ) );
	else
		return( f_cut_noninteger_fraction(f_add(x,f_NUMBER_0_5) ) );
}

void check_round() {
	float64_t r;
	
	// check fp64_round
	Serial.println(F("--------- check fp64_round ---------"));
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.println(i);
		r = get_check_table1(i)->x;
		check_fop1(r, fp64_round, "fp64_round", my_round(r) );
		Serial.println();
	}
	r = float64_NUMBER_PI;
	for( int i = 0; i < 18; i ++ ) {
		Serial.println(i);
		check_fop1(r, fp64_round, "fp64_round", my_round(r) );
		Serial.println();
		r = f_mult( r, f_NUMBER_10 );
	}
	r = f_sub(float64_NUMBER_PLUS_ZERO, float64_NUMBER_PI);
	for( int i = 0; i < 18; i ++ ) {
		Serial.println(i);
		check_fop1(r, fp64_round, "fp64_round", my_round(r) );
		Serial.println();
		r = f_mult( r, f_NUMBER_10 );
	}
	
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_round ---------"));
	r = float64_NUMBER_PI;
	timeIt1( r, fp64_round, "fp64_round", true);
	timeIt1( r, my_round, "fp64_round" , false);
	Serial.println();
	
	r = f_NUMBER_001;
	timeIt1( r, fp64_round, "fp64_round", true);
	timeIt1( r, my_round, "fp64_round" , false);
	Serial.println();

	r = f_mult( float64_NUMBER_PI, f_NUMBER_100 );
	timeIt1( r, fp64_round, "fp64_round", true);
	timeIt1( r, my_round, "fp64_round" , false);
	Serial.println();

	r = f_mult( r, f_NUMBER_100 );
	r = f_mult( r, f_NUMBER_100 );
	timeIt1( r, fp64_round, "fp64_round", true);
	timeIt1( r, my_round, "fp64_round" , false);
	Serial.println();

#endif
}

long my_lround(float64_t x) {
	if( (uint16_t)((x >> 52) & 0x7ff) >= 0x41e )
		return( 0x80000000L );
	else
		return( f_float64_to_long( my_round( x ) ) );
}

void check_lround() {
	float64_t r, r2;
	long i1, i2; 
	
	// check fp64_lround
	Serial.println(F("--------- check fp64_lround ---------"));
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.println(i);
		r = get_check_table1(i)->x;
		Serial.println( fp64_lround(r) );
		check_longop1(r, fp64_lround, "fp64_lround", my_lround(r) );
		Serial.println();
	}
	r = float64_NUMBER_PI;
	for( int i = 0; i < 18; i ++ ) {
		Serial.println(i);
		check_longop1(r, fp64_lround, "fp64_lround", my_lround(r) );
		Serial.println();
		r = f_mult( r, f_NUMBER_10 );
	}
	r = f_sub(float64_NUMBER_PLUS_ZERO, float64_NUMBER_PI);
	for( int i = 0; i < 18; i ++ ) {
		Serial.println(i);
		check_longop1(r, fp64_lround, "fp64_lround", my_lround(r) );
		Serial.println();
		r = f_mult( r, f_NUMBER_10 );
	}
	
	// test beyond long number range from 2^0 to 2^32
	r = float64_NUMBER_ONE;
	for( int i = 0; i < 32; i++ ) {
		// for positive and negative numbers
		for( int j = -1; j < 2; j += 2 ) {
			// test for x-0.75, x-0.5, x-0.25, x, x+0.25, x+0.5, x+0.75 
			//   result   x-1     x      x     x    x      x+1   x+1
			r2 = f_sub( r, f_NUMBER_0_5 );
			r2 = f_sub( r2, f_NUMBER_0_25 );
			for( int k = -3; k < 4; k++ ) {
				Serial.print(i*j); Serial.print(" "); Serial.println( k );
				check_longop1(r2, fp64_lround, "fp64_lround", my_lround(r2) );
				Serial.println();
				r2 = f_add( r2, f_NUMBER_0_25 );
			}
			r = f_sub( float64_NUMBER_PLUS_ZERO, r );
		}
		Serial.println();
		r = f_mult( r, f_NUMBER_2 );
	}		
	
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_lround ---------"));
	r = float64_NUMBER_PI;
	timeItLong( r, fp64_lround, my_lround, "fp64_lround" );
	Serial.println();
	
	r = f_NUMBER_001;
	timeItLong( r, fp64_lround, my_lround, "fp64_lround" );
	Serial.println();

	r = f_mult( float64_NUMBER_PI, f_NUMBER_100 );
	timeItLong( r, fp64_lround, my_lround, "fp64_lround" );
	Serial.println();

	r = f_mult( r, f_NUMBER_100 );
	r = f_mult( r, f_NUMBER_100 );
	timeItLong( r, fp64_lround, my_lround, "fp64_lround" );
	Serial.println();
#endif
}

long my_lrint(float64_t x) {
	int16_t f_ex = x>>52;
	bool sign = f_ex & 2048;
	f_ex &= 2047;
	x &= 0x7fffffffffffffffULL; 
	if( x >= 0x41e0000000000000ULL )
		return( 0x80000000L );
	else {
		float64_t x1 = f_cut_noninteger_fraction(x);
		float64_t diff = f_sub( x, x1 ) & 0x7fffffffffffffffULL;
		long n = f_float64_to_long(x);
		// Serial.println( f_ex );
		// dumpLong( (uint8_t*) &x,     "    x"); Serial.println();
		// dumpLong( (uint8_t*) &x1,    "   x1"); Serial.println();
		// dumpLong( (uint8_t*) &diff,  " diff"); ddump(diff); Serial.println();
		
		if( diff > 0x3fe0000000000000ULL )
			n++;
		else if( diff < 0x3fe0000000000000ULL )
			;
		else if( n & 1 )
			n++;
		
		if( sign)
			return( -n );
		else
			return( n );
	}
}

void check_lrint() {
	float64_t r, r2;
	long i1, i2; 
	float rf, rf2;

	// Serial.println(F("--------- check my_lround ---------"));
	// check our implementation against float lrint
	// test beyond in range from +/-2^0 to +/-2^22
	// r = float64_NUMBER_ONE;
	// rf = 1.0;
	// for( int i = 0; i < 22; i++ ) {
		// // for positive and negative numbers
		// for( int j = -1; j < 2; j += 2 ) {
			// // test for x-0.75, x-0.5, x-0.25, x, x+0.25, x+0.5, x+0.75 
			// //   result   x-1     x      x     x    x      x+1   x+1
			// rf2 = rf - 1.5;
			// r2 = f_sub( r, f_NUMBER_0_5 );
			// r2 = f_sub( r2, float64_NUMBER_ONE );
			// for( int k = -6; k < 7; k++ ) {
				// Serial.print(i*j); Serial.print(" "); Serial.println( k );
				// long resf = lrint( rf2 );
				
				// Serial.print( rf2 ); Serial.print(" ");
				// Serial.print( resf, DEC ); Serial.print(" ");
				// Serial.print( resf, HEX ); Serial.print(" ");
				// check_longop1(r2, my_lrint, "my_lrint", resf );
				// Serial.println();
				// r2 = f_add( r2, f_NUMBER_0_25 );
				// rf2 = rf2 + 0.25;
			// }
			// r = f_sub( float64_NUMBER_PLUS_ZERO, r );
			// rf = -rf;
		// }
		// Serial.println();
		// rf = rf * 2.0;
		// r = f_mult( r, f_NUMBER_2 );
	// }		
	// check fp64_lrint
	Serial.println(F("--------- check fp64_lrint ---------"));
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.println(i);
		r = get_check_table1(i)->x;
		check_longop1(r, fp64_lrint, "fp64_lrint", my_lrint(r) );
		Serial.println();
	}
	r = float64_NUMBER_PI;
	for( int i = 0; i < 18; i ++ ) {
		Serial.println(i);
		check_longop1(r, fp64_lrint, "fp64_lrint", my_lrint(r) );
		Serial.println();
		r = f_mult( r, f_NUMBER_10 );
	}
	r = f_sub(float64_NUMBER_PLUS_ZERO, float64_NUMBER_PI);
	for( int i = 0; i < 18; i ++ ) {
		Serial.println(i);
		check_longop1(r, fp64_lrint, "fp64_lrint", my_lrint(r) );
		Serial.println();
		r = f_mult( r, f_NUMBER_10 );
	}
	
	// test beyond long number range from 2^0 to 2^32
	r = float64_NUMBER_ONE;
	for( int i = 0; i < 32; i++ ) {
		// for positive and negative numbers
		for( int j = -1; j < 2; j += 2 ) {
			// test for x-0.75, x-0.5, x-0.25, x, x+0.25, x+0.5, x+0.75 
			//   result   x-1    x-1     x     x    x      x+1   x+1     if x is even
			//   result   x-1     x      x     x    x       x    x+1     if x is odd
			r2 = f_sub( r, f_NUMBER_0_5 );
			r2 = f_sub( r2, float64_NUMBER_ONE );
			for( int k = -6; k < 7; k++ ) {
				Serial.print(i*j); Serial.print(" "); Serial.println( k );
				check_longop1(r2, fp64_lrint, "fp64_lrint", my_lrint(r2) );
				Serial.println();
				r2 = f_add( r2, f_NUMBER_0_25 );
			}
			r = f_sub( float64_NUMBER_PLUS_ZERO, r );
		}
		Serial.println();
		r = f_mult( r, f_NUMBER_2 );
	}		
	
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_lrint ---------"));
	r = float64_NUMBER_PI;
	timeItLong( r, fp64_lrint, my_lrint, "fp64_lrint" );
	Serial.println();
	
	r = f_NUMBER_001;
	timeItLong( r, fp64_lrint, my_lrint, "fp64_lrint" );
	Serial.println();

	r = f_mult( float64_NUMBER_PI, f_NUMBER_100 );
	timeItLong( r, fp64_lrint, my_lrint, "fp64_lrint" );
	Serial.println();

	r = f_mult( r, f_NUMBER_100 );
	r = f_mult( r, f_NUMBER_100 );
	timeItLong( r, fp64_lrint, my_lrint, "fp64_lrint" );
	Serial.println();
#endif
}

float64_t my_neg(float64_t x) {
	return( x ^ 0x8000000000000000LLU );
}

void check_neg() {
	float64_t r;
	
	// check fp64_neg
	Serial.println(F("--------- check fp64_neg ---------"));
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.println(i);
		r = get_check_table1(i)->x;
		check_fop1(r, fp64_neg, "fp64_neg", my_neg(r) );
		Serial.println();
	}
	r = float64_NUMBER_PI;
	for( int i = 0; i < 18; i ++ ) {
		Serial.println(i);
		check_fop1(r, fp64_neg, "fp64_neg", my_neg(r) );
		Serial.println();
		r = f_mult( r, f_NUMBER_10 );
	}
	r = f_sub(float64_NUMBER_PLUS_ZERO, float64_NUMBER_PI);
	for( int i = 0; i < 18; i ++ ) {
		Serial.println(i);
		check_fop1(r, fp64_neg, "fp64_neg", my_neg(r) );
		Serial.println();
		r = f_mult( r, f_NUMBER_10 );
	}
	
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_neg ---------"));
	r = float64_NUMBER_PI;
	timeIt1( r, fp64_neg, "fp64_neg", true);
	timeIt1( r, my_neg, "fp64_neg" , false);
	Serial.println();
	
	r = f_NUMBER_001;
	timeIt1( r, fp64_neg, "fp64_neg", true);
	timeIt1( r, my_neg, "fp64_neg" , false);
	Serial.println();

	r = f_mult( float64_NUMBER_PI, f_NUMBER_100 );
	timeIt1( r, fp64_neg, "fp64_neg", true);
	timeIt1( r, my_neg, "fp64_neg" , false);
	Serial.println();

	r = f_mult( r, f_NUMBER_100 );
	r = f_mult( r, f_NUMBER_100 );
	timeIt1( r, fp64_neg, "fp64_neg", true);
	timeIt1( r, my_neg, "fp64_neg" , false);
	Serial.println();

#endif
}

float64_t my_modf( float64_t a, float64_t *i ) {
	// float64_t res1 = fp64_trunc(a);
	// float64_t res2 = fp64_sub(a, res1);
	// if( i )
		// *i = res1;
	// return( res2 );
	if( fp64_isinf(a)) {
		Serial.println( "infinite" );
		if( i ) 
			*i = a & 0x8000000000000000LLU;
		return( a );
	} else {
		// Serial.println( "finite" );
		return( f_mod( a, float64_NUMBER_ONE, i ) );
	}
}

#ifdef WITH_TIMING	
float64_t my_modft( float64_t a ) {
	float64_t i;
	return( my_modf( a, &i ) );
}

float64_t fp64_modft( float64_t a ) {
	float64_t i;
	return( fp64_modf( a, &i ) );
}

float64_t my_modft_null( float64_t a ) {
	return( my_modf( a, NULL ) );
}

float64_t fp64_modft_null( float64_t a ) {
	return( fp64_modf( a, NULL ) );
}
#endif

void check_modf() {
	float64_t x, r1, r2, i1, i2;
	
	// check fp64_modf
	Serial.println(F("--------- check fp64_modf ---------"));
	for( int i = 0; i < size_trig_vals; i++ ) {
		Serial.println(i);
		x = get_check_trig_vals(i);
		i1 = float64_NUMBER_PLUS_ZERO;
		i2 = float64_NUMBER_PLUS_ZERO;
		Serial.print(" &iptr = "); Serial.println( (uint16_t) &i1, HEX );
		struct fp64_debug_t* xd = __fp64_debugAB();
		r1 = fp64_modf( x, &i1 );
#ifndef FAST
		dump_debug( xd ); // dump intermediate result			
		dump_debug( xd+1 ); // dump intermediate result			
		dump_debug( xd+2 ); // dump intermediate result			
#endif
		Serial.println( toHex4( (uint16_t) &i1 ));
		r2 = my_modf( x, &i2 );
		check_res(x, r1, "fp64_modf", r2 );
		check_res(x, i1, "fp64_modf", i2 );
		Serial.println();
	}
	
#ifdef WITH_TIMING	
	Serial.println(F("--------- timing fp64_modf ---------"));
	timeIt1( f_EULER_E,fp64_modft, "fp64_modf", true);
	timeIt1( f_EULER_E,my_modft, "my_modf", false);
	timeIt1( f_NUMBER_2,fp64_modft, "fp64_modf", true);
	timeIt1( f_NUMBER_2,my_modft, "my_modf", false);
	timeIt1( f_NUMBER_0_5,fp64_modft, "fp64_modf", true);
	timeIt1( f_NUMBER_0_5,my_modft, "my_modf", false);

	timeIt1( f_EULER_E,fp64_modft_null, "fp64_modf", true);
	timeIt1( f_EULER_E,my_modft_null, "my_modf", false);
	timeIt1( f_NUMBER_2,fp64_modft_null, "fp64_modf", true);
	timeIt1( f_NUMBER_2,my_modft_null, "my_modf", false);
	timeIt1( f_NUMBER_0_5,fp64_modft_null, "fp64_modf", true);
	timeIt1( f_NUMBER_0_5,my_modft_null, "my_modf", false);

#endif
}

void check_fn() {
	// check_abs();
	// check_inv();
	// check_sqrt();
	// check_sqr();
	// check_cut();
	// check_ceil();
	// check_floor();
	// check_round();
	// check_lround();
	// check_lrint();
	// check_neg();
	check_modf();
}
#endif

#ifdef CHECK_LDEXP
float64_t my_ldexp (float64_t x, int exp) {
	float64_t x1;
	int16_t f_ex = x>>52;
	bool sign = f_ex & 2048;
	f_ex &= 2047;
	
	if( (x & 0x7fffffffffffffffULL) >= 0x7ff0000000000000ULL )
		return( x );
	else {
		f_ex += exp;
		// Serial.println( f_ex );
		if( f_ex > 0x7fe || exp > (0x7ff+53) )
			return( sign ? float64_MINUS_INFINITY : float64_PLUS_INFINITY );
		else if( (f_ex < -52) || (exp < (-2046-53)) )
			return( sign ? 0x8000000000000000LLU : float64_NUMBER_PLUS_ZERO );
		if( exp <= -1023 )
			x1 = 0x1ULL << (1023+51+exp);
		else
			x1 = ((uint64_t) (exp + 1023)) << 52;
		// ddump( x1 );
		float64_t res = fp64_mul( x, x1 ); // this handles also subnormal numbers
		return( res );
	}
}

#ifdef WITH_TIMING
void check_ldexp_timing( float64_t x, int exp ) {
	// cannot use timeIt operations as result are floats
	unsigned long start;
	float res;
	start = micros();
	for( int i = 0; i < 1000; i++ ) {
			res = fp64_ldexp( x, exp );
	}
	timeItCommon( x, "fp64_ldexp", true, micros() - start );
	start = micros();
	for( int i = 0; i < 1000; i++ ) {
			res = my_ldexp( x, exp );
	}
	timeItCommon( x, "fp64_ldexp", false, micros() - start );
}
#endif 
		
void check_ldexp() {
	float64_t r, r2, r3;
	float64_t res, res2, res3;
	int exp, exp2;
	Serial.println(F("--------- check fp64_ldexp ---------"));
	// check our implementation against float ldexp
	// test beyond in range from +/-2^0 to +/-2^1023
	// check whether subnormal calculations work
	struct fp64_debug_t* xd = __fp64_debugAB();
	r = 0x001921FB54442D18LLU;
	dddump(r);
	r = fp64_div( r , f_NUMBER_2 );
	dddump(r); check( r == 0x000C90FDAA22168CLLU ); Serial.println( F("fp64_ldexp") );
	r = fp64_div( r , f_NUMBER_2 );
	dddump(r); check( r == 0x0006487ED5110B46LLU ); Serial.println( F("fp64_ldexp") );
	r = fp64_div( r , 0x4010000000000000LLU );
	dddump(r); check( r == 0x0001921FB54442D1LLU ); Serial.println( F("fp64_ldexp") );
	
	r = 0x001921FB54442D18LLU;
	dddump(r);
	r = fp64_mul( r , f_NUMBER_0_5 );
	dddump(r); check( r == 0x000C90FDAA22168CLLU ); Serial.println( F("fp64_ldexp") );
	r = fp64_mul( r , f_NUMBER_0_5 );
	dddump(r); check( r == 0x0006487ED5110B46LLU ); Serial.println( F("fp64_ldexp") );
	r = fp64_mul( r , f_NUMBER_0_25 );
	dddump(r); check( r == 0x0001921FB54442D1LLU ); Serial.println( F("fp64_ldexp") );
	
	r = float64_NUMBER_PI;
	r2 = f_NUMBER_2;
	r3 = float64_NUMBER_ONE;
	exp = 1;
	for( int i = 0; i < 16; i++ ) {
		// for positive and negative exponents
		r3 = fp64_mul( r2, f_NUMBER_0_25 );
		for( int j = -1; j < 2; j += 2 ) {
			for( int k = -2; k < 3; k++ ) {
				// test for 2^(n-2), 2^(n-1), 2^n, 2^(n+1), 2^(n+2)
				exp2 = exp + k;
				Serial.print( i ); Serial.print( j > 0 ? F(": neg ") : F(": pos ") ); Serial.print( k );
				Serial.print(" 2^" ); Serial.println( exp2 );
				res = fp64_ldexp( r, exp2 );
				dump_debug( xd );
				dump_debug( xd+1 );
				ddump( r );
				ddump( res );
				if( abs(exp2) < 1022 ) {
					res2 = fp64_mul( r, r3 );
					ddump( r3 );
					ddump( res2 );
					check_diff( res, res2 );
					Serial.println( F("fp64_ldexp"));
				}
				res3 = my_ldexp( r, exp2 );
				ddump( res3 );
				check_diff( res, res3 );
				Serial.println( F("fp64_ldexp\n"));
	
				r3 = fp64_mul( r3, f_NUMBER_2 );
			}
			exp = -exp;
			r3 = fp64_div(f_NUMBER_2, r3 );
		}
		Serial.println();
		r2 = fp64_mul( r2, r2 );
		exp <<= 1;
	}		
	
	for( int i = 0; i < check_table1_size; i++ ) {
		for( exp2 = -2; exp2 < 3; exp2++ ) {
			Serial.print(i); Serial.print(F(": exp:")); Serial.println(exp2);
			r = get_check_table1(i)->x;
			res = fp64_ldexp( r, exp2 );
			dump_debug( xd );
			dump_debug( xd+1 );
			ddump( r );
			ddump( res );
			res3 = my_ldexp( r, exp2 );
			ddump( res3 );
			check_diff( res, res3 );
			Serial.println( F("fp64_ldexp\n"));
		}
	}
#ifdef WITH_TIMING
	Serial.println("--------- timing fp64_ldexp ---------");
	r = float64_NUMBER_PI;
	check_ldexp_timing( r, 10 );
	Serial.println();
	
	r = float64_NUMBER_PI;
	check_ldexp_timing( r, -10 );
	Serial.println();

	r = f_sub( float64_NUMBER_PLUS_ZERO, f_NUMBER_180PI );
	check_ldexp_timing( r, 10 );
	Serial.println();

	r = 0x0001921FB54442D1LLU;
	check_ldexp_timing( r, -10 );
	Serial.println();
#endif

}
#endif

#ifdef CHECK_FDIM
float64_t my_fdim( float64_t a, float64_t b ) {
	if( fp64_isnan(a) || fp64_isnan(b) )
		return( float64_ONE_POSSIBLE_NAN_REPRESENTATION );
	float64_t res = my_sub( a, b );
	if( res & 0x8000000000000000LLU )
		return( float64_NUMBER_PLUS_ZERO );
	else
		return( res );
}

void dump_fdim( int i, float64_t a, float64_t b ) {
	dump_op2( i, a, b, fp64_fdim, my_fdim, "fp64_fdim", FLAGS_FDIM );
}

void check_fdim() {
	float64_t a, b;
	float64_t res, res2;
	
	Serial.println(F("--------- check fp64_fdim ---------"));

	for( int i = 0; i < check_mult_table_size; i++ ) {
		a = get_mult_table(i)->a;
		b = get_mult_table(i)->b;
		dump_fdim( i, a, b );
		dump_fdim( i, b, a );
	}
	
#ifdef WITH_TIMING	
	Serial.println(F("--------- timing fp64_fdim ---------"));
	timeIt( f_EULER_E,f_NUMBER_2,fp64_fdim, "fp64_fdim", true);
	timeIt( f_EULER_E,f_NUMBER_2,my_fdim, "my_fdim", false);
	timeIt( f_NUMBER_2,f_EULER_E,fp64_fdim, "fp64_fdim", true);
	timeIt( f_NUMBER_2,f_EULER_E,my_fdim, "my_fdim", false);

	a = get_mult_table(23)->a;
	b = get_mult_table(23)->b;
	timeIt( a, b, fp64_fdim, "fp64_fdim subn", true);

	a = get_mult_table(23)->a;
	b = get_mult_table(23)->b;
	timeIt( a, b, my_fdim, "my_fdim subn", false);	
#endif
}
#endif

#ifdef CHECK_POW
float64_t my_pow( float64_t a, float64_t b ) {
	float64_t res;
	// we have to declare our own function, as f_pow is just a macro
	// and macros cannot be passed as function pointers
	if( a == float64_NUMBER_ONE || b == float64_NUMBER_ONE )
		return( a );
	else if( (b & 0x7fffffffffffffffLLU) == float64_NUMBER_PLUS_ZERO ) {
		return( float64_NUMBER_ONE );
	}
	else if ( (a >> 63) & 1 ) {
		//a is negative, check for b being an positive integer
		if( (b < 0x4340000000000000LLU) && (b == f_cut_noninteger_fraction(b))) { 
			// x^y = abs(x)^y for x even
			res = f_pow( a & 0x7fffffffffffffffLLU, b );
			if( f_mod( b, f_NUMBER_2, NULL ) )
				// x^y = -abs(x)^y for x odd
				res = res | 0x8000000000000000LLU;
			return( res );
		} else 
			return( float64_ONE_POSSIBLE_NAN_REPRESENTATION );
	}
			
	res = f_pow(a,b);
	return( res);
}

void dump_pow( int i, float64_t a, float64_t b ) {
	dump_op2( i, a, b, fp64_pow, my_pow , "fp64_pow", FLAGS_POW );
}

void check_xpowy() {
	float64_t a, b;
	float64_t res, res2;
	
	Serial.println(F("--------- check fp64_pow ---------"));

	for( int i = 0; i < check_mult_table_size; i++ ) {
		a = get_mult_table(i)->a;
		b = get_mult_table(i)->b;
		dump_pow( i, a, b );
		// dump_pow( i, b, a );
	}
	
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.println(i);
		b = get_check_table1(i)->x;
		res2 = my_pow( float64_NUMBER_PLUS_ZERO, b );
		check_fop2( float64_NUMBER_PLUS_ZERO, b, fp64_pow, "fp64_pow", res2 );
		Serial.println();
	}		
		
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.println(i);
		b = get_check_table1(i)->x;
		check_fop2( float64_NUMBER_ONE, b, fp64_pow, "fp64_pow", float64_NUMBER_ONE );
		Serial.println();
	}		
	
	// check (negative x)^(positive integer)
	a = f_MINUS_NUMBER_2;
	b = float64_NUMBER_ONE;
	for( int i = 0; i < 33; i++ ) {
		Serial.println(i);
		res2 = my_pow( a, b );
		check_fop2( a, b, fp64_pow, "fp64_pow", res2 );
		Serial.println();
		b = f_add( b, float64_NUMBER_ONE );
	}		
	
	
#ifdef WITH_TIMING	
	Serial.println(F("--------- timing fp64_pow ---------"));
	timeIt( f_EULER_E,f_NUMBER_2,fp64_pow, "fp64_pow", true);
	timeIt( f_EULER_E,f_NUMBER_2,my_pow, "my_pow", false);
	timeIt( f_NUMBER_2,f_EULER_E,fp64_pow, "fp64_pow", true);
	timeIt( f_NUMBER_2,f_EULER_E,my_pow, "my_pow", false);

	a = get_mult_table(23)->a;
	b = get_mult_table(23)->b;
	timeIt( a, b, fp64_pow, "fp64_pow subn", true);

	a = get_mult_table(23)->a;
	b = get_mult_table(23)->b;
	timeIt( a, b, my_pow, "my_pow subn", false);	
#endif
}

float64_t my_cbrt( float64_t a ) {
		float64_t sign = a & 0x8000000000000000LLU;
		a ^= sign;
		float64_t res = f_pow( a, 0x3FD5555555555555LLU );
		res |= sign; 
		return( res );
}

void check_cbrt() {
	float64_t a, b;
	float64_t res, res2;

	Serial.println(F("--------- check fp64_cbrt ---------"));
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.print(i);
		Serial.println(":");
		a = get_check_table1(i)->x;
		res2 = my_cbrt(a);
		check_fop1( a, fp64_cbrt, "fp64_cbrt", res2 );
		Serial.println();
	}
	
	// check n^3
	a = float64_NUMBER_ONE;
	for( int i = 0; i < 100; i++ ) {
		Serial.println(i);
		b = f_mult( a, a );
		b = f_mult( b, a );
		check_fop1( b, fp64_cbrt, "fp64_cbrt", my_cbrt(b) );
		Serial.println();
		check_fop1( b, fp64_cbrt, "fp64_cbrt", a );
		Serial.println();
		a = f_add( a, float64_NUMBER_ONE );
	}
	
#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_cbrt ---------"));
	timeIt1( f_NUMBER_2, fp64_cbrt, "fp64_cbrt", true);
	timeIt1( f_NUMBER_2, my_cbrt, "my_cbrt", false);
#endif
	
}

void check_pow() {
	check_xpowy();
	check_cbrt();
}	
#endif

#ifdef CHECK_HYPOT
float64_t my_hypot( float64_t a, float64_t b ) {
	float64_t res = f_mult( a, a );
	float64_t res2 = f_mult( b, b );
	res = f_add(res,res2);
	return( f_sqrt(res) );
}

void dump_hypot( int i, float64_t a, float64_t b ) {
	dump_op2( i, a, b, fp64_hypot, my_hypot , "fp64_hypot", FLAGS_HYPOT );
}

void check_hypot() {
	float64_t a, b;
	float64_t res, res2;
	
	Serial.println(F("--------- check fp64_hypot ---------"));

	for( int i = 0; i < check_mult_table_size; i++ ) {
		a = get_mult_table(i)->a;
		b = get_mult_table(i)->b;
		dump_hypot( i, a, b );
		dump_hypot( i, b, a );
	}
	
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.println(i);
		b = get_check_table1(i)->x;
		res2 = my_hypot( float64_NUMBER_ONE, b );
		check_fop2( float64_NUMBER_ONE, b, fp64_hypot, "fp64_hypot", res2 );
		Serial.println();
	}		
	
	a = float64_NUMBER_ONE;
	b = float64_NUMBER_ONE;
	for( int i = 0; i < 10; i++ ) {
		Serial.println(i);
		res2 = my_hypot( a, b );
		check_fop2( a, b, fp64_hypot, "fp64_hypot", res2 );
		a = f_add( a, float64_NUMBER_ONE );
		b = f_add( b, f_NUMBER_2 );
		Serial.println();
	}		
	
#ifdef WITH_TIMING	
	Serial.println(F("--------- timing fp64_pow ---------"));
	timeIt( f_EULER_E,f_NUMBER_2,fp64_hypot, "fp64_hypot", true);
	timeIt( f_EULER_E,f_NUMBER_2,my_hypot, "my_hypot", false);
	timeIt( f_NUMBER_2,f_EULER_E,fp64_hypot, "fp64_hypot", true);
	timeIt( f_NUMBER_2,f_EULER_E,my_hypot, "my_hypot", false);
#endif
}
#endif

#ifdef CHECK_FREXP
float64_t my_frexp (float64_t x, int *pexp) {
	float64_t res;
	int sign;
	if( pexp )
		*pexp = 0;
	int f_ex = (x >> 52);
	sign = f_ex & 0x0800;
	f_ex -= sign;
	if( f_ex == 0x7ff || f_ex == 0x000 )
		return( x );
	*pexp = f_ex - 0x3fe;
	res = x & 0xfffffffffffffLLU;
	if( sign )
		res |= 0xbfe0000000000000LLU;
	else
		res |= 0x3fe0000000000000LLU;
	return( res );
}

#ifdef WITH_TIMING
void check_frexp_timing( float64_t x, int* pexp ) {
	// cannot use timeIt operations as result are floats
	unsigned long start;
	float res;
	start = micros();
	for( int i = 0; i < 1000; i++ ) {
			res = fp64_frexp( x, pexp );
	}
	timeItCommon( res, "fp64_frexp", true, micros() - start );
	start = micros();
	for( int i = 0; i < 1000; i++ ) {
			res = my_frexp( x, pexp );
	}
	timeItCommon( res, "my_frexp", false, micros() - start );
}
#endif 
		
void check_frexp() {
	float64_t r, r2, r3;
	float64_t res, res2, res3;
	int exp, exp2;
	bool ok;
	
	Serial.println(F("--------- check fp64_frexp ---------"));
	struct fp64_debug_t* xd = __fp64_debugAB();
	Serial.println( toHex4( (uint16_t) &exp ));
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.println(i);
		r = get_check_table1(i)->x;
		exp = exp2 = 0x1234;
		res = fp64_frexp( r, &exp );
		dump_debug( xd );
		dump_debug( xd+1 );
		ddump( r );
		ddump( res );
		res2 = my_frexp( r, &exp2 );
		ddump( res2 );
		check_diff( res, res2 );
		Serial.println( F("fp64_frexp"));
		ok = exp == exp2;
		if( !ok && isSubnormal(r) && exp2 == 0 ) {
			check( ok = true ),
			Serial.print( F("OVERRIDE subn") );
			Serial.print( exp );
			Serial.print( F("!=") );
		} else if( check( ok ) ) {
			Serial.print( exp );
			Serial.print( F("==") );
		} else {
			Serial.print( exp );
			Serial.print( F("!=") );
		}
		Serial.print( exp2 );
		Serial.println(F(" fp64_frexp\n"));	
	}
	
#ifdef WITH_TIMING
	Serial.println("--------- timing fp64_frexp ---------");
	r = float64_NUMBER_PI;
	check_frexp_timing( r, NULL );
	Serial.println();
	
	r = float64_NUMBER_PI;
	check_frexp_timing( r, &exp );
	Serial.println();

	r = 0x0001921FB54442D1LLU;
	check_frexp_timing( r, &exp );
	Serial.println();
#endif

}
#endif

#ifdef CHECK_FMA
float64_t my_fma( float64_t a, float64_t b, float64_t c ) {
	float64_t res, res2;
	res = f_mult( a, b );
	// work around sign bug in f_add: 
	// f_add( any, -Inf ) returns +Inf instead of -Inf
	// f_add( -any, +Inf ) returns -Inf instead of +Inf
	if( fp64_isfinite(res) && fp64_isinf(c) )
		res2 = c;
	else
		res2 = f_add( res, c );
	return( res2 );
}

#ifdef WITH_TIMING
void check_fma_timing( float64_t a, float64_t b, float64_t c ) {
	// cannot use timeIt operations as result are floats
	unsigned long start;
	float res;
	start = micros();
	for( int i = 0; i < 1000; i++ ) {
			res = fp64_fma( a, b, c );
	}
	timeItCommon( res, "fp64_frexp", true, micros() - start );
	start = micros();
	for( int i = 0; i < 1000; i++ ) {
			res = my_fma( a, b, c );
	}
	timeItCommon( res, "my_frexp", false, micros() - start );
}
#endif 

void check_fma() {
	float64_t a, b, c, res, res2;
	
	Serial.println(F("--------- check fp64_fma ---------"));
	struct fp64_debug_t* xd = __fp64_debugAB();
	
	for( int i = 0; i < check_mult_table_size; i++ ) {
	// for( int i = 0; i < 10; i++ ) {
		a = get_mult_table(i)->a;
		b = get_mult_table(i)->b;
		for( int j = 0; j < check_table1_size; j++ ) {
			Serial.print(i); Serial.print("+"); Serial.println(j);
			c = get_check_table1(j)->x;
			dddump( a );
			dddump( b );
			dddump( c );
	
			res = fp64_fma( a, b, c );
			dump_debug( xd ); // dump intermediate result			
			dump_debug( xd+1 );
			dddump( res );
			
			res2 = my_fma( a, b, c );
			dddump( res2 );
			check_diff( res, res2 );
			Serial.println(F("fp64_fma\n"));
		}
		Serial.println();
	}

#ifdef WITH_TIMING
	Serial.println("--------- timing fp64_fma ---------");
	check_fma_timing( float64_NUMBER_PI, f_NUMBER_2, float64_NUMBER_PLUS_ZERO );
	Serial.println();
	
	check_fma_timing( float64_NUMBER_PI, f_NUMBER_2, float64_NUMBER_PIO4 );
	Serial.println();

	check_fma_timing( 0x0001921FB54442D1LLU, f_NUMBER_16, 0x0010000000000000LLU );
	Serial.println();
#endif	
}
#endif

#ifdef CHECK_TRIGH
void check_trigh_values( f1ptr f, f1ptr fexp, const char *s ) {
	struct fp64_debug_t* xd = __fp64_debugAB();
	for( int i = 0; i < check_table1_size; i++ ) {
		Serial.print( i );
		Serial.println(F(": special value"));
		float64_t x = get_check_table1(i)->x;
		float64_t res2 = (*fexp)( x );
		check_fop1( x, f, s, res2 );
		Serial.println();
	}
	Serial.println();
}

void check_trigh_all( f1ptr f, f1ptr fexp, const char *s ) {
	float64_t phi;
	char s2[10] = "f_";
	
	Serial.print(F("--------- check ")); Serial.print( s ); Serial.println(F(" ---------"));
	check_trigh_values( f, fexp, s );

#ifdef WITH_TIMING
	Serial.print(F("--------- timing ")); Serial.print( s ); Serial.println(F(" ---------"));
	phi = float64_NUMBER_PI;
	timeIt1( phi, f, s, true);
	strcat( s2, s+5 );		// build f_xxxx out of fp64_xxxx
	timeIt1( phi, fexp, s2, false);
	
	phi = f_sub( float64_NUMBER_PLUS_ZERO, float64_NUMBER_2PI);
	timeIt1( phi, f, s, true);
	strcat( s2, "1" );		// build f_xxxx out of fp64_xxxx
	timeIt1( phi, fexp, s2, false);

	phi = f_NUMBER_01;
	timeIt1( phi, f, s, true);
	strcat( s2, "2" );		// build f_xxxx out of fp64_xxxx
	timeIt1( phi, fexp, s2, false);
#endif
}

float64_t my_cosh( float64_t x ) {
	// work around 
	if( fp64_isinf(x) )
		return( float64_PLUS_INFINITY );

	float64_t res = f_exp(x);
	float64_t res2 = f_div( float64_NUMBER_ONE, res );
	res = f_add( res, res2 );
	res = f_mult( res, f_NUMBER_0_5 );
	return( res );
}
	
void check_cosh() {
	check_trigh_all( fp64_cosh, my_cosh, "fp64_cosh" );
}

float64_t my_sinh( float64_t x) {
	// work around 
	if( fp64_isinf(x) < 0 )
		return( x );
	
	float64_t res = f_exp(x);
	float64_t res2 = f_div( float64_NUMBER_ONE, res );
	res = f_sub( res, res2 );
	res = f_mult( res, f_NUMBER_0_5 );
	return( res );
}
	
void check_sinh() {
	check_trigh_all( fp64_sinh, my_sinh, "fp64_sinh" );
}

float64_t my_tanh( float64_t x) {
	float64_t res = f_exp(x);
	float64_t res2 = f_div( float64_NUMBER_ONE, res );
	float64_t res3 = f_add( res, res2 );
	float64_t res4 = f_sub( res, res2 );
	res = (res4 == float64_NUMBER_PLUS_ZERO) ? float64_PLUS_INFINITY : f_div( res3, res4 );
	return( res );
}

void check_tanh() {
	check_trigh_all( fp64_tanh, my_tanh, "fp64_tanh" );
}

void check_trigh() {
	check_cosh();
	check_sinh();
	check_tanh();
}
#endif

#ifdef CHECK_ATAN2
float64_t my_div( float64_t y, float64_t x ) {
	float64_t res = f_div( y, x );
	int i1 = fp64_isinf(y);
	int i2 = fp64_isinf(x);
	// f_div does not handle sign correctly for +/-inf
	if( i1 || i2 ) {
		// ddump( res );
		int sign_y = y >> 63;
		int sign_x = x >> 63;
		res &= 0x7fffffffffffffffLLU;
		if( sign_y^sign_x )
			res ^= 0x8000000000000000LLU;
		// dump( res, "res after" );
	}
	return( res );
}
				
float64_t my_atan2( float64_t y, float64_t x ) {
	float64_t res;
	float64_t disp = float64_NUMBER_PLUS_ZERO;

	int sign_y = y >> 63;
	int sign_x = x >> 63;
	float64_t y2 = y & 0x7fffffffffffffffLLU;
	float64_t x2 = x & 0x7fffffffffffffffLLU;
	if( fp64_isnan(y) || fp64_isnan(x) )
		return( float64_ONE_POSSIBLE_NAN_REPRESENTATION );
	if( y2 == float64_NUMBER_PLUS_ZERO || fp64_isinf(x) ) {
		res = sign_y ? 0x8000000000000000LLU : float64_NUMBER_PLUS_ZERO;
		if( fp64_isinf(y) && fp64_isinf(x) ) 
			return( float64_ONE_POSSIBLE_NAN_REPRESENTATION );
		else if( sign_x )
			return( res | float64_NUMBER_PI );
		else
			return( res );
	}
	if( y2 <= x2 ) {
		res = f_arctan( my_div(y,x) );
		if( sign_x ) {
			disp = float64_NUMBER_PI;
			if( sign_y )
				disp ^= 0x8000000000000000LLU;
		} else {
			return( res );
		}
	} else {
		res = f_arctan( my_div(x,y) );
		res ^= 0x8000000000000000LLU;
		disp = float64_NUMBER_PIO2;
		if( sign_y )
			disp ^= 0x8000000000000000LLU;
	}
	// ddump( res );
	// ddump( disp );
	res = f_add( res, disp );
	return( res );
}

const struct check_atan2_table_t {
	double y;
	double x;
}  check_atan2_table[] = {
	{ 1, 1 }, 
	{ 1, 2 },
	{ 2, 1 },
	{ -1, 1 }, 
	{ -1, 2 },
	{ -2, 1 },
	{ -0.5016084, -0.5000116 },
	{ -0.5016715, -0.4999826 },
	{ -0.5017346, -0.4999537 }
};


void check_atan2() {
	float64_t x, y, res, res2;
	float xf, yf, resf, res2f, diff;
	bool ok;
	
	Serial.println(F("--------- check fp64_atan2 ---------"));
	struct fp64_debug_t* xd = __fp64_debugAB();
	
	for( int i = 0; i < 9; i++ ) {
		yf = check_atan2_table[i].y;
		xf = check_atan2_table[i].x;
		for( int j = 0; j < 2; j ++ ) {
			y = fp64_sd( yf );
			x = fp64_sd( xf );
			dddump( y );
			dddump( x );

			res = fp64_atan2( y, x );
			dump_debug( xd ); // dump intermediate result			
			dump_debug( xd+1 );
			dddump( res );
			
			res2 = my_atan2( y, x );
			dddump( res2 );
			check_diff( res, res2 );
			
			resf = f_ds( res );
			res2f = atan2( yf, xf );
			diff = resf - res2f;
			Serial.println(F("fp64_atan2"));
			Serial.print( "    yf:"); Serial.print(yf,6);
			Serial.print( "    xf:"); Serial.print(xf,6);
			Serial.print( "  resf:"); Serial.print(resf,6);
			Serial.print( " res2f:"); Serial.print(res2f,6);
			Serial.print( "  diff:"); Serial.println(diff,8);
			if( isnan(diff) && isnan(resf) && isnan(res2f) ) {
				check( ok = true );
			} else {
				if( diff == 0.0f || res2f == 0.0f )
					ok = (resf == res2f);
				else 
					ok = fabs(diff) < 1.0e-6;
				
				Serial.print( fabs(xf) == 0.0f ); Serial.print( fabs(yf) == 0.0f );
				if( !ok && fabs(xf) == 0.0f && fabs(yf) == 0.0f ) {
					check( ok = true );
					Serial.print( F("OVERRIDE +/-0 "));
				} else 
					check( ok );
			}
			Serial.println(F("fp64_atan2"));
			Serial.println();
			xf = -xf;
			yf = -yf;
		}
	}
	
	Serial.println();
	
	for( int i = 0; i < check_table1_size; i++ ) {
	// for( int i = 0; i < 10; i++ ) {
		y = get_check_table1(i)->x;
		yf = f_ds( y );
		for( int j = 0; j < check_table1_size; j++ ) {
			Serial.print(i); Serial.print("+"); Serial.println(j);
			x = get_check_table1(j)->x;
			xf = f_ds( x );
			dddump( y );
			dddump( x );
	
			res = fp64_atan2( y, x );
			dump_debug( xd ); // dump intermediate result			
			dump_debug( xd+1 );
			dddump( res );
			
			res2 = my_atan2( y, x );
			dddump( res2 );
			if( res != res2 && (isSubnormal(y) || isSubnormal(x)) ) {
				check( ok = true );
				Serial.print( F("OVERRIDE subn "));
			} else 
				check_diff( res, res2 );
			resf = f_ds( res );
			res2f = atan2( yf, xf );
			diff = resf - res2f;
			Serial.println(F("fp64_atan2"));
			Serial.print( "    yf:"); Serial.print(yf,6);
			Serial.print( "    xf:"); Serial.print(xf,6);
			Serial.print( "  resf:"); Serial.print(resf,6);
			Serial.print( " res2f:"); Serial.print(res2f,6);
			Serial.print( "  diff:"); Serial.println(diff,8);
			if( isnan(diff) && isnan(resf) && isnan(res2f) ) {
				check( ok = true );
			} else {
				if( diff == 0.0f || res2f == 0.0f )
					ok = (resf == res2f);
				else 
					ok = fabs(diff) < 1.0e-6;
				
				//hexDump( (char*) &xf, 4 ); Serial.print(fabs(xf),6); 
				Serial.print("x"); Serial.print( fabs(xf) == 0.0f ); 
				//hexDump( (char*) &yf, 4 ); Serial.print(fabs(yf),6); 
				Serial.print("y"); Serial.print( fabs(yf) == 0.0f ); Serial.print(ok);
				if( !ok && fabs(xf) == 0.0f && fabs(yf) == 0.0f ) {
					check( ok = true );
					Serial.print( F("OVERRIDE +/-0 "));
				} else if( !ok && (isSubnormal(y) || isSubnormal(x) || *((uint32_t*)&xf) == 0x00800000 || *((uint32_t*)&yf) == 0x00800000) ) {
					check( ok = true );
					Serial.print( F("OVERRIDE subn "));
				} if( !ok && isinf(yf) && isinf(xf) ) {
					check( ok = true );
					Serial.print( F("OVERRIDE inf "));
				} else 
					check( ok );
			}
			Serial.println(F("fp64_atan2"));
			Serial.println();
		}
		Serial.println();
	}

#ifdef WITH_TIMING
	Serial.println(F("--------- timing fp64_atan2 ---------"));
	timeIt( float64_NUMBER_ONE,f_NUMBER_2,fp64_atan2, "fp64_atan2", true);
	timeIt( float64_NUMBER_ONE,f_NUMBER_2,my_atan2, "my_atan2", false);
	timeIt( f_NUMBER_2,float64_NUMBER_ONE,fp64_atan2, "fp64_atan2", true);
	timeIt( f_NUMBER_2,float64_NUMBER_ONE,my_atan2, "my_atan2", false);
	timeIt( float64_MINUS_NUMBER_ONE,f_NUMBER_2,fp64_atan2, "fp64_atan2", true);
	timeIt( float64_MINUS_NUMBER_ONE,f_NUMBER_2,my_atan2, "my_atan2", false);
	timeIt( f_NUMBER_2,float64_MINUS_NUMBER_ONE,fp64_atan2, "fp64_atan2", true);
	timeIt( f_NUMBER_2,float64_MINUS_NUMBER_ONE,my_atan2, "my_atan2", false);

#endif
	
}
#endif

#ifdef CHECK_PROXY
extern byte __before[32];
extern byte __after[32];
byte dontChange[32] = {
 //31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
	0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 };
bool check_stack( bool doPrint ) {
	
	uint8_t diff = 0;
	for( int i = 0; i < 32; i++ ) {
		if( __before[i] != __after[i] && dontChange[i] )
			diff++;
	}
	check( diff == 0 );
	Serial.println();
	if( diff || doPrint ) {
	   for( int i = 31; i > 9; i-- ) {
		   Serial.print( i ); Serial.print( " " );
	   }
	   Serial.println(" 9  8  7  6  5  4  3  2  1  0");
	   for( int i = 0; i < 32; i ++ ) {
		   Serial.print( toHex2(__before[i]) ); Serial.print(" ");
	   }
	   Serial.println();
	   for( int i = 0; i < 32; i ++ ) {
		   Serial.print( toHex2(__after[i]) ); Serial.print(" ");
	   }
	   Serial.println();
	   for( int i = 0; i < 32; i ++ ) {
		   Serial.print( __before[i] == __after[i] ? "   " : (dontChange[i] ? "!* " : " * "));
	   }
	   Serial.println();
	}
	return( diff == 0 );
}

void check_proxy_fun1( int16_t (*f)(float64_t), const char* s ) {
   float64_t a, res;

   struct fp64_debug_t* xd = __fp64_debugAB();
   Serial.print( "-------- proxy1 " ); Serial.print(s); 
   Serial.print("@"); Serial.print( (uint16_t) f, HEX );
   Serial.println( " ---------" );
   for( int i = 0; i < check_table1_size; i++ ) {
	  a = get_check_table1(i)->x;
	  Serial.println(i);
	  // Serial.println( (uint16_t) &a, HEX );
	  ddump(a); Serial.flush();
	  res = __fp64_proxy1_int16( f, &a );
	  dump_debug( xd ); // dump intermediate result			
	  dump_debug( xd+1 );
	  ddump(res); 
	  Serial.print( s ); Serial.print(" ");
	  check_stack( false ); 
	  Serial.println();
   }
   Serial.println();
}

void check_proxy_fun1_int8( int8_t (*f)(float64_t), const char* s ) {
   int8_t res;
   float64_t a;

   struct fp64_debug_t* xd = __fp64_debugAB();
   Serial.print( "-------- proxy1_int16 " ); Serial.print(s); 
   Serial.print("@"); Serial.print( (uint16_t) f, HEX );
   Serial.println( " ---------" );
   for( int i = 0; i < check_table1_size; i++ ) {
	  a = get_check_table1(i)->x;
	  Serial.println(i);
	  // Serial.println( (uint16_t) &a, HEX );
	  ddump(a); Serial.flush();
	  res = __fp64_proxy1_int8( f, &a );
	  dump_debug( xd ); // dump intermediate result			
	  dump_debug( xd+1 );
	  Serial.println(res); 
	  Serial.print( s ); Serial.print(" ");
	  check_stack( false ); 
	  Serial.println();
   }
   Serial.println();
}

void check_proxy_fun1_int16( int16_t (*f)(float64_t), const char* s ) {
   int16_t res;
   float64_t a;

   struct fp64_debug_t* xd = __fp64_debugAB();
   Serial.print( "-------- proxy1_int16 " ); Serial.print(s); 
   Serial.print("@"); Serial.print( (uint16_t) f, HEX );
   Serial.println( " ---------" );
   for( int i = 0; i < check_table1_size; i++ ) {
	  a = get_check_table1(i)->x;
	  Serial.println(i);
	  // Serial.println( (uint16_t) &a, HEX );
	  ddump(a); Serial.flush();
	  res = __fp64_proxy1_int16( f, &a );
	  dump_debug( xd ); // dump intermediate result			
	  dump_debug( xd+1 );
	  Serial.println(res); 
	  Serial.print( s ); Serial.print(" ");
	  check_stack( false ); 
	  Serial.println();
   }
   Serial.println();
}

void check_proxy_fun1_int32( int32_t (*f)(float64_t), const char* s ) {
   int32_t res;
   float64_t a;

   struct fp64_debug_t* xd = __fp64_debugAB();
   Serial.print( "-------- proxy1_int32 " ); Serial.print(s); 
   Serial.print("@"); Serial.print( (uint16_t) f, HEX );
   Serial.println( " ---------" );
   for( int i = 0; i < check_table1_size; i++ ) {
	  a = get_check_table1(i)->x;
	  Serial.println(i);
	  // Serial.println( (uint16_t) &a, HEX );
	  ddump(a); Serial.flush();
	  res = __fp64_proxy1_int32( f, &a );
	  dump_debug( xd ); // dump intermediate result			
	  dump_debug( xd+1 );
	  Serial.println(res); 
	  Serial.print( s ); Serial.print(" ");
	  check_stack( false ); 
	  Serial.println();
   }
   Serial.println();
}

void check_proxy_fun1_int64( int64_t (*f)(float64_t), const char* s ) {
   int64_t res;
   float64_t a;

   struct fp64_debug_t* xd = __fp64_debugAB();
   Serial.print( "-------- proxy1_int32 " ); Serial.print(s); 
   Serial.print("@"); Serial.print( (uint16_t) f, HEX );
   Serial.println( " ---------" );
   for( int i = 0; i < check_table1_size; i++ ) {
	  a = get_check_table1(i)->x;
	  Serial.println(i);
	  // Serial.println( (uint16_t) &a, HEX );
	  ddump(a); Serial.flush();
	  res = __fp64_proxy1_int64( f, &a );
	  dump_debug( xd ); // dump intermediate result			
	  dump_debug( xd+1 );
	  dumpLong( (uint8_t*) &res, "res"); 
	  Serial.print( s ); Serial.print(" ");
	  check_stack( false ); 
	  Serial.println();
   }
   Serial.println();
}

void check_proxy_fun2( f2ptr f, const char* s ) {
   float64_t a, b, res;

   struct fp64_debug_t* xd = __fp64_debugAB();
   Serial.print( "-------- proxy2 " ); Serial.print(s); 
   Serial.print("@"); Serial.print( (uint16_t) f, HEX );
   Serial.println( " ---------" );
   for( int i = 0; i < check_mult_table_size; i++ ) {
	  a = get_mult_table(i)->a;
	  b = get_mult_table(i)->b;
	  Serial.println(i);
	  // Serial.println( (uint16_t) &a, HEX );
	  ddump(a);
	  // Serial.println( (uint16_t) &b, HEX );
	  ddump(b); Serial.flush();
	  res = __fp64_proxy2( f, &a, &b );
	  dump_debug( xd ); // dump intermediate result			
	  dump_debug( xd+1 );
	  ddump(res); 
	  Serial.print( s ); Serial.print(" ");
	  check_stack( false ); 
	  Serial.println();
   }
   Serial.println();
}

void check_proxy_fun2_int8( int8_t (*f)(float64_t, float64_t), const char* s ) {
   float64_t a, b;
   int8_t res;

   struct fp64_debug_t* xd = __fp64_debugAB();
   Serial.print( "-------- proxy2_int8 " ); Serial.print(s); 
   Serial.print("@"); Serial.print( (uint16_t) f, HEX );
   Serial.println( " ---------" );
   for( int i = 0; i < check_mult_table_size; i++ ) {
	  a = get_mult_table(i)->a;
	  b = get_mult_table(i)->b;
	  Serial.println(i);
	  ddump(a);
	  ddump(b); Serial.flush();
	  res = __fp64_proxy2_int8( f, &a, &b );
	  dump_debug( xd ); // dump intermediate result			
	  dump_debug( xd+1 );
	  Serial.println(res);
	  Serial.print( s ); Serial.print(" ");
	  check_stack( false ); 
	  Serial.println();
   }
   Serial.println();
}

void check_proxy() {
	
   // all functions with 2 float64_t parameters, returning float64_t
   check_proxy_fun2( fp64_div, "fp64_div" );
   check_proxy_fun2( fp64_mul, "fp64_mul" );
   check_proxy_fun2( fp64_add, "fp64_add" );
   check_proxy_fun2( fp64_sub, "fp64_sub" );
   check_proxy_fun2( fp64_fmin, "fp64_fmin" );
   check_proxy_fun2( fp64_fmax, "fp64_fmax" );
   check_proxy_fun2( fp64_fdim, "fp64_fdim" );
   check_proxy_fun2( fp64_pow, "fp64_pow" );
   check_proxy_fun2( fp64_hypot, "fp64_hypot" );
   check_proxy_fun2( fp64_atan2, "fp64_atan2" );
   
   // all functions with 1 float64_t parameter, returning float64_t
   check_proxy_fun1( fp64_neg, "fp64_neg" );
   check_proxy_fun1( fp64_abs, "fp64_abs" );
   check_proxy_fun1( fp64_inverse, "fp64_inverse" );
   check_proxy_fun1( fp64_sqrt, "fp64_sqrt" );
   check_proxy_fun1( fp64_square, "fp64_square" );
   check_proxy_fun1( fp64_trunc, "fp64_trunc" );
   check_proxy_fun1( fp64_ceil, "fp64_ceil" );
   check_proxy_fun1( fp64_floor, "fp64_floor" );
   check_proxy_fun1( fp64_round, "fp64_round" );
   check_proxy_fun1( fp64_cbrt, "fp64_cbrt" );
   check_proxy_fun1( fp64_sin, "fp64_sin" );
   check_proxy_fun1( fp64_cos, "fp64_cos" );
   check_proxy_fun1( fp64_tan, "fp64_tan" );
   check_proxy_fun1( fp64_atan, "fp64_atan" );
   check_proxy_fun1( fp64_asin, "fp64_asin" );
   check_proxy_fun1( fp64_acos, "fp64_acos" );
   check_proxy_fun1( fp64_log, "fp64_log" );
   check_proxy_fun1( fp64_exp, "fp64_exp" );
   check_proxy_fun1( fp64_log10, "fp64_log10" );
   check_proxy_fun1( fp64_sinh, "fp64_sinh" );
   check_proxy_fun1( fp64_cosh, "fp64_cosh" );
   check_proxy_fun1( fp64_tanh, "fp64_tanh" );

   // all functions with 1 float64_t parameter, returning int8_t
   check_proxy_fun1_int8( fp64_to_int8, "fp64_to_int8" );

   // all functions with 1 float64_t parameter, returning int16_t
   check_proxy_fun1_int16( fp64_classify, "fp64_classify" );
   check_proxy_fun1_int16( fp64_isinf, "fp64_isinf" );
   check_proxy_fun1_int16( fp64_isnan, "fp64_isnan" );
   check_proxy_fun1_int16( fp64_isfinite, "fp64_isfinite" );
   check_proxy_fun1_int16( fp64_signbit, "fp64_signbit" );
   check_proxy_fun1_int16( fp64_to_int16, "fp64_to_int16" );

   // all functions with 1 float64_t parameter, returning int32_t
   check_proxy_fun1_int32( fp64_lround, "fp64_lround" );
   check_proxy_fun1_int32( fp64_lrint, "fp64_lrint" );
   check_proxy_fun1_int32( fp64_to_int32, "fp64_to_int32" );

   // all functions with 1 float64_t parameter, returning int64_t
   check_proxy_fun1_int64( fp64_to_int64, "fp64_to_int64" );

   // all functions with 2 float64_t parameters, returning int8_t
   check_proxy_fun2_int8( fp64_compare, "fp64_compare" );
   // check_proxy_fun2( fp64_modf, "fp64_modf" );
	
#define C180 ((float64_t)0x4066800000000000LLU)  /* fails */
// #define C180 (fp64_sd(180.0))    /* works */

   struct fp64_debug_t* xd = __fp64_debugAB();
   for( int c = 0; c < 10; c++ ) {

	  uint8_t b = (c%2);
	  float64_t a = fp64_sd(c%360);
	  float64_t f;

	  if (b == 1) {
		 Serial.println("cos()");
		 f = fp64_cos(fp64_mul(fp64_div(a,C180), float64_NUMBER_PI));
	  } else {
		 Serial.println("sin()");
		 f = fp64_sin(fp64_mul(fp64_div(a,C180), float64_NUMBER_PI));
	  }
	  dump_debug( xd );
	  dump_debug( xd+1 );
	  ddump(f);
   }
}
#endif

void setup() {
#ifdef ARDUINO_AVR_MEGA2560
	Serial.begin(230400);
#else
	Serial.begin(57600);
#endif
	Serial.println(F("starting test of fp64"));
	
	dddump( fp64_int32_to_float64(22) );
	dddump( fp64_int32_to_float64(355) );
	
#ifdef CHECK_DUMP
	Serial.print(F("int ")); Serial.println( sizeof(int) );
	Serial.print(F("long ")); Serial.println( sizeof(long) );
	Serial.print(F("long long ")); Serial.println( sizeof(long long) );
	Serial.print(F("float ")); Serial.println( sizeof(float) );
	Serial.print(F("double ")); Serial.println( sizeof(double) );
	Serial.print(F("float64_t ")); Serial.println( sizeof(float64_t) );

	Serial.println(F("--------- Basic dumps ---------"));
	dddump( float64_NUMBER_PLUS_ZERO );
	dddump( __fp64_zero() );
	dddump( float64_NUMBER_ONE );
	dddump( float64_MINUS_NUMBER_ONE );
	dddump( 0x3fffffffffffffffLLU );
	dddump( float64_ONE_POSSIBLE_NAN_REPRESENTATION );
	for( int i = 0; i < 4; i++ ) {
		dddump( __fp64_nan() );
	}

	Serial.println(F("--------- Double dumps ---------"));
	dddump( float64_NUMBER_PLUS_ZERO );
	// struct fp64_debug_t* xdb = __fp64_debugAB();
	for( int i = 0; i < check_table1_size; i++ ) {
		for( int j = i; j < check_table1_size; j++ ) {
			float64_t a = get_check_table1(i)->x;
			float64_t b = check_table1[j].x;		
			// __fp64_split3(a,b);
			// Serial.print("a[");Serial.print(i);Serial.print("] before "); dump_debug( xdb );
			// Serial.print("b[");Serial.print(j);Serial.print("] before "); dump_debug( xdb+1 );
			__fp64_split3(a,b);	
			struct fp64_debug_t* xd = __fp64_debugAB();
			Serial.print("a[");Serial.print(i);Serial.print("] after  "); dump_debug( xd );
			Serial.print("b[");Serial.print(j);Serial.print("] after  "); dump_debug( ++xd );
			Serial.println();
			if( i != j ) {
				// __fp64_split3(b,a);
				// Serial.print("a[");Serial.print(j);Serial.print("] before "); dump_debug( xdb );
				// Serial.print("b[");Serial.print(i);Serial.print("] before "); dump_debug( xdb+1 );
				__fp64_split3(b,a);	
				struct fp64_debug_t* xd = __fp64_debugAB();
				Serial.print("a[");Serial.print(j);Serial.print("] after  "); dump_debug( xd );
				Serial.print("b[");Serial.print(i);Serial.print("] after  "); dump_debug( ++xd );
				Serial.println();
			}
		}
	}
#endif
#ifdef CHECK_ISXXX
	check_isxxx();
#endif
#ifdef CHECK_MULT	
	check_mult();
#endif
#ifdef CHECK_FN
	check_fn();
#endif
#ifdef CHECK_ADD	
	check_add();
#endif
#ifdef CHECK_SUB	
	check_sub();
#endif
#ifdef CHECK_DIV	
	check_div();
#endif
#ifdef CHECK_FMOD
	check_fmod();
#endif
#ifdef CHECK_CMP
	check_compare();
#endif
#ifdef CHECK_CONV
	check_conv();
#endif
#ifdef CHECK_TRIG
	check_trig();
#endif
#ifdef CHECK_POWSER
	check_powser();
#endif
#ifdef CHECK_LOG
	check_log();
#endif
#ifdef CHECK_EXP
	check_exp();
#endif
#ifdef CHECK_10POWN
	check_pown();
#endif
#ifdef CHECK_FTOA
	check_ftoa();
#endif
#ifdef CHECK_ATOF
	check_atof();
#endif
#ifdef CHECK_TOSTRING
	check_to_string();
#endif
#ifdef CHECK_TOINT
	check_to_int();
#endif
#ifdef CHECK_TOFLOAT
	check_to_float();
#endif
#ifdef CHECK_LDEXP
	check_ldexp();
#endif
#ifdef CHECK_FDIM
	check_fdim();
#endif
#ifdef CHECK_POW
	check_pow();
#endif
#ifdef CHECK_HYPOT
	check_hypot();
#endif
#ifdef CHECK_FREXP
	check_frexp();
#endif
#ifdef CHECK_FMA
	check_fma();
#endif
#ifdef CHECK_TRIGH
	check_trigh();
#endif
#ifdef CHECK_ATAN2
	check_atan2();
#endif
#ifdef CHECK_PROXY
	check_proxy();
#endif

	// print summary
#ifdef WITH_TIMING
	dumpTimings();
#endif
	int testTotalPrec = 0;
	for( int i = 0; i < 8; i++ )
		testTotalPrec += testPrec[i];
	Serial.println(F("--------- test cases -----------"));
	Serial.print(F("Passed:")); Serial.println(testPassed);
	Serial.print(F("Failed:")); Serial.println(testFailed);
	Serial.print(F(" Total:")); Serial.println(testPassed+testFailed);
	Serial.println(F("---------------------------------"));
	long avg = 0;
	for( int i = 0; i < 7; i ++ ) {
		Serial.print(i+1);
		Serial.print(F("ulp: ")); Serial.println( testPrec[i] );
		avg += (i+1)*testPrec[i];
	}
	Serial.print(F(">7ulp:")); Serial.println( testPrec[7] );
	avg += 8*testPrec[7];
	Serial.print(F("  avg:")); Serial.println( (float) avg / (float) (testPassed+testTotalPrec) );
	Serial.println(F("-----------"));
	Serial.print(F("total:")); Serial.println( testTotalPrec );
	Serial.print(F(" sign:")); Serial.println( testSign );
	Serial.print(F("other:")); Serial.println( testFailed-testSign-testTotalPrec );

  //dump( f_div(f_sd(180.0),f_NUMBER_PI) );
  //dump( f_div(f_sd(200.0),f_NUMBER_PI) );
  //dump( f_log(f_sd(10.0)) );
  //dump( f_NUMBER_PI );
  //dump( f_sd(0.01) );
  //dump( f_div(float64_NUMBER_ONE,f_sd(100.0) ));
  //dump( f_sd(100.0) );
  //dump( f_sd(60.0) );
  //dump(f_mult(f_mult(f_NUMBER_60,f_NUMBER_001),f_NUMBER_001));
  //dump(f_div(f_div(f_NUMBER_100,f_NUMBER_60),f_NUMBER_60));
  
  /*
  for( dispMode = FIX; dispMode <= ENG; dispMode++ ) {
  dummy = f_NUMBER_PI;
  for( int i = 0; i < 10; i++ ) {
    char *fullResult = f_to_decimalExp(dummy, (uint8_t) 17, (uint8_t) 1, &exponent ); 
    Serial.print(" d:");Serial.print(fullResult);Serial.print("E");Serial.println(exponent);
    for( dispDigits = 0; dispDigits < 10; dispDigits++ ) {
      char *s = convertToString(dummy);
      Serial.print( dispDigits ); Serial.print(":"); Serial.print(s); Serial.print(" len="); Serial.println(strlen(s));
    }
    dummy = f_mult(dummy,f_sd(10.0));
  }
  dummy = f_NUMBER_PI;
  for( int i = 0; i < 10; i++ ) {
    dummy = f_div(dummy,f_sd(10.0));
    char *fullResult = f_to_decimalExp(dummy, (uint8_t) 17, (uint8_t) 1, &exponent ); 
    Serial.print(" d:");Serial.print(fullResult);Serial.print("E");Serial.println(exponent);
    for( dispDigits = 0; dispDigits < 10; dispDigits++ ) {
      char *s = convertToString(dummy);
      Serial.print( dispDigits ); Serial.print(":"); Serial.print(s); Serial.print(" len="); Serial.println(strlen(s));
    }
  }
  }
  */
    pinMode(led, OUTPUT);     
}

#if USE_GAMMA > 1
// gamma function (lanczos approximation) 
// sources: https://en.wikipedia.org/wiki/Lanczos_approximation
//          https://rosettacode.org/wiki/Gamma_function
float64_t f_gamma(float64_t zpar) {
  const static float64_t par[9] = {
    ((float64_t)0x3feffffffffff950LLU), //    0.99999999999980993
    ((float64_t)0x40852429b6c30b05LLU), //  676.5203681218851
    ((float64_t)0xc093ac8e8ed4171bLLU), //-1259.1392167224028
    ((float64_t)0x40881a9661d3b4d8LLU), //  771.32342877765313
    ((float64_t)0xc06613ae51a32f5dLLU), // -176.61502916214059
    ((float64_t)0x402903c27f8b9c81LLU), //   12.507343278686905
    ((float64_t)0xbfc1bcb2992b2855LLU), //   -0.13857109526572012
    ((float64_t)0x3ee4f0514e4e324fLLU), //    9.9843695780195716E-6
    ((float64_t)0x3e8435508f3faeefLLU)  //    1.5056327351493116E-7
  };
  const static float64_t sqrt2pi =     ((float64_t)0x40040d931ff62705LLU);    // sqrt(2*pi) = 2.5066282746310002
  const static float64_t f_NUMBER_65 = ((float64_t)0x401a000000000000LLU);   //6.5

  float64_t tt = f_add(zpar,f_NUMBER_65);
  float64_t res = par[0];
  float64_t zz = zpar;
  for( byte i = 1; i < 9; i++ ) {
    res = f_add(res,f_div(par[i],zz));
    zz = f_add(zz, float64_NUMBER_ONE);
    //Serial.print(i); Serial.print(convertToString(res)); Serial.print(" "); Serial.println(convertToString(zz));
  }
  res = f_mult(res, f_mult(sqrt2pi, f_mult(f_pow(tt,f_sub(zpar,f_NUMBER_0_5)),f_exp(f_sub(float64_NUMBER_PLUS_ZERO,tt)))));
  return res;
}

float64_t fp64_gamma(float64_t zpar) {
  const static float64_t par[9] = {
    ((float64_t)0x3feffffffffff950LLU), //    0.99999999999980993
    ((float64_t)0x40852429b6c30b05LLU), //  676.5203681218851
    ((float64_t)0xc093ac8e8ed4171bLLU), //-1259.1392167224028
    ((float64_t)0x40881a9661d3b4d8LLU), //  771.32342877765313
    ((float64_t)0xc06613ae51a32f5dLLU), // -176.61502916214059
    ((float64_t)0x402903c27f8b9c81LLU), //   12.507343278686905
    ((float64_t)0xbfc1bcb2992b2855LLU), //   -0.13857109526572012
    ((float64_t)0x3ee4f0514e4e324fLLU), //    9.9843695780195716E-6
    ((float64_t)0x3e8435508f3faeefLLU)  //    1.5056327351493116E-7
  };
  const static float64_t sqrt2pi =     ((float64_t)0x40040d931ff62705LLU);    // sqrt(2*pi) = 2.5066282746310002
  //const static float64_t f_NUMBER_05 = ((float64_t)0x3fe0000000000000LLU);   //0.5
  const static float64_t f_NUMBER_65 = ((float64_t)0x401a000000000000LLU);   //6.5

  float64_t tt = fp64_add(zpar,f_NUMBER_65);
  float64_t res = par[0];
  float64_t zz = zpar;
  for( byte i = 1; i < 9; i++ ) {
    res = fp64_add(res,fp64_div(par[i],zz));
    zz = fp64_add(zz, float64_NUMBER_ONE);
    //Serial.print(i); Serial.print(convertToString(res)); Serial.print(" "); Serial.println(convertToString(zz));
  }
  res = fp64_mul(res, fp64_mul(sqrt2pi, fp64_mul(f_pow(tt,fp64_sub(zpar,f_NUMBER_0_5)),f_exp(fp64_sub(float64_NUMBER_PLUS_ZERO,tt)))));
  return res;
}

#endif

void loop() {
static bool once = true;
if( once ) {	
  once = !once;

	float64_t A, B, C, b2, c2;
	A = fp64_atof("1.23456789");
	B = fp64_trunc(A);
	C = fp64_sub(A,B);
	b2 = fp64_modf( A, &c2 );
	Serial.print("A:");
	Serial.println(fp64_to_string(A, 15, 18));

	Serial.print("B:");
	Serial.println(fp64_to_string(B, 15, 18));
	Serial.print("b2:");
	Serial.println(fp64_to_string(b2, 15, 18));

	Serial.print("C:");
	Serial.println(fp64_to_string(C, 15, 18));
	Serial.print("C2:");
	Serial.println(fp64_to_string(c2, 15, 18));
}
  digitalWrite(led, HIGH);   // turn the LED on (HIGH is the voltage level)
  delay(1000);               // wait for a second
  digitalWrite(led, LOW);    // turn the LED off by making the voltage LOW
  delay(1000);               // wait for a second
 
}

