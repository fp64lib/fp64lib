/*	A fp64lib-Arduino version of Kahan's Floating Point Test "Paranoia"
    
	This is based on the C version, which is a rewrite from a Pascal version,
	based on the original BASIC version of Professor W. M. Kahan, one
	of the fathers of the IEEE 754 standard, fp64lib is based on.
	
	For more details and the original copyright, see https://www.netlib.org/paranoia/
	and https://people.math.sc.edu/Burkardt/c_src/paranoia/paranoia.html
*/ 

#define NO_RELEASE
int led = 13;				// pin of onboard-led for blinking

#include <avr/pgmspace.h>
#ifdef NO_RELEASE
#include "Double.h"
#else
#include <Double.h>
#endif

#define FABS(x) 	Double::fabs(x)
#define LOG(x) 		Double::log(x)
#define POW(x,y) 	Double::pow((x),(y))
#define SQRT(x) 	Double::sqrt(x)

#define CHARP char *
#define CHARPP char **

char buf[128];

Double Sign(Double), Random(void);
extern void BadCond(int, char*);
extern void SqXMinX(int);
extern void TstCond(int, int, char*);
extern void notify(char*);
extern int read(int, char*, int);

extern void Characteristics(void);
extern void Heading(void);
extern void History(void);
extern void Instructions(void);
extern void IsYeqX(void);
extern void NewD(void);
extern void Pause(void);
extern void PrintIfNPositive(void);
extern void SR3750(void);
extern void SR3980(void);
extern void TstPtUf(void);

#define KEYBOARD 0

Double Radix, BInvrse, RadixD2, BMinusU2;

/*Small floating point constants.*/
Double Zero = 0.0;
Double Half = 0.5;
Double One = 1.0;
Double Two = 2.0;
Double Three = 3.0;
Double Four = 4.0;
Double Five = 5.0;
Double Eight = 8.0;
Double Nine = 9.0;
Double TwentySeven = 27.0;
Double ThirtyTwo = 32.0;
Double TwoForty = 240.0;
Double MinusOne = -1.0;
Double OneAndHalf = 1.5;
/*Integer constants*/
int NoTrials = 20; /*Number of tests for commutativity. */
#define False 0
#define True 1

/* Definitions for declared types 
	Guard == (Yes, No);
	Rounding == (Chopped, Rounded, Other);
	Message == packed array [1..40] of char;
	Class == (Flaw, Defect, Serious, Failure);
	  */
#define Yes 1
#define No  0
#define Chopped 2
#define Rounded 1
#define Other   0
#define Flaw    3
#define Defect  2
#define Serious 1
#define Failure 0
typedef int Guard, Rounding, Class;
typedef char Message;

/* Declarations of Variables */
int Indx;
char ch[8];
Double AInvrse, Aone;
Double C, CInvrse;
Double D, FourD;
Double E0, E1, Exp2, E3, MinSqEr;
Double SqEr, MaxSqEr, E9;
Double Third;
Double F6, F9;
Double H, HInvrse;
int I;
Double StickyBit, J;
Double MyZero;
Double Precision;
Double Q, Q9;
Double R, Random9;
Double T, Underflow, S;
Double OneUlp, UfThold, U1, U2;
Double V, V0, V9;
Double W;
Double X, X1, X2, X8, Random1;
Double Y, Y1, Y2, Random2;
Double Z, PseudoZero, Z1, Z2, Z9;
int ErrCnt[4];
int fpecount;
int Milestone;
int PageNo;
int M, N, N1;
Guard GMult, GDiv, GAddSub;
Rounding RMult, RDiv, RAddSub, RSqrt;
int Break, Done, NotMonot, Monot, Anomaly, IEEE,
		SqRWrng, UfNGrad;
/* Computed constants. */
/*U1  gap below 1.0, i.e, 1.0-U1 is next number below 1.0 */
/*U2  gap above 1.0, i.e, 1.0+U2 is next number above 1.0 */


