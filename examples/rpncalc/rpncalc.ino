/* Copyright (c) 2025  Uwe Bissinger
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   * Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in
     the documentation and/or other materials provided with the
     distribution.
   * Neither the name of the copyright holders nor the names of
     contributors may be used to endorse or promote products derived
     from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE. */

/* $Id$ */

#include <fp64lib.h>

/*
 * Reads and evaluate a string of instructions for an rpn calculator
 * The string may contain the following:
 * <number> | <enter> | <func1Op> | <func2Op> | <whitespace>
 * To terminate a number, a function, enter or whitespace must following
 * whitespace following a number has the same effect than enter
  * <number>	:= [<sign>] <mantissa> [<exponent>] // put the number into x register
 *	<sign> 		:= '+' | '-'
 *	<mantissa> 	:= <digit>+ ['.' <digit>*]
 *	<exponent>	:= 'E' [<sign>] <digit>+
 * <enter>		:= ','
 * <operator>	:= '+' | '-' | '*' | '/'
 * <func1Op>	:= 'sin' | 'cos' | 'tan' | 'asin' | 'acos' | 'atan'
 * <func2Op>	:= '%' | 'y^x'
 */
 
#define DEBUG
#ifdef DEBUG
#define debug(x) Serial.println(x);
#else
#define debug(x)
#endif
 
 // possible states of the internal parsing state machine
 typedef enum {
	START,		// default, start of parsing
	NUMBER,		// detect any number, e.g. 1.23E34
	FUNC,		// detect any function, e.g. sin
	OPERATOR,	// detect any operator, e.g. *
	} state_t;

// the rpn stack: x = stack[0], y = stack[1], z = stack[2],
// t = stack[3] and lastx = stack[5]
float64_t stack[5];
#define LSTX stack[4]

// push a new value of the stack
// (old) x -> y -> z -> t, and put nwe value into x
bool stackLift = false;
void liftStack( float64_t x ) {
	if( stackLift ) {
		debug( "stackLift");
		stack[3] = stack[2];
		stack[2] = stack[1];
		stack[1] = stack[0];
	} else {
		debug( "no stacklift" );
	}
	stack[0] = x;
	stackLift = true;
}

// drop the stack (t -> z -> y) and replace x
void dropStack( float64_t x ) {
	debug( "dropStack");
	stack[0] = x;
	stack[1] = stack[2];
	stack[2] = stack[3];
	stackLift = true;
}

// type definitions for function pointers with 0, 1 and 2 args
typedef float64_t (*funcPtr)();
typedef float64_t (*func_1arg)(float64_t);
typedef float64_t (*func_2arg)(float64_t,float64_t);

// x = (x percent of y)
#define f_NUMBER_100    	((float64_t)0x4059000000000000LLU) //100
float64_t myPercent( float64_t y, float64_t x ) {
	float64_t res;
	res = fp64_mul( y, fp64_div( x, f_NUMBER_100 ) );
	return res;
}

// list of two argument operators
struct t_opTable {
	char op;
	func_2arg func;
} opTable[] = {
	// op, fp64lib function
	{ '+', fp64_add },
	{ '-', fp64_sub },
	{ '*', fp64_mul },
	{ '/', fp64_div },
	{ '%', myPercent }
};
int opSize = sizeof(opTable) / sizeof(t_opTable);

// calculator functions with no direct fp64lib equivalent
// retrieve lastX value
float64_t myLastX( ) {
	return LSTX;
}

// clear x register
float64_t myClrX( ) {
	stackLift = false;
	LSTX = stack[0];
	return 0ULL;
}

// clear all registers, including lastX
float64_t myClr( ) {
	float64_t res = 0ULL;
	stackLift = false;
	for( byte i = 0; i < 5; i++ )
		stack[i] = res;
	return res;
}

float64_t myPi( ) {
	return float64_NUMBER_PI;
}