void setup(void) {
#ifdef ARDUINO_AVR_MEGA2560
	Serial.begin(230400);
#else
	Serial.begin(230400);
#endif
    pinMode(led, OUTPUT);     
	
	
	/* First two assignments use integer right-hand sides. */
	Zero = 0;
	One = 1;
	Two = One + One;
	Three = Two + One;
	Four = Three + One;
	Five = Four + One;
	Eight = Four + Four;
	Nine = Three * Three;
	TwentySeven = Nine * Three;
	ThirtyTwo = Four * Eight;
	TwoForty = Four * Five * Three * Four;
	MinusOne = -One;
	Half = One / Two;
	OneAndHalf = One + Half;
	ErrCnt[Failure] = 0;
	ErrCnt[Serious] = 0;
	ErrCnt[Defect] = 0;
	ErrCnt[Flaw] = 0;
	PageNo = 1;
	/*=============================================*/
	Milestone = 0;
	/*=============================================*/
	Instructions();
	Pause();
	Heading();
	Pause();
	Characteristics();
	Pause();
	History();
	Pause();
	/*=============================================*/
	Milestone = 7;
	/*=============================================*/
	Serial.print( F("Program is now RUNNING tests on small integers:\n") );
	
	TstCond (Failure, (Zero + Zero == Zero) && (One - One == Zero)
		   && (One > Zero) && (One + One == Two),
			"0+0 != 0, 1-1 != 0, 1 <= 0, or 1+1 != 2");
	Z = - Zero;
	if (Z != 0.0) {
		ErrCnt[Failure] = ErrCnt[Failure] + 1;
		Serial.print( F("Comparison alleges that -0.0 is Non-zero!\n") );
		U2 = 0.001;
		Radix = 1;
		TstPtUf();
		}
	TstCond (Failure, (Three == Two + One) && (Four == Three + One)
		   && (Four + Two * (- Two) == Zero)
		   && (Four - Three - One == Zero),
		   "3 != 2+1, 4 != 3+1, 4+2*(-2) != 0, or 4-3-1 != 0");
	TstCond (Failure, (MinusOne == (Zero - One))
		   && (MinusOne + One == Zero ) && (One + MinusOne == Zero)
		   && (MinusOne + FABS(One) == Zero)
		   && (MinusOne + MinusOne * MinusOne == Zero),
		   "-1+1 != 0, (-1)+abs(1) != 0, or -1+(-1)*(-1) != 0");
	TstCond (Failure, Half + MinusOne + Half == Zero,
		  "1/2 + (-1) + 1/2 != 0");
	/*=============================================*/
	/*SPLIT
	{
		extern void part2(void), part3(void), part4(void),
			part5(void), part6(void), part7(void);
		int part8(void);

		part2();
		part3();
		part4();
		part5();
		part6();
		part7();
		return part8();
		}
	}
#include "paranoia.h"
void part2(void){
*/
	Milestone = 10;
	/*=============================================*/
	TstCond (Failure, (Nine == Three * Three)
		   && (TwentySeven == Nine * Three) && (Eight == Four + Four)
		   && (ThirtyTwo == Eight * Four)
		   && (ThirtyTwo - TwentySeven - Four - One == Zero),
		   "9 != 3*3, 27 != 9*3, 32 != 8*4, or 32-27-4-1 != 0");
	TstCond (Failure, (Five == Four + One) &&
			(TwoForty == Four * Five * Three * Four)
		   && (TwoForty / Three - Four * Four * Five == Zero)
		   && ( TwoForty / Four - Five * Three * Four == Zero)
		   && ( TwoForty / Five - Four * Three * Four == Zero),
		  "5 != 4+1, 240/3 != 80, 240/4 != 60, or 240/5 != 48");
	if (ErrCnt[Failure] == 0) {
		Serial.print( F("-1, 0, 1/2, 1, 2, 3, 4, 5, 9, 27, 32 & 240 are O.K.\n") );
		Serial.println();
		}
	Serial.print( F("Searching for Radix and Precision.\n") );
	W = One;
	do  {
		W = W + W;
		Y = W + One;
		Z = Y - W;
		Y = Z - One;
		} while (MinusOne + FABS(Y) < Zero);
	/*.. now W is just big enough that |((W+1)-W)-1| >= 1 ...*/
	Precision = Zero;
	Y = One;
	do  {
		Radix = W + Y;
		Y = Y + Y;
		Radix = Radix - W;
		} while ( Radix == Zero);
	if (Radix < Two) Radix = One;
	sprintf_P( buf, PSTR("Radix = %s .\n"), Radix.toString(20)); Serial.print( buf );
	if (Radix != 1) {
		W = One;
		do  {
			Precision = Precision + One;
			W = W * Radix;
			Y = W + One;
			} while ((Y - W) == One);
		}
	/*... now W == Radix^Precision is barely too big to satisfy (W+1)-W == 1
			                              ...*/
	U1 = One / W;
	U2 = Radix * U1;
	sprintf_P( buf, PSTR("Closest relative separation found is U1 = %s .\n\n"), U1.toString(20)); Serial.print( buf );
	Serial.print( F("Recalculating radix and precision\n ") );
	
	/*save old values*/
	E0 = Radix;
	E1 = U1;
	E9 = U2;
	E3 = Precision;
	
	X = Four / Three;
	Third = X - One;
	F6 = Half - Third;
	X = F6 + F6;
	X = FABS(X - Third);
	if (X < U2) X = U2;
	
	/*... now X = (unknown no.) ulps of 1+...*/
	do  {
		U2 = X;
		Y = Half * U2 + ThirtyTwo * U2 * U2;
		Y = One + Y;
		X = Y - One;
		} while ( ! ((U2 <= X) || (X <= Zero)));
	
	/*... now U2 == 1 ulp of 1 + ... */
	X = Two / Three;
	F6 = X - Half;
	Third = F6 + F6;
	X = Third - Half;
	X = FABS(X + F6);
	if (X < U1) X = U1;
	
	/*... now  X == (unknown no.) ulps of 1 -... */
	do  {
		U1 = X;
		Y = Half * U1 + ThirtyTwo * U1 * U1;
		Y = Half - Y;
		X = Half + Y;
		Y = Half - X;
		X = Half + Y;
		} while ( ! ((U1 <= X) || (X <= Zero)));
	/*... now U1 == 1 ulp of 1 - ... */
	if (U1 == E1)
		Serial.print( F("confirms closest relative separation U1 .\n") );
	else {
		sprintf_P( buf, PSTR("gets better closest relative separation U1 = %s .\n"), U1.toString(20));
		Serial.print( buf );
	}
	W = One / U1;
	F9 = (Half - U1) + Half;
	Radix = Double::floor(Double(0.01) + U2 / U1);
	if (Radix == E0)
		Serial.print( F("Radix confirmed.\n") );
	else {
		sprintf_P( buf, PSTR("MYSTERY: recalculated Radix = %s .\n"), Radix.toString(20));
		Serial.print( buf );
	}
	TstCond (Defect, Radix <= Eight + Eight,
		   "Radix is too big: roundoff problems");
	TstCond (Flaw, (Radix == Two) || (Radix == 10)
		   || (Radix == One), "Radix is not as good as 2 or 10");
	/*=============================================*/
	Milestone = 20;
	/*=============================================*/
	TstCond (Failure, F9 - Half < Half,
		   "(1-U1)-1/2 < 1/2 is FALSE, prog. fails?");
	X = F9;
	I = 1;
	Y = X - Half;
	Z = Y - Half;
	TstCond (Failure, (X != One)
		   || (Z == Zero), "Comparison is fuzzy,X=1 but X-1/2-1/2 != 0");
	X = One + U2;
	I = 0;
	/*=============================================*/
	Milestone = 25;
	/*=============================================*/
	/*... BMinusU2 = nextafter(Radix, 0) */
	BMinusU2 = Radix - One;
	BMinusU2 = (BMinusU2 - U2) + One;
	/* Purify Integers */
	if (Radix != One)  {
		X = - TwoForty * LOG(U1) / LOG(Radix);
		Y = Double::floor(Half + X);
		if (FABS(X - Y) * Four < One) X = Y;
		Precision = X / TwoForty;
		Y = Double::floor(Half + Precision);
		if (FABS(Precision - Y) * TwoForty < Half) Precision = Y;
		}
	if ((Precision != Double::floor(Precision)) || (Radix == One)) {
		Serial.print( F("Precision cannot be characterized by an Integer number\n") );
		Serial.print( F("of significant digits but, by itself, this is a minor flaw.\n") );
		}
	if (Radix == One) 
		Serial.print( F("logarithmic encoding has precision characterized solely by U1.\n") );
	else {
		sprintf_P( buf, PSTR("The number of significant digits of the Radix is %s .\n"), Precision.toString(20) );
		Serial.print( buf );
	}
	TstCond (Serious, U2 * Nine * Nine * TwoForty < One,
		   "Precision worse than 5 decimal figures  ");
	/*=============================================*/
	Milestone = 30;
	/*=============================================*/
	/* Test for extra-precise subepressions */
	X = FABS(((Four / Three - One) - One / Four) * Three - One / Four);
	do  {
		Z2 = X;
		X = (One + (Half * Z2 + ThirtyTwo * Z2 * Z2)) - One;
		} while ( ! ((Z2 <= X) || (X <= Zero)));
	X = Y = Z = FABS((Three / Four - Two / Three) * Three - One / Four);
	do  {
		Z1 = Z;
		Z = (One / Two - ((One / Two - (Half * Z1 + ThirtyTwo * Z1 * Z1))
			+ One / Two)) + One / Two;
		} while ( ! ((Z1 <= Z) || (Z <= Zero)));
	do  {
		do  {
			Y1 = Y;
			Y = (Half - ((Half - (Half * Y1 + ThirtyTwo * Y1 * Y1)) + Half
				)) + Half;
			} while ( ! ((Y1 <= Y) || (Y <= Zero)));
		X1 = X;
		X = ((Half * X1 + ThirtyTwo * X1 * X1) - F9) + F9;
		} while ( ! ((X1 <= X) || (X <= Zero)));
	if ((X1 != Y1) || (X1 != Z1)) {
		BadCond(Serious, "Disagreements among the values X1, Y1, Z1,\n");
		Serial.print( F("respectively  ") ); Serial.print( X1.toString(20) ); Serial.print( Y1.toString(20) ); Serial.println( Z1.toString(20) );
		Serial.print( F("are symptoms of inconsistencies introduced\n") );
		Serial.print( F("by extra-precise evaluation of arithmetic subexpressions.\n") );
		notify("Possibly some part of this");
		if ((X1 == U1) || (Y1 == U1) || (Z1 == U1))  Serial.print(
			"That feature is not tested further by this program.\n") ;
		}
	else  {
		if ((Z1 != U1) || (Z2 != U2)) {
			if ((Z1 >= U1) || (Z2 >= U2)) {
				BadCond(Failure, "");
				notify("Precision");
				Serial.print( F("\tU1 = ") );Serial.print( U1.toString(20) );
				sprintf_P( buf, PSTR(" Z1 - U1 = %s\n"),(Z1-U1).toString(20)); Serial.print(buf);
				Serial.print( F("\tU2 = ") );Serial.print( U2.toString(20) );
				sprintf_P( buf, PSTR(" Z2 - U2 = %s\n"),(Z2-U2).toString(20)); Serial.print(buf);
				}
			else {
				if ((Z1 <= Zero) || (Z2 <= Zero)) {
					sprintf_P( buf, PSTR("Because of unusual Radix = %s"), Radix.toString(20)); Serial.print(buf);
					Serial.print( F(", or exact rational arithmetic a result\n") );
					Serial.print( F("\Z1 = ") );Serial.print( Z1.toString(20) );
					Serial.print( F(", or Z2 = ") ); Serial.print( Z2.toString(20) );
					notify("of an\nextra-precision");
					}
				if (Z1 != Z2 || Z1 > Zero) {
					X = Z1 / U1;
					Y = Z2 / U2;
					if (Y > X) X = Y;
					Q = - LOG(X);
					Serial.print( F("Some subexpressions appear to be calculated extra\n") );
					sprintf_P( buf, PSTR("precisely with about %s extra B-digits, i.e.\n"),
						(Q / LOG(Radix)).toString(20) ); Serial.print( buf );
					sprintf_P( buf, PSTR("roughly %s extra significant decimals.\n"), 
						(Q / LOG(10.)).toString(20) );
					}
				Serial.print( F("That feature is not tested further by this program.\n") );
				}
			}
		}
	Pause();
	/*=============================================*/
	/*SPLIT
	}
#include "paranoia.h"
void part3(void){
*/
	Milestone = 35;
	/*=============================================*/
	if (Radix >= Two) {
		X = W / (Radix * Radix);
		Y = X + One;
		Z = Y - X;
		T = Z + U2;
		X = T - Z;
		TstCond (Failure, X == U2,
			"Subtraction is not normalized X=Y,X+Z != Y+Z!");
		if (X == U2) Serial.print(
			"Subtraction appears to be normalized, as it should be.");
		}
	Serial.print( F("\nChecking for guard digit in *, /, and -.\n") );
	Y = F9 * One;
	Z = One * F9;
	X = F9 - Half;
	Y = (Y - Half) - X;
	Z = (Z - Half) - X;
	X = One + U2;
	T = X * Radix;
	R = Radix * X;
	X = T - Radix;
	X = X - Radix * U2;
	T = R - Radix;
	T = T - Radix * U2;
	X = X * (Radix - One);
	T = T * (Radix - One);
	if ((X == Zero) && (Y == Zero) && (Z == Zero) && (T == Zero)) GMult = Yes;
	else {
		GMult = No;
		TstCond (Serious, False,
			"* lacks a Guard Digit, so 1*X != X");
		}
	Z = Radix * U2;
	X = One + Z;
	Y = FABS((X + Z) - X * X) - U2;
	X = One - U2;
	Z = FABS((X - U2) - X * X) - U1;
	TstCond (Failure, (Y <= Zero)
		   && (Z <= Zero), "* gets too many final digits wrong.\n");
	Y = One - U2;
	X = One + U2;
	Z = One / Y;
	Y = Z - X;
	X = One / Three;
	Z = Three / Nine;
	X = X - Z;
	T = Nine / TwentySeven;
	Z = Z - T;
	TstCond(Defect, X == Zero && Y == Zero && Z == Zero,
		"Division lacks a Guard Digit, so error can exceed 1 ulp\n\
or  1/3  and  3/9  and  9/27 may disagree");
	Y = F9 / One;
	X = F9 - Half;
	Y = (Y - Half) - X;
	X = One + U2;
	T = X / One;
	X = T - X;
	if ((X == Zero) && (Y == Zero) && (Z == Zero)) GDiv = Yes;
	else {
		GDiv = No;
		TstCond (Serious, False,
			"Division lacks a Guard Digit, so X/1 != X");
		}
	X = One / (One + U2);
	Y = X - Half - Half;
	TstCond (Serious, Y < Zero,
		   "Computed value of 1/1.000..1 >= 1");
	X = One - U2;
	Y = One + Radix * U2;
	Z = X * Radix;
	T = Y * Radix;
	R = Z / Radix;
	StickyBit = T / Radix;
	X = R - X;
	Y = StickyBit - Y;
	TstCond (Failure, X == Zero && Y == Zero,
			"* and/or / gets too many last digits wrong");
	Y = One - U1;
	X = One - F9;
	Y = One - Y;
	T = Radix - U2;
	Z = Radix - BMinusU2;
	T = Radix - T;
	if ((X == U1) && (Y == U1) && (Z == U2) && (T == U2)) GAddSub = Yes;
	else {
		GAddSub = No;
		TstCond (Serious, False,
			"- lacks Guard Digit, so cancellation is obscured");
		}
	if (F9 != One && F9 - One >= Zero) {
		BadCond(Serious, "comparison alleges  (1-U1) < 1  although\n");
		Serial.print( F("  subtraction yields  (1-U1) - 1 = 0 , thereby vitiating\n") );
		Serial.print( F("  such precautions against division by zero as\n") );
		Serial.print( F("  ...  if (X == 1.0) {.....} else {.../(X-1.0)...}\n") );
		}
	if (GMult == Yes && GDiv == Yes && GAddSub == Yes) Serial.print(
		"     *, /, and - appear to have guard digits, as they should.\n");
	/*=============================================*/
	Milestone = 40;
	/*=============================================*/
	Pause();
	Serial.print( F("Checking rounding on multiply, divide and add/subtract.\n") );
	RMult = Other;
	RDiv = Other;
	RAddSub = Other;
	RadixD2 = Radix / Two;
	Aone = Two;
	Done = False;
	do  {
		AInvrse = Radix;
		do  {
			X = AInvrse;
			AInvrse = AInvrse / Aone;
			} while ( ! (Double::floor(AInvrse) != AInvrse));
		Done = (X == One) || (Aone > Three);
		if (! Done) Aone = Nine + One;
		} while ( ! (Done));
	if (X == One) Aone = Radix;
	AInvrse = One / Aone;
	X = Aone;
	Y = AInvrse;
	Done = False;
	do  {
		Z = X * Y - Half;
		TstCond (Failure, Z == Half,
			"X * (1/X) differs from 1");
		Done = X == Radix;
		X = Radix;
		Y = One / X;
		} while ( ! (Done));
	Y2 = One + U2;
	Y1 = One - U2;
	X = OneAndHalf - U2;
	Y = OneAndHalf + U2;
	Z = (X - U2) * Y2;
	T = Y * Y1;
	Z = Z - X;
	T = T - X;
	X = X * Y2;
	Y = (Y + U2) * Y1;
	X = X - OneAndHalf;
	Y = Y - OneAndHalf;
	if ((X == Zero) && (Y == Zero) && (Z == Zero) && (T <= Zero)) {
		X = (OneAndHalf + U2) * Y2;
		Y = OneAndHalf - U2 - U2;
		Z = OneAndHalf + U2 + U2;
		T = (OneAndHalf - U2) * Y1;
		X = X - (Z + U2);
		StickyBit = Y * Y1;
		S = Z * Y2;
		T = T - Y;
		Y = (U2 - Y) + StickyBit;
		Z = S - (Z + U2 + U2);
		StickyBit = (Y2 + U2) * Y1;
		Y1 = Y2 * Y1;
		StickyBit = StickyBit - Y2;
		Y1 = Y1 - Half;
		if ((X == Zero) && (Y == Zero) && (Z == Zero) && (T == Zero)
			&& ( StickyBit == Zero) && (Y1 == Half)) {
			RMult = Rounded;
			Serial.print( F("Multiplication appears to round correctly.\n") );
			}
		else	if ((X + U2 == Zero) && (Y < Zero) && (Z + U2 == Zero)
				&& (T < Zero) && (StickyBit + U2 == Zero)
				&& (Y1 < Half)) {
				RMult = Chopped;
				Serial.print( F("Multiplication appears to chop.\n") );
				}
			else Serial.print( F("* is neither chopped nor correctly rounded.\n") );
		if ((RMult == Rounded) && (GMult == No)) notify("Multiplication");
		}
	else Serial.print( F("* is neither chopped nor correctly rounded.\n") );
	/*=============================================*/
	Milestone = 45;
	/*=============================================*/
	Y2 = One + U2;
	Y1 = One - U2;
	Z = OneAndHalf + U2 + U2;
	X = Z / Y2;
	T = OneAndHalf - U2 - U2;
	Y = (T - U2) / Y1;
	Z = (Z + U2) / Y2;
	X = X - OneAndHalf;
	Y = Y - T;
	T = T / Y1;
	Z = Z - (OneAndHalf + U2);
	T = (U2 - OneAndHalf) + T;
	if (! ((X > Zero) || (Y > Zero) || (Z > Zero) || (T > Zero))) {
		X = OneAndHalf / Y2;
		Y = OneAndHalf - U2;
		Z = OneAndHalf + U2;
		X = X - Y;
		T = OneAndHalf / Y1;
		Y = Y / Y1;
		T = T - (Z + U2);
		Y = Y - Z;
		Z = Z / Y2;
		Y1 = (Y2 + U2) / Y2;
		Z = Z - OneAndHalf;
		Y2 = Y1 - Y2;
		Y1 = (F9 - U1) / F9;
		if ((X == Zero) && (Y == Zero) && (Z == Zero) && (T == Zero)
			&& (Y2 == Zero) && (Y2 == Zero)
			&& (Y1 - Half == F9 - Half )) {
			RDiv = Rounded;
			Serial.print( F("Division appears to round correctly.\n") );
			if (GDiv == No) notify("Division");
			}
		else if ((X < Zero) && (Y < Zero) && (Z < Zero) && (T < Zero)
			&& (Y2 < Zero) && (Y1 - Half < F9 - Half)) {
			RDiv = Chopped;
			Serial.print( F("Division appears to chop.\n") );
			}
		}
	if (RDiv == Other) Serial.print( F("/ is neither chopped nor correctly rounded.\n") );
	BInvrse = One / Radix;
	TstCond (Failure, (BInvrse * Radix - Half == Half),
		   "Radix * ( 1 / Radix ) differs from 1");
	/*=============================================*/
	/*SPLIT
	}
#include "paranoia.h"
void part4(void){
*/
	Milestone = 50;
	/*=============================================*/
	TstCond (Failure, ((F9 + U1) - Half == Half)
		   && ((BMinusU2 + U2 ) - One == Radix - One),
		   "Incomplete carry-propagation in Addition");
	X = One - U1 * U1;
	Y = One + U2 * (One - U2);
	Z = F9 - Half;
	X = (X - Half) - Z;
	Y = Y - One;
	if ((X == Zero) && (Y == Zero)) {
		RAddSub = Chopped;
		Serial.print( F("Add/Subtract appears to be chopped.\n") );
		}
	if (GAddSub == Yes) {
		X = (Half + U2) * U2;
		Y = (Half - U2) * U2;
		X = One + X;
		Y = One + Y;
		X = (One + U2) - X;
		Y = One - Y;
		if ((X == Zero) && (Y == Zero)) {
			X = (Half + U2) * U1;
			Y = (Half - U2) * U1;
			X = One - X;
			Y = One - Y;
			X = F9 - X;
			Y = One - Y;
			if ((X == Zero) && (Y == Zero)) {
				RAddSub = Rounded;
				Serial.print( F("Addition/Subtraction appears to round correctly.\n") );
				if (GAddSub == No) notify("Add/Subtract");
				}
			else Serial.print( F("Addition/Subtraction neither rounds nor chops.\n") );
			}
		else Serial.print( F("Addition/Subtraction neither rounds nor chops.\n") );
		}
	else Serial.print( F("Addition/Subtraction neither rounds nor chops.\n") );
	S = One;
	X = One + Half * (One + Half);
	Y = (One + U2) * Half;
	Z = X - Y;
	T = Y - X;
	StickyBit = Z + T;
	if (StickyBit != Zero) {
		S = Zero;
		BadCond(Flaw, "(X - Y) + (Y - X) is non zero!\n");
		}
	StickyBit = Zero;
	if ((GMult == Yes) && (GDiv == Yes) && (GAddSub == Yes)
		&& (RMult == Rounded) && (RDiv == Rounded)
		&& (RAddSub == Rounded) && (Double::floor(RadixD2) == RadixD2)) {
		Serial.print( F("Checking for sticky bit.\n") );
		X = (Half + U1) * U2;
		Y = Half * U2;
		Z = One + Y;
		T = One + X;
		if ((Z - One <= Zero) && (T - One >= U2)) {
			Z = T + Y;
			Y = Z - X;
			if ((Z - T >= U2) && (Y - T == Zero)) {
				X = (Half + U1) * U1;
				Y = Half * U1;
				Z = One - Y;
				T = One - X;
				if ((Z - One == Zero) && (T - F9 == Zero)) {
					Z = (Half - U1) * U1;
					T = F9 - Z;
					Q = F9 - Y;
					if ((T - F9 == Zero) && (F9 - U1 - Q == Zero)) {
						Z = (One + U2) * OneAndHalf;
						T = (OneAndHalf + U2) - Z + U2;
						X = One + Half / Radix;
						Y = One + Radix * U2;
						Z = X * Y;
						if (T == Zero && X + Radix * U2 - Z == Zero) {
							if (Radix != Two) {
								X = Two + U2;
								Y = X / Two;
								if ((Y - One == Zero)) StickyBit = S;
								}
							else StickyBit = S;
							}
						}
					}
				}
			}
		}
	if (StickyBit == One) Serial.print( F("Sticky bit apparently used correctly.\n") );
	else Serial.print( F("Sticky bit used incorrectly or not at all.\n") );
	TstCond (Flaw, !(GMult == No || GDiv == No || GAddSub == No ||
			RMult == Other || RDiv == Other || RAddSub == Other),
		"lack(s) of guard digits or failure(s) to correctly round or chop\n\
(noted above) count as one flaw in the final tally below");
	/*=============================================*/
	Milestone = 60;
	/*=============================================*/
	Serial.println();
	Serial.print( F("Does Multiplication commute?  ") );
	sprintf_P( buf, PSTR("Testing on %d random pairs.\n"), NoTrials); Serial.print( buf );
	Random9 = SQRT(3.0);
	Random1 = Third;
	I = 1;
	do  {
		X = Random();
		Y = Random();
		Z9 = Y * X;
		Z = X * Y;
		Z9 = Z - Z9;
		I = I + 1;
		} while ( ! ((I > NoTrials) || (Z9 != Zero)));
	if (I == NoTrials) {
		Random1 = One + Half / Three;
		Random2 = (U2 + U1) + One;
		Z = Random1 * Random2;
		Y = Random2 * Random1;
		Z9 = (One + Half / Three) * ((U2 + U1) + One) - (One + Half /
			Three) * ((U2 + U1) + One);
		}
	if (! ((I == NoTrials) || (Z9 == Zero)))
		BadCond(Defect, "X * Y == Y * X trial fails.\n");
	else {
		sprintf_P( buf, PSTR("     No failures found in %d integer pairs.\n"), NoTrials);
		Serial.print( buf );
	}
	/*=============================================*/
	Milestone = 70;
	/*=============================================*/
	Serial.print( F("\nRunning test of square root(x).\n") );
	TstCond (Failure, (Zero == SQRT(Zero))
		   && (- Zero == SQRT(- Zero))
		   && (One == SQRT(One)), "Square root of 0.0, -0.0 or 1.0 wrong");
	MinSqEr = Zero;
	MaxSqEr = Zero;
	J = Zero;
	X = Radix;
	OneUlp = U2;
	SqXMinX (Serious);
	X = BInvrse;
	OneUlp = BInvrse * U1;
	SqXMinX (Serious);
	X = U1;
	OneUlp = U1 * U1;
	SqXMinX (Serious);
	if (J != Zero) Pause();
	sprintf_P( buf, PSTR("Testing if sqrt(X * X) == X for %d Integers X.\n"), NoTrials); Serial.print( buf );
	J = Zero;
	X = Two;
	Y = Radix;
	if ((Radix != One)) do  {
		X = Y;
		Y = Radix * Y;
		} while ( ! ((Y - X >= NoTrials)));
	OneUlp = X * U2;
	I = 1;
	while (I <= NoTrials) {
		X = X + One;
		SqXMinX (Defect);
		if (J > Zero) break;
		I = I + 1;
		}
	Serial.print( F("Test for sqrt monotonicity.\n") );
	I = - 1;
	X = BMinusU2;
	Y = Radix;
	Z = Radix + Radix * U2;
	NotMonot = False;
	Monot = False;
	while ( ! (NotMonot || Monot)) {
		I = I + 1;
		X = SQRT(X);
		Q = SQRT(Y);
		Z = SQRT(Z);
		if ((X > Q) || (Q > Z)) NotMonot = True;
		else {
			Q = Double::floor(Q + Half);
			if (!(I > 0 || Radix == Q * Q)) Monot = True;
			else if (I > 0) {
			if (I > 1) Monot = True;
			else {
				Y = Y * BInvrse;
				X = Y - U1;
				Z = Y + U1;
				}
			}
			else {
				Y = Q;
				X = Y - U2;
				Z = Y + U2;
				}
			}
		}
	if (Monot) 
		Serial.print( F("sqrt has passed a test for Monotonicity.\n") );
	else {
		BadCond(Defect, "");
		sprintf_P( buf, PSTR("sqrt(X) is non-monotonic for X near %s .\n"), Y.toString(20) );
	}
	/*=============================================*/
	/*SPLIT
	}
#include "paranoia.h"
void part5(void){
*/
	Milestone = 80;
	/*=============================================*/
	MinSqEr = MinSqEr + Half;
	MaxSqEr = MaxSqEr - Half;
	Y = (SQRT(One + U2) - One) / U2;
	SqEr = (Y - One) + U2 / Eight;
	if (SqEr > MaxSqEr) MaxSqEr = SqEr;
	SqEr = Y + U2 / Eight;
	if (SqEr < MinSqEr) MinSqEr = SqEr;
	Y = ((SQRT(F9) - U2) - (One - U2)) / U1;
	SqEr = Y + U1 / Eight;
	if (SqEr > MaxSqEr) MaxSqEr = SqEr;
	SqEr = (Y + One) + U1 / Eight;
	if (SqEr < MinSqEr) MinSqEr = SqEr;
	OneUlp = U2;
	X = OneUlp;
	for( Indx = 1; Indx <= 3; ++Indx) {
		Y = SQRT((X + U1 + X) + F9);
		Y = ((Y - U2) - ((One - U2) + X)) / OneUlp;
		Z = ((U1 - X) + F9) * Half * X * X / OneUlp;
		SqEr = (Y + Half) + Z;
		if (SqEr < MinSqEr) MinSqEr = SqEr;
		SqEr = (Y - Half) + Z;
		if (SqEr > MaxSqEr) MaxSqEr = SqEr;
		if (((Indx == 1) || (Indx == 3))) 
			X = OneUlp * Sign (X) * Double::floor(Eight / (Nine * SQRT(OneUlp)));
		else {
			OneUlp = U1;
			X = - OneUlp;
			}
		}
	/*=============================================*/
	Milestone = 85;
	/*=============================================*/
	SqRWrng = False;
	Anomaly = False;
	RSqrt = Other; /* ~dgh */
	if (Radix != One) {
		Serial.print( F("Testing whether sqrt is rounded or chopped.\n") );
		D = Double::floor(Half + POW(Radix, One + Precision - Double::floor(Precision)));
	/* ... == Radix^(1 + fract) if (Precision == Integer + fract. */
		X = D / Radix;
		Y = D / Aone;
		if ((X != Double::floor(X)) || (Y != Double::floor(Y))) {
			Anomaly = True;
			}
		else {
			X = Zero;
			Z2 = X;
			Y = One;
			Y2 = Y;
			Z1 = Radix - One;
			FourD = Four * D;
			do  {
				if (Y2 > Z2) {
					Q = Radix;
					Y1 = Y;
					do  {
						X1 = FABS(Q + Double::floor(Half - Q / Y1) * Y1);
						Q = Y1;
						Y1 = X1;
						} while ( ! (X1 <= Zero));
					if (Q <= One) {
						Z2 = Y2;
						Z = Y;
						}
					}
				Y = Y + Two;
				X = X + Eight;
				Y2 = Y2 + X;
				if (Y2 >= FourD) Y2 = Y2 - FourD;
				} while ( ! (Y >= D));
			X8 = FourD - Z2;
			Q = (X8 + Z * Z) / FourD;
			X8 = X8 / Eight;
			if (Q != Double::floor(Q)) Anomaly = True;
			else {
				Break = False;
				do  {
					X = Z1 * Z;
					X = X - Double::floor(X / Radix) * Radix;
					if (X == One) 
						Break = True;
					else
						Z1 = Z1 - One;
					} while ( ! (Break || (Z1 <= Zero)));
				if ((Z1 <= Zero) && (! Break)) Anomaly = True;
				else {
					if (Z1 > RadixD2) Z1 = Z1 - Radix;
					do  {
						NewD();
						} while ( ! (U2 * D >= F9));
					if (D * Radix - D != W - D) Anomaly = True;
					else {
						Z2 = D;
						I = 0;
						Y = D + (One + Z) * Half;
						X = D + Z + Q;
						SR3750();
						Y = D + (One - Z) * Half + D;
						X = D - Z + D;
						X = X + Q + X;
						SR3750();
						NewD();
						if (D - Z2 != W - Z2) Anomaly = True;
						else {
							Y = (D - Z2) + (Z2 + (One - Z) * Half);
							X = (D - Z2) + (Z2 - Z + Q);
							SR3750();
							Y = (One + Z) * Half;
							X = Q;
							SR3750();
							if (I == 0) Anomaly = True;
							}
						}
					}
				}
			}
		if ((I == 0) || Anomaly) {
			BadCond(Failure, "Anomalous arithmetic with Integer < ");
			sprintf_P( buf, PSTR("Radix^Precision = %s\n"), W.toString(20) );
			Serial.print( F(" fails test whether sqrt rounds or chops.\n") );
			SqRWrng = True;
			}
		}
	if (! Anomaly) {
		if (! ((MinSqEr < Zero) || (MaxSqEr > Zero))) {
			RSqrt = Rounded;
			Serial.print( F("Square root appears to be correctly rounded.\n") );
			}
		else  {
			if ((MaxSqEr + U2 > U2 - Half) || (MinSqEr > Half)
				|| (MinSqEr + Radix < Half)) SqRWrng = True;
			else {
				RSqrt = Chopped;
				Serial.print( F("Square root appears to be chopped.\n") );
				}
			}
		}
	if (SqRWrng) {
		Serial.print( F("Square root is neither chopped nor correctly rounded.\n") );
		sprintf_P( buf, PSTR("Observed errors run from %s "), (MinSqEr - Half).toString(20) ); Serial.print( buf );
		sprintf_P( buf, PSTR("to %s ulps.\n"), (Half + MaxSqEr).toString(20) ); Serial.print( buf );
		TstCond (Serious, MaxSqEr - MinSqEr < Radix * Radix,
			"sqrt gets too many last digits wrong");
		}
	/*=============================================*/
	Milestone = 90;
	/*=============================================*/
	Pause();
	Serial.print( F("Testing powers Z^i for small Integers Z and i.\n") );
	N = 0;
	/* ... test powers of zero. */
	I = 0;
	Z = -Zero;
	M = 3;
	Break = False;
	do  {
		X = One;
		SR3980();
		if (I <= 10) {
			I = 1023;
			SR3980();
			}
		if (Z == MinusOne) Break = True;
		else {
			Z = MinusOne;
			/* .. if(-1)^N is invalid, replace MinusOne by One. */
			I = - 4;
			}
		} while ( ! Break);
	PrintIfNPositive();
	N1 = N;
	N = 0;
	Z = Aone;
	M = Double::floor(Two * LOG(W) / LOG(Aone)).toInt();
	Break = False;
	do  {
		X = Z;
		I = 1;
		SR3980();
		if (Z == AInvrse) Break = True;
		else Z = AInvrse;
		} while ( ! (Break));
	/*=============================================*/
		Milestone = 100;
	/*=============================================*/
	/*  Powers of Radix have been tested, */
	/*         next try a few primes     */
	M = NoTrials;
	Z = Three;
	do  {
		X = Z;
		I = 1;
		SR3980();
		do  {
			Z = Z + Two;
			} while ( Three * Double::floor(Z / Three) == Z );
		} while ( Z < Eight * Three );
	if (N > 0) {
		Serial.print( F("Errors like this may invalidate financial calculations\n") );
		Serial.print( F("\tinvolving interest rates.\n") );
		}
	PrintIfNPositive();
	N += N1;
	if (N == 0) Serial.print( F("... no discrepancies found.\n") );
	if (N > 0) Pause();
	else Serial.println();
	/*=============================================*/
	/*SPLIT
	}
#include "paranoia.h"
void part6(void){
*/
	Milestone = 110;
	/*=============================================*/
	Serial.print( F("Seeking Underflow thresholds UfThold and E0.\n") );
	D = U1;
	if (Precision != Double::floor(Precision)) {
		D = BInvrse;
		X = Precision;
		do  {
			D = D * BInvrse;
			X = X - One;
			} while ( X > Zero);
		}
	Y = One;
	Z = D;
	/* ... D is power of 1/Radix < 1. */
	do  {
		C = Y;
		Y = Z;
		Z = Y * Y;
		} while ((Y > Z) && (Z + Z > Z));
	Y = C;
	Z = Y * D;
	do  {
		C = Y;
		Y = Z;
		Z = Y * D;
		} while ((Y > Z) && (Z + Z > Z));
	if (Radix < Two) HInvrse = Two;
	else HInvrse = Radix;
	H = One / HInvrse;
	/* ... 1/HInvrse == H == Min(1/Radix, 1/2) */
	CInvrse = One / C;
	E0 = C;
	Z = E0 * H;
	/* ...1/Radix^(BIG Integer) << 1 << CInvrse == 1/C */
	do  {
		Y = E0;
		E0 = Z;
		Z = E0 * H;
		} while ((E0 > Z) && (Z + Z > Z));
	UfThold = E0;
	E1 = Zero;
	Q = Zero;
	E9 = U2;
	S = One + E9;
	D = C * S;
	if (D <= C) {
		E9 = Radix * U2;
		S = One + E9;
		D = C * S;
		if (D <= C) {
			BadCond(Failure, "multiplication gets too many last digits wrong.\n");
			Underflow = E0;
			Y1 = Zero;
			PseudoZero = Z;
			Pause();
			}
		}
	else {
		Underflow = D;
		PseudoZero = Underflow * H;
		UfThold = Zero;
		do  {
			Y1 = Underflow;
			Underflow = PseudoZero;
			if (E1 + E1 <= E1) {
				Y2 = Underflow * HInvrse;
				E1 = FABS(Y1 - Y2);
				Q = Y1;
				if ((UfThold == Zero) && (Y1 != Y2)) UfThold = Y1;
				}
			PseudoZero = PseudoZero * H;
			} while ((Underflow > PseudoZero)
				&& (PseudoZero + PseudoZero > PseudoZero));
		}
	/* Comment line 4530 .. 4560 */
	if (PseudoZero != Zero) {
		Serial.println();
		Z = PseudoZero;
	/* ... Test PseudoZero for "phoney- zero" violates */
	/* ... PseudoZero < Underflow or PseudoZero < PseudoZero + PseudoZero
		   ... */
		if (PseudoZero <= Zero) {
			BadCond(Failure, "Positive expressions can underflow to an\n");
			Serial.print( F("allegedly negative value\n") );
			sprintf_P( buf, PSTR("PseudoZero that prints out as: %s .\n"), PseudoZero.toString(20) ); Serial.print( buf );
			X = - PseudoZero;
			if (X <= Zero) {
				Serial.print( F("But -PseudoZero, which should be\n") );
				sprintf_P( buf, PSTR("positive, isn't; it prints out as  %s .\n"), X.toString(20) ); Serial.print( buf );
				}
			}
		else {
			BadCond(Flaw, "Underflow can stick at an allegedly positive\n");
			sprintf_P( buf, PSTR("value PseudoZero that prints out as %s .\n"), PseudoZero.toString(20) );
			}
		TstPtUf();
		}
	/*=============================================*/
	Milestone = 120;
	/*=============================================*/
	if (CInvrse * Y > CInvrse * Y1) {
		S = H * S;
		E0 = Underflow;
		}
	if (! ((E1 == Zero) || (E1 == E0))) {
		BadCond(Defect, "");
		if (E1 < E0) {
			Serial.print( F("Products underflow at a higher") );
			Serial.print( F(" threshold than differences.\n") );
			if (PseudoZero == Zero) 
			E0 = E1;
			}
		else {
			Serial.print( F("Difference underflows at a higher") );
			Serial.print( F(" threshold than products.\n") );
			}
		}
	sprintf_P( buf, PSTR("Smallest strictly positive number found is E0 = %s .\n"), E0.toString(20) ); Serial.print( buf );
	Z = E0;
	TstPtUf();
	Underflow = E0;
	if (N == 1) Underflow = Y;
	I = 4;
	if (E1 == Zero) I = 3;
	if (UfThold == Zero) I = I - 2;
	UfNGrad = True;
	switch (I)  {
	case	1:
		UfThold = Underflow;
		if ((CInvrse * Q) != ((CInvrse * Y) * S)) {
			UfThold = Y;
			BadCond(Failure, "Either accuracy deteriorates as numbers\n");
			sprintf_P( buf, PSTR("approach a threshold = %s\n"), UfThold.toString(20) );  Serial.print( buf );
			sprintf_P( buf, PSTR(" coming down from %s\n"), C.toString(20) ); Serial.print( buf );
			Serial.print( F(" or else multiplication gets too many last digits wrong.\n") );
		}
		Pause();
		break;
	
	case	2:
		BadCond(Failure, "Underflow confuses Comparison, which alleges that\n");
		Serial.print( F("Q == Y while denying that |Q - Y| == 0; these values\n") );
		sprintf_P( buf, PSTR("print out as Q = %s, "), Q.toString(20) ); Serial.print( buf );
		sprintf_P( buf, PSTR("Y = %s .\n"), Y2.toString(20) );  Serial.print( buf );
		sprintf_P( buf, PSTR("|Q - Y| = %s .\n") , FABS(Q - Y2).toString(20) ); Serial.print( buf );
		UfThold = Q;
		break;
	
	case	3:
		X = X;
		break;
	
	case	4:
		if ((Q == UfThold) && (E1 == E0)
			&& (FABS( UfThold - E1 / E9) <= E1)) {
			UfNGrad = False;
			Serial.print( F("Underflow is gradual; it incurs Absolute Error =\n") );
			Serial.print( F("(roundoff in UfThold) < E0.\n") );
			Y = E0 * CInvrse;
			Y = Y * (OneAndHalf + U2);
			X = CInvrse * (One + U2);
			Y = Y / X;
			IEEE = (Y == E0);
		}
	}
	if (UfNGrad) {
		Serial.println();
		R = SQRT(Underflow / UfThold);
		if (R <= H) {
			Z = R * UfThold;
			X = Z * (One + R * H * (One + H));
			}
		else {
			Z = UfThold;
			X = Z * (One + H * H * (One + H));
			}
		if (! ((X == Z) || (X - Z != Zero))) {
			BadCond(Flaw, "");
			sprintf_P( buf, PSTR("X = %s\n"), X.toString(20) ); Serial.print( buf );
			sprintf_P( buf, PSTR("\tis not equal to Z = %s .\n"), Z.toString(20) ); Serial.print( buf );
			Z9 = X - Z;
			sprintf_P( buf, PSTR("yet X - Z yields %s .\n"), Z9.toString(20) ); Serial.print( buf );
			Serial.print( F("    Should this NOT signal Underflow, ") );
			Serial.print( F("this is a SERIOUS DEFECT\nthat causes ") );
			Serial.print( F("confusion when innocent statements like\n") );;
			Serial.print( F("    if (X == Z)  ...  else") );
			Serial.print( F("  ... (f(X) - f(Z)) / (X - Z) ...\n") );
			Serial.print( F("encounter Division by Zero although actually\n") );
			sprintf("X / Z = 1 + %s .\n", ((X / Z - Half) - Half).toString(20) ); Serial.print( buf );
			}
		}
	sprintf_P( buf, PSTR("The Underflow threshold is %s, below which\n"), UfThold.toString(20) ); Serial.print( buf );
	Serial.print( F("calculation may suffer larger Relative error than ") );
	Serial.print( F("merely roundoff.\n") );
	Y2 = U1 * U1;
	Y = Y2 * Y2;
	Y2 = Y * U1;
	if (Y2 <= UfThold) {
		if (Y > E0) {
			BadCond(Defect, "");
			I = 5;
		} else {
			BadCond(Serious, "");
			I = 4;
		}
		sprintf_P( buf, PSTR("Range is too narrow; U1^%d Underflows.\n"), I ); Serial.print( buf );
	}
	/*=============================================*/
	/*SPLIT
	}
#include "paranoia.h"
void part7(void){
*/
	Milestone = 130;
	/*=============================================*/
	Y = - Double::floor(Half - TwoForty * LOG(UfThold) / LOG(HInvrse)) / TwoForty;
	Y2 = Y + Y;
	Serial.print( F("Since underflow occurs below the threshold\n") );
	sprintf_P( buf, PSTR("UfThold = (%s) "), HInvrse.toString(20) ); Serial.print( buf );
	sprintf_P( buf, PSTR("^ (%s)\nonly underflow "), Y.toString(20) ); Serial.print( buf );
	sprintf_P( buf, PSTR("should afflict the expression\n\t(%s) "), HInvrse.toString(20) ); Serial.print( buf );
	sprintf_P( buf, PSTR("^ (%s);\n"), Y2.toString(20) ); Serial.print( buf );
	Serial.print( F("actually calculating yields:") );
	V9 = POW(HInvrse, Y2);
	sprintf_P( buf, PSTR(" %s .\n"), V9.toString(20) ); Serial.print( buf );
	if (! ((V9 >= Zero) && (V9 <= (Radix + Radix + E9) * UfThold))) {
		BadCond(Serious, "this is not between 0 and underflow\n");
		sprintf_P( buf, PSTR("   threshold = %s .\n"), UfThold.toString(20) ); Serial.print( buf );
	} else if (! (V9 > UfThold * (One + E9))) {
		Serial.print( F("This computed value is O.K.\n") );
	} else {
		BadCond(Defect, "this is not between 0 and underflow\n");
		sprintf_P( buf, PSTR("   threshold = %s .\n"), UfThold.toString(20) ); Serial.print( buf );
	}
	/*=============================================*/
	Milestone = 140;
	/*=============================================*/
	Serial.println();
	/* ...calculate Exp2 == exp(2) == 7.389056099... */
	X = Zero;
	I = 2;
	Y = Two * Three;
	Q = Zero;
	N = 0;
	do  {
		Z = X;
		I = I + 1;
		Y = Y / (I + I);
		R = Y + Q;
		X = Z + R;
		Q = (Z - X) + R;
		} while(X > Z);
	Z = (OneAndHalf + One / Eight) + X / (OneAndHalf * ThirtyTwo);
	X = Z * Z;
	Exp2 = X * X;
	X = F9;
	Y = X - U1;
	sprintf_P( buf, PSTR("Testing X^((X + 1) / (X - 1)) vs. exp(2) = %s as X -> 1.\n"),
		Exp2.toString(20) ); Serial.print( buf );
	for(I = 1;;) {
		Z = X - BInvrse;
		Z = (X + One) / (Z - (One - BInvrse));
		Q = POW(X, Z) - Exp2;
		if (FABS(Q) > TwoForty * U2) {
			N = 1;
	 		V9 = (X - BInvrse) - (One - BInvrse);
			BadCond(Defect, "Calculated");
			sprintf_P( buf, PSTR(" %s for\n"), POW(X,Z).toString(20) ); Serial.print( buf );
			sprintf_P( buf, PSTR("\t(1 + (%s) "), V9.toString(20) ); Serial.print( buf );
			sprintf_P( buf, PSTR("^ (%s);\n"), Z.toString(20) ); Serial.print( buf );
			sprintf_P( buf, PSTR("\tdiffers from correct value by %s .\n"), Q.toString(20) ); Serial.print( buf );
			Serial.print( F("\tThis much error may spoil financial\n") );
			Serial.print( F("\tcalculations involving tiny interest rates.\n") );
			break;
			}
		else {
			Z = (Y - X) * Two + Y;
			X = Y;
			Y = Z;
			Z = One + (X - F9)*(X - F9);
			if (Z > One && I < NoTrials) I++;
			else  {
				if (X > One) {
					if (N == 0)
					   Serial.print( F("Accuracy seems adequate.\n") );
					break;
					}
				else {
					X = One + U2;
					Y = U2 + U2;
					Y += X;
					I = 1;
					}
				}
			}
		}
	/*=============================================*/
	Milestone = 150;
	/*=============================================*/
	Serial.print( F("Testing powers Z^Q at four nearly extreme values.\n") );
	N = 0;
	Z = Aone;
	Q = Double::floor(Half - LOG(C) / LOG(Aone));
	Break = False;
	do  {
		X = CInvrse;
		Y = POW(Z, Q);
		IsYeqX();
		Q = - Q;
		X = C;
		Y = POW(Z, Q);
		IsYeqX();
		if (Z < One) Break = True;
		else Z = AInvrse;
	} while ( ! (Break));
	PrintIfNPositive();
	if (N == 0) Serial.print( F(" ... no discrepancies found.\n") );
	Serial.println();
	
	/*=============================================*/
	Milestone = 160;
	/*=============================================*/
	Pause();
	Serial.print( F("Searching for Overflow threshold:\n") );
	Serial.print( F("This may generate an error.\n") );
	Y = - CInvrse;
	V9 = HInvrse * Y;

	do {
		V = Y;
		Y = V9;
		V9 = HInvrse * Y;
		} while(V9 < Y);
	I = 1;

overflow:
	Z = V9;
	Serial.print( F("Can `Z = -Y' overflow?\n") );
	sprintf("Trying it on Y = %s .\n", Y.toString(20) ); Serial.print( buf );
	V9 = - Y;
	V0 = V9;
	if (V - Y == V + V0) Serial.print( F("Seems O.K.\n") );
	else {
		Serial.print( F("finds a ") );
		BadCond(Flaw, "-(-Y) differs from Y.\n");
		}
	if (Z != Y) {
		BadCond(Serious, "");
		sprintf_P( buf, PSTR("overflow past %s\n"), Y.toString(20) ); Serial.print( buf );
		sprintf_P( buf, PSTR("\tshrinks to %s .\n"), Z.toString(20) ); Serial.print( buf );
		}
	if (I) {
		Y = V * (HInvrse * U2 - HInvrse);
		Z = Y + ((One - HInvrse) * U2) * V;
		if (Z < V0) Y = Z;
		if (Y < V0) V = Y;
		if (V0 - V < V0) V = V0;
		}
	else {
		V = Y * (HInvrse * U2 - HInvrse);
		V = V + ((One - HInvrse) * U2) * Y;
		}
	sprintf_P( buf, PSTR("Overflow threshold is V  = %s .\n"), V.toString(20) ); Serial.print( buf );
	if (I) {
		sprintf_P( buf, PSTR("Overflow saturates at V0 = %s .\n"), V0.toString(20) ); Serial.print( buf );
	} else
		Serial.print( F("There is no saturation value because the system traps on overflow.\n") );
	V9 = V * One;
	sprintf_P( buf, PSTR("No Overflow should be signaled for V * 1 = %s\n"), V9.toString(20) ); Serial.print( buf );
	V9 = V / One;
	sprintf_P( buf, PSTR("                           nor for V / 1 = %s .\n"), V9.toString(20) ); Serial.print( buf );
	Serial.print( F("Any overflow signal separating this * from the one\n") );
	Serial.print( F("above is a DEFECT.\n") );
	/*=============================================*/
	Milestone = 170;
	/*=============================================*/
	if (!(-V < V && -V0 < V0 && -UfThold < V && UfThold < V)) {
		BadCond(Failure, "Comparisons involving ");
		sprintf_P( buf, PSTR("+-%s, "), V.toString(20) ); Serial.print( buf );
		sprintf_P( buf, PSTR("+-%s\n"), V0.toString(20) ); Serial.print( buf );
		sprintf_P( buf, PSTR("and +-%s are confused by Overflow."), UfThold.toString(20) ); Serial.print( buf );
	}
	/*=============================================*/
	Milestone = 175;
	/*=============================================*/
	Serial.println();
	for(Indx = 1; Indx <= 3; ++Indx) {
		switch (Indx)  {
		case 1: Z = UfThold; break;
		case 2: Z = E0; break;
		case 3: Z = PseudoZero; break;
		}
		if (Z != Zero) {
			V9 = SQRT(Z);
			Y = V9 * V9;
			if (Y / (One - Radix * E9) < Z
			   || Y > (One + Radix * E9) * Z) { /* dgh: + E9 --> * E9 */
				if (V9 > U1) 
					BadCond(Serious, "");
				else
					BadCond(Defect, "");
				sprintf_P( buf, PSTR("Comparison alleges that what prints as Z = %s\n"), Z.toString(20) ); Serial.print( buf );
				sprintf_P( buf, PSTR(" is too far from sqrt(Z) ^ 2 = %s .\n"), Y.toString(20) ); Serial.print( buf );
			}
		}
	}
	/*=============================================*/
	Milestone = 180;
	/*=============================================*/
	for(Indx = 1; Indx <= 2; ++Indx) {
		if (Indx == 1) Z = V;
		else Z = V0;
		V9 = SQRT(Z);
		X = (One - Radix * E9) * V9;
		V9 = V9 * X;
		if (((V9 < (One - Two * Radix * E9) * Z) || (V9 > Z))) {
			Y = V9;
			if (X < W) BadCond(Serious, "");
			else BadCond(Defect, "");
			sprintf_P( buf, PSTR("Comparison alleges that Z = %s\n"), Z.toString(20) ); Serial.print( buf );
			sprintf_P( buf, PSTR(" is too far from sqrt(Z) ^ 2 (%s) .\n"), Y.toString(20) ); Serial.print( buf );
			}
		}
	/*=============================================*/
	/*SPLIT
	}
#include "paranoia.h"
int part8(void){
*/
	Milestone = 190;
	/*=============================================*/
	Pause();
	X = UfThold * V;
	Y = Radix * Radix;
	if (X*Y < One || X > Y) {
		if (X * Y < U1 || X > Y/U1)
			BadCond(Defect, "Badly");
		else
			BadCond(Flaw, "");
			
		sprintf_P( buf, PSTR(" unbalanced range; UfThold * V = %s\n\tis too far from 1.\n\n"),
			X.toString(20) ); Serial.print( buf );
	}
	/*=============================================*/
	Milestone = 200;
	/*=============================================*/
	for (Indx = 1; Indx <= 5; ++Indx)  {
		X = F9;
		switch (Indx)  {
			case 2: X = One + U2; break;
			case 3: X = V; break;
			case 4: X = UfThold; break;
			case 5: X = Radix;
			}
		Y = X;

		V9 = (Y / X - Half) - Half;
		if (V9 == Zero) continue;
		if (V9 == - U1 && Indx < 5) BadCond(Flaw, "");
		else BadCond(Serious, "");
		sprintf_P( buf, PSTR("  X / X differs from 1 when X = %s\n"), X.toString(20) ); Serial.print( buf );
		sprintf_P( buf, PSTR("  instead, X / X - 1/2 - 1/2 = %s .\n"), V9.toString(20) ); Serial.print( buf );
		}
	/*=============================================*/
	Milestone = 210;
	/*=============================================*/
	MyZero = Zero;
	Serial.println();
	Serial.print( F("What message and/or values does Division by Zero produce?\n") ) ;
	Serial.print( F("    Trying to compute 1 / 0 produces ...") );
	sprintf_P( buf, PSTR("  %s .\n"), (One / MyZero).toString(20) ); Serial.print( buf );
	Serial.print( F("\n    Trying to compute 0 / 0 produces ...") );
	sprintf_P( buf, PSTR("  %s .\n"), (Zero / MyZero).toString(20) ); Serial.print( buf );

	/*=============================================*/
	Milestone = 220;
	/*=============================================*/
	Pause();
	Serial.println();
	{
		static char *msg[] = {
			"FAILUREs  encountered =",
			"SERIOUS DEFECTs  discovered =",
			"DEFECTs  discovered =",
			"FLAWs  discovered =" };
		int i;
		for(i = 0; i < 4; i++) if (ErrCnt[i])
			sprintf_P( buf, PSTR("The number of  %-29s %d.\n"),
				msg[i], ErrCnt[i]); Serial.print( buf );
		}
	Serial.println();
	if ((ErrCnt[Failure] + ErrCnt[Serious] + ErrCnt[Defect]
			+ ErrCnt[Flaw]) > 0) {
		if ((ErrCnt[Failure] + ErrCnt[Serious] + ErrCnt[
			Defect] == 0) && (ErrCnt[Flaw] > 0)) {
			Serial.print( F("The arithmetic diagnosed seems ") );
			Serial.print( F("Satisfactory though flawed.\n") );
			}
		if ((ErrCnt[Failure] + ErrCnt[Serious] == 0)
			&& ( ErrCnt[Defect] > 0)) {
			Serial.print( F("The arithmetic diagnosed may be Acceptable\n") );
			Serial.print( F("despite inconvenient Defects.\n") );
			}
		if ((ErrCnt[Failure] + ErrCnt[Serious]) > 0) {
			Serial.print( F("The arithmetic diagnosed has ") );
			Serial.print( F("unacceptable Serious Defects.\n") );
			}
		if (ErrCnt[Failure] > 0) {
			Serial.print( F("Potentially fatal FAILURE may have spoiled this") );
			Serial.print( F(" program's subsequent diagnoses.\n") );
			}
		}
	else {
		Serial.print( F("No failures, defects nor flaws have been discovered.\n") );
		if (! ((RMult == Rounded) && (RDiv == Rounded)
			&& (RAddSub == Rounded) && (RSqrt == Rounded))) 
			Serial.print( F("The arithmetic diagnosed seems Satisfactory.\n") );
		else {
			if (StickyBit >= One &&
				(Radix - Two) * (Radix - Nine - One) == Zero) {
				Serial.print( F("Rounding appears to conform to ") );
				Serial.print( F("the proposed IEEE standard P") );
				if ((Radix == Two) &&
					 ((Precision - Four * Three * Two) *
					  ( Precision - TwentySeven -
					   TwentySeven + One) == Zero)) 
					Serial.print( F("754") );
				else Serial.print( F("854") );
				if (IEEE) Serial.println();
				else {
					Serial.print( F(",\nexcept for possibly Double Rounding") );
					Serial.print( F(" during Gradual Underflow.\n") );
					}
				}
			Serial.print( F("The arithmetic diagnosed appears to be Excellent!\n") );
			}
		}
	if (fpecount)
		sprintf_P( buf, PSTR("\nA total of %d floating point exceptions were registered.\n"),
			fpecount); Serial.print( buf );
	Serial.print( F("END OF TEST.\n") );
	return 0;
}