// Table of functions to call
struct t_ftable {
	const char *name;
	byte args;
	funcPtr func;
} funcTable[] = {
	// extend with further functions if you like
	// no need for alphabetical sorting, only make sure
	// that longer function names are listed before
	// shorter function names, e.g. "sinh" must be before "sin"
	//name, #args, fp64lib function
	{ "sin",  1, (funcPtr) fp64_sin },
	{ "cos",  1, (funcPtr) fp64_cos },
	{ "tan",  1, (funcPtr) fp64_tan },
	{ "asin", 1, (funcPtr) fp64_asin },
	{ "acos", 1, (funcPtr) fp64_acos },
	{ "atan", 1, (funcPtr) fp64_atan },
	{ "y^x",  2, (funcPtr) fp64_pow },
	{ "lstx", 0,           myLastX },
	{ "clrx", 0,		   myClrX },
	{ "clear",0,		   myClr },
	{ "pi",   0,		   myPi }
};
int funcSize = sizeof(funcTable) / sizeof(t_ftable);

// save the current value of X into lastX register
void saveLstX() {
	LSTX = stack[0];
}

// exec operation n out of opTable
void execOp(int n) {
	float64_t res = (*opTable[n].func)( stack[1], stack[0] );
	saveLstX();
	if( opTable[n].op == '%' ) 
		stack[0] = res;
	else
		dropStack( res );
}

// exec function n out of funcTable
void execFunc( int n ) {
	float64_t res;
	funcPtr func = funcTable[n].func;

	if( strcmp( funcTable[n].name, "lstx" ) != 0 )
		saveLstX();
	debug("execFunc"); debug( n ); Serial.flush();
	if( funcTable[n].args == 0 ) {
		res = (*func)();
		liftStack( res );
	} else {
		if( funcTable[n].args == 1 ) 
			res = (*((func_1arg)func))( stack[0] );
		else
			res = (*((func_2arg)func))( stack[1], stack[0] );
		
		dropStack( res );
	}
}
 
 // evaluate a string for an rpn based calculator
 // if withRest = true, calculations start with a cleared stacked
 // otherwise calculations continue with existing stack values
 float64_t rpn_eval( char *s, bool withReset ) {
	char *p = s;			// pointer to current character
	char *n = NULL;			// start of a number or token
	char ch;				// save for current character
	float64_t num;			// the parsed number
	state_t state = START;	// current state of the state machine
	
	// reset stack when needed, otherwise new calculations 
	// will work with previous stack content
	if( withReset )
		myClr();
	
	// no statement, return NaN
	if( s == NULL )
		return( float64_ONE_POSSIBLE_NAN_REPRESENTATION );
	
	while( *p || (state != START) ) {
		switch( state ) {
		case START:
			// START = any operation allowed
			debug("START"); debug(p);
			// skip whitespace
			while( isspace(*p) ) {
				p++;
				stackLift = true;
			}

			// check for start of number
			if( (*p == '-' && isdigit(*(p+1))) ||
				isdigit(*p) ) {
				// start of a number detected
				// rest of parsing is done by NUMBER state machine
				n = p++;
				state = NUMBER;
				break;
				}

			// check for function
			if( isalpha(*p) ) {
				// rest of parsing is done by FUNC state machine
				n = p++;
				state = FUNC;
				break;
			}
			
			// check for enter
			if( *p == ',' ) {
				liftStack( stack[0] );
				p++;
				stackLift = false;
			} else {
				// neither number nor function nor enter
				// it has to be an operator
				// rest of parsing done by OPERATOR state machine
				state = OPERATOR;
			}
			break;
			
		case NUMBER:
			// a number was detected at *p
			// parse until end of number
			// and push number to stack
			debug("NUMBER"); debug(n);
			while( isdigit(*p) )
				p++;
			
			// parse decimal part
			if( *p == '.' ) {
				while( isdigit(*++p) );
			}
			
			// parse optional exponent
			if( *p == 'E' || *p == 'e' ) {
				p++;
				if( *p == '-' || *p == '+' )
					p++;	// skip sign
				while( isdigit(*p) )
					p++;
			}
			
			// now number is completely parsed
			// *p points to first character after number
			// convert number
			ch = *p;
			*p = '\0';
			num = fp64_atof( n );
			*p = ch;
	
			// and put number on stack
			liftStack( num );

			// restart normal parsing
			n  = NULL;
			state = START;
			break;
			
		case FUNC:
			// detect end of function, i.e. whitespace or digit
			debug("FUNC"); debug(n);
			while( !(isspace(*p) || isdigit(*p) || *p == '\0') )
				p++;
			ch = *p;
			*p = '\0';
			
			// now search in the function table
			// simple linear search is fast enough for a calculator
			for( int i = 0; i < funcSize; i++ ) {
				if( strcmp( n, funcTable[i].name ) == 0 ) {
					// found a function, execute it
					execFunc( i );
					break;
				}
			}
			
			// if function is not found, word is ignored
			// restore parsing at end of word
			n  = NULL;
			*p = ch;
			state = START;
			break;
			
		case OPERATOR:
			// check for operators
			// unknown characters are ignored
			debug("OPERATOR"); debug(p);
			for( int i = 0; i < opSize; i++ ) {
				if( *p == opTable[i].op ) {
					// found an operator
					execOp( i );
					break;
				}
			}

			// restart parsing after operator
			p++;
			state = START;
			break;
			
		default:
			// should not happen, unknown state
			// skip current character and restart parsing
			debug("ERROR"); debug(p);
			p++;
			state = START;
		}
	}

	// everything eval'ed, return X
	return( stack[0] );
}
 