/*SPLIT subs.c
#include "paranoia.h"
*/

Double Sign (Double X) { 
	return X >= 0. ? 1.0 : -1.0; 
}

void Pause(void) {
	sprintf_P( buf, PSTR("\nDiagnosis resumes after milestone Number %d"), Milestone); Serial.print( buf );
	sprintf_P( buf, PSTR("          Page: %d\n\n"), PageNo); Serial.print( buf );
	++Milestone;
	++PageNo;
}

void TstCond (int K, int Valid, CHARP T) { 
	if (! Valid) { 
		BadCond(K,T); 
		Serial.println(); 
	}
}

void BadCond(int K, CHARP T) {
	static char *msg[] = { "FAILURE", "SERIOUS DEFECT", "DEFECT", "FLAW" };

	ErrCnt [K] = ErrCnt [K] + 1;
	sprintf( buf, "%s:  %s", msg[K], T); Serial.print( buf );
}


Double Random(void) {
/*  Random computes
     X = (Random1 + Random9)^5
     Random1 = X - Double::floor(X) + 0.000005 * X;
   and returns the new value of Random1
*/
	Double X, Y;
	
	X = Random1 + Random9;
	Y = X * X;
	Y = Y * Y;
	X = X * Y;
	Y = X - Double::floor(X);
	Random1 = Y + X * 0.000005;
	return(Random1);
	}

void SqXMinX (int ErrKind) {
	Double XA, XB;
	
	XB = X * BInvrse;
	XA = X - XB;
	SqEr = ((SQRT(X * X) - XB) - XA) / OneUlp;
	if (SqEr != Zero) {
		if (SqEr < MinSqEr) MinSqEr = SqEr;
		if (SqEr > MaxSqEr) MaxSqEr = SqEr;
		J = J + 1.0;
		BadCond(ErrKind, "\n");
		sprintf_P( buf, PSTR("sqrt( %s) - %.17e  = %.17e\n"), (X * X).toString(20) ); Serial.print( buf );
		sprintf_P( buf, PSTR(" - %s  = %.17e\n"), X.toString(20) ); Serial.print( buf );
		sprintf_P( buf, PSTR("  = %s\n"), (OneUlp * SqEr).toString(20) ); Serial.print( buf );
		Serial.print( F("\tinstead of correct value 0 .\n") );
	}
}

void NewD(void) {
	X = Z1 * Q;
	X = Double::floor(Half - X / Radix) * Radix + X;
	Q = (Q - X * Z) / Radix + X * X * (D / Radix);
	Z = Z - Two * X * D;
	if (Z <= Zero) {
		Z = - Z;
		Z1 = - Z1;
	}
	D = Radix * D;
}

void SR3750(void) {
	if (! ((X - Radix < Z2 - Radix) || (X - Z2 > W - Z2))) {
		I = I + 1;
		X2 = SQRT(X * D);
		Y2 = (X2 - Z2) - (Y - Z2);
		X2 = X8 / (Y - Half);
		X2 = X2 - Half * X2 * X2;
		SqEr = (Y2 + Half) + (Half - X2);
		if (SqEr < MinSqEr) MinSqEr = SqEr;
		SqEr = Y2 - X2;
		if (SqEr > MaxSqEr) MaxSqEr = SqEr;
	}
}

void IsYeqX(void) {
	if (Y != X) {
		if (N <= 0) {
			if (Z == Zero && Q <= Zero)
				Serial.print( F("WARNING:  computing\n") );
			else 
				BadCond(Defect, "computing\n");
			sprintf_P( buf, PSTR("\t(%s) "), Z.toString(20) ); Serial.print( buf );
			sprintf_P( buf, PSTR("^ (%s)\n"), Q.toString(20) ); Serial.print( buf );
			sprintf_P( buf, PSTR("\tyielded %s;\n"), Y.toString(20) ); Serial.print( buf );
			sprintf_P( buf, PSTR("\twhich compared unequal to correct %s ;\n"), X.toString(20) ); Serial.print( buf );
			sprintf_P( buf, PSTR("\t\tthey differ by %s .\n"), (Y - X).toString(20) ); Serial.print( buf );
			sprintf_P( buf, PSTR("\t\trelative error (Y - X) / X = %s .\n"), ((Y - X) / X).toString(10) ); Serial.print( buf );
		}
	N = N + 1; /* ... count discrepancies. */
	}
}

void SR3980(void) {
	do {
		Q = (Double) I;
		Y = POW(Z, Q);
		IsYeqX();
		if (++I > M) break;
		X = Z * X;
	} while ( X < W );
}

void PrintIfNPositive(void) {
	if (N > 0) {
		sprintf_P( buf, PSTR("Similar discrepancies have occurred %d times.\n"), N); Serial.print( buf );
	}
}

void TstPtUf(void) {
	N = 0;
	if (Z != Zero) {
		Serial.print( F("Since comparison denies Z = 0, evaluating ") );
		Serial.print( F("(Z + Z) / Z should be safe.\n") );
		Q9 = (Z + Z) / Z;
		sprintf_P( buf, PSTR("What the machine gets for (Z + Z) / Z is  %s .\n"),
			Q9.toString(20) ); Serial.print( buf );
		if (FABS(Q9 - Two) < Radix * U2) {
			Serial.print( F("This is O.K., provided Over/Underflow") );
			Serial.print( F(" has NOT just been signaled.\n") );
			}
		else {
			if ((Q9 < One) || (Q9 > Two)) {
				N = 1;
				ErrCnt [Serious] = ErrCnt [Serious] + 1;
				Serial.print( F("This is a VERY SERIOUS DEFECT!\n") );
				}
			else {
				N = 1;
				ErrCnt [Defect] = ErrCnt [Defect] + 1;
				Serial.print( F("This is a DEFECT!\n") );
				}
			}
		// sigsave = 0;
		V9 = Z * One;
		Random1 = V9;
		V9 = One * Z;
		Random2 = V9;
		V9 = Z / One;
		if ((Z == Random1) && (Z == Random2) && (Z == V9)) {
			if (N > 0) Pause();
			}
		else {
			N = 1;
			BadCond(Defect, "What prints as Z = ");
			sprintf_P( buf, PSTR("%s\n\tcompares different from  "), Z.toString(20) ); Serial.print( buf );
			if (Z != Random1) {
				sprintf_P( buf, PSTR("Z * 1 = %s "), Random1.toString(20) ); Serial.print( buf );
			}
			if (! ((Z == Random2)
				|| (Random2 == Random1))) {
				sprintf_P( buf, PSTR("1 * Z == %s\n"), Random2.toString(20) ); Serial.print( buf );
			}
			if (! (Z == V9)) {
				sprintf_P( buf, PSTR("Z / 1 = %s\n"), V9.toString(20) ); Serial.print( buf );
			}
			if (Random2 != Random1) {
				ErrCnt [Defect] = ErrCnt [Defect] + 1;
				BadCond(Defect, "Multiplication does not commute!\n");
				sprintf_P( buf, PSTR("\tComparison alleges that 1 * Z = %s\n"),
					Random2.toString(20) ); Serial.print( buf );
				sprintf_P( buf, PSTR("\tdiffers from Z * 1 = %s\n"), Random1.toString(20) ); Serial.print( buf );
				}
			Pause();
			}
		}
	}

void notify(CHARP s) {
	sprintf_P( buf, PSTR("%s test appears to be inconsistent...\n"), s); Serial.print( buf );
	Serial.print( F("   PLEASE NOTIFY KARPINKSI!\n") );
	}

/*SPLIT msgs.c
#include "paranoia.h"
*/

void msglist_P(CHARPP s) {
	int i = 0;
	while(s[i]) {
		strcpy_P( buf, (char*)pgm_read_ptr( s[i++] ));
		Serial.println( buf ); 
	}
}

void msglist(CHARPP s) {
	while(*s) {
		Serial.println( *s++ ); 
	}
}



 void Instructions(void) {
	const char string_0[] = "Lest this program stop prematurely, i.e. before displaying\n";
	const char string_1[] = "    `END OF TEST',\n";
	const char string_2[] = "try to persuade the computer NOT to terminate execution when an";
	const char string_3[] = "error like Over/Underflow or Division by Zero occurs, but rather";
	const char string_4[] = "to persevere with a surrogate value after, perhaps, displaying some";
	const char string_5[] = "warning.  If persuasion avails naught, don't despair but run this";
	const char string_6[] = "program anyway to see how many milestones it passes, and then";
	const char string_7[] = "amend it to make further progress.\n";
	const char string_8[] = "Answer questions with Y, y, N or n (unless otherwise indicated).\n";
	const char *const instr[] = {
		string_0, string_1, string_2, string_3, string_4, string_5, string_6, string_7, string_8, 
		0 };

	msglist(instr);
}

void Heading(void) {
	const char string_0[] = "Users are invited to help debug and augment this program so it will";
	const char string_1[] = "cope with unanticipated and newly uncovered arithmetic pathologies.\n";
	const char string_2[] = "Please send suggestions and interesting results to";
	const char string_3[] = "\tRichard Karpinski";
	const char string_4[] = "\tComputer Center U-76";
	const char string_5[] = "\tUniversity of California";
	const char string_6[] = "\tSan Francisco, CA 94143-0704, USA\n";
	const char string_7[] = "In doing so, please include the following information:";
	const char string_8[] = "\tPrecision:\tdouble;";
	const char string_9[] = "\tVersion:\t10 February 1989;";
	const char string_a[] = "\tComputer:\n";
	const char string_b[] = "\tCompiler:\n";
	const char string_c[] = "\tOptimization level:\n";
	const char string_d[] = "\tOther relevant compiler options:";
	const char *const head[] = {
		string_0, string_1, string_2, string_3, string_4, string_5, string_6, string_7, string_8, string_9, 
		string_a, string_b, string_c, string_d, 
		0 };

	msglist(head);
}

void Characteristics(void) {
	static char *chars[] = {
	 "Running this program should reveal these characteristics:",
	"     Radix = 1, 2, 4, 8, 10, 16, 100, 256 ...",
	"     Precision = number of significant digits carried.",
	"     U2 = Radix/Radix^Precision = One Ulp",
	"\t(OneUlpnit in the Last Place) of 1.000xxx .",
	"     U1 = 1/Radix^Precision = One Ulp of numbers a little less than 1.0 .",
	"     Adequacy of guard digits for Mult., Div. and Subt.",
	"     Whether arithmetic is chopped, correctly rounded, or something else",
	"\tfor Mult., Div., Add/Subt. and Sqrt.",
	"     Whether a Sticky Bit used correctly for rounding.",
	"     UnderflowThreshold = an underflow threshold.",
	"     E0 and PseudoZero tell whether underflow is abrupt, gradual, or fuzzy.",
	"     V = an overflow threshold, roughly.",
	"     V0  tells, roughly, whether  Infinity  is represented.",
	"     Comparisions are checked for consistency with subtraction",
	"\tand for contamination with pseudo-zeros.",
	"     Sqrt is tested.  Y^X is not tested.",
	"     Extra-precise subexpressions are revealed but NOT YET tested.",
	"     Decimal-Binary conversion is NOT YET tested for accuracy.",
	0};

	msglist(chars);
}

void History(void) { /* History */
 /* Converted from Brian Wichmann's Pascal version to C by Thos Sumner,
	with further massaging by David M. Gay. */

  static char *hist[] = {
	"The program attempts to discriminate among",
	"   FLAWs, like lack of a sticky bit,",
	"   Serious DEFECTs, like lack of a guard digit, and",
	"   FAILUREs, like 2+2 == 5 .",
	"Failures may confound subsequent diagnoses.\n",
	"The diagnostic capabilities of this program go beyond an earlier",
	"program called `MACHAR', which can be found at the end of the",
	"book  `Software Manual for the Elementary Functions' (1980) by",
	"W. J. Cody and W. Waite. Although both programs try to discover",
	"the Radix, Precision and range (over/underflow thresholds)",
	"of the arithmetic, this program tries to cope with a wider variety",
	"of pathologies, and to say how well the arithmetic is implemented.",
	"\nThe program is based upon a conventional radix representation for",
	"floating-point numbers, but also allows logarithmic encoding",
	"as used by certain early WANG machines.\n",
	"BASIC version of this program (C) 1983 by Prof. W. M. Kahan;",
	"see source comments for more history.",
	0};

	msglist(hist);
}

// blink to signal end of tests
void loop() {
  digitalWrite(led, HIGH);   // turn the LED on (HIGH is the voltage level)
  delay(1000);               // wait for a second
  digitalWrite(led, LOW);    // turn the LED off by making the voltage LOW
  delay(1000);               // wait for a second
}