// test cases
#ifdef DEBUG
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wwrite-strings"
char *tests[] = {
	// happy cases
	"",
	"1",
	"-1",
	"1.23",
	"1.23E12",
	"1.23E-45",
	"1,2",
	"3 4",
	"1,2,3,4",
	"1,2,3,4,5",
	"1,2+",
	"1,2-",
	"2,3*",
	"2,3/",
	"1,10% +",
	"1 asin",
	"1 asin cos",
	"1,2+ lstx +",
	"1,2,3,4 clear",
	"1,2 clrx 3 +",
	"pi sin",
	"-1 acos pi +",

	// more complex cases
	"1 0 /",
	"1,,,+++",
	"2,,,- - -",
	"1 2 3 4 + - * /",

	//unhappy cases
	"A",
	"asiN",
	"1 2 hidden+sign",
	"1 embeddasin",
	"1E309",
	"-1E309",

	// end of the list
	NULL
};
#pragma GCC diagnostic pop
#endif
 
void evalAndPrint(char *s) {
	const char *stackLetters = "XYZTL";
	char res[] = "X:";
	float64_t x;

	Serial.println(s);
	x = rpn_eval( s, false );
	Serial.println( fp64_to_string(x,17,15) );
	for( int i = 4; i >= 0; i-- ) {
		*res = stackLetters[i];
		Serial.print( res );
		Serial.println( fp64_to_string(stack[i],17,15) );
	}
}	 

#ifdef DEBUG 
void testCalc() {
	for( byte i = 0; tests[i] != NULL; i++ ) {
		Serial.print( i ); Serial.print(": ");
		evalAndPrint( tests[i] );
		Serial.println();
	}
}
 
void setup() {
	 Serial.begin(230400);
	 
	 testCalc();
}
#else
	
void setup() {
	 Serial.begin(230400);
}

#endif	

 
void loop() {
	char readLine[128];
	String s;

	while( Serial.available() ) {
		Serial.print("rpnEval>");
		Serial.flush();
		s = Serial.readString();
		// as eval and print modifies input string, copy it to a buffer and terminate it
		strncpy( readLine, s.c_str(), 128 );
		readLine[127] ='\0';

		evalAndPrint( readLine );
	}
}
 