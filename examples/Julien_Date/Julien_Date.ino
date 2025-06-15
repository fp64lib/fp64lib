/* Copyright (c) 2019-2025  Uwe Bissinger
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
 * Another example for comparing precision between double and fp64lib,
 * calculating julien date for a given day and time. This is used as
 * base for many astronomical calculations, like determining position of the moon.
 *
 */

#define TIMEZONE	2			// delta in hours to UTC / Greenwich time
#define LOCALDATE	20250613	// date in YYYYMMDD
#define LOCALTIME	180000		// time in HHMMSS (24 hours clock)

bool verbose = true;
long start, now;
byte myHour, myMin, mySec;
int myYear;
byte myMonth, myDay;
byte lastDay[12] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
long myTime, myDate;

// convert date to julien date
float64_t fp64_julienDate( int32_t date, int32_t timezone, uint32_t time ) {
	int day = date % 100; date /= 100;
	int month = date % 100;
	int year = date / 100;
	if( month <= 2 ) {
		month += 12;
		year--;
	}
	float64_t fday = fp64_uint32_to_float64( day );
	float64_t fmonth = fp64_add( fp64_uint32_to_float64( month ), float64_NUMBER_ONE	);
	float64_t fyear = fp64_uint32_to_float64( year );
	float64_t res1 = fp64_floor( fp64_mul( fyear, fp64_atof("365.25" ) ) );
	float64_t res2 = fp64_floor( fp64_mul( fmonth, fp64_atof("30.6001") ) );
	float64_t res3 = fp64_add( fday, fp64_atof("1720981.5") );
	float64_t res4 = fp64_div( fp64_uint32_to_float64( time ), fp64_uint32_to_float64(10000));
	res4 = fp64_div( fp64_sub( res4, fp64_uint32_to_float64( TIMEZONE )), fp64_uint32_to_float64(24));
	if( verbose ) {
		Serial.print("  fp64 res1:"); Serial.println( fp64_to_string( res1, 17, 15 ) );
		Serial.print("  fp64 res2:"); Serial.println( fp64_to_string( res2, 17, 15 ) );
		Serial.print("  fp64 res3:"); Serial.println( fp64_to_string( res3, 17, 15 ) );
		Serial.print("  fp64 res4:"); Serial.println( fp64_to_string( res4, 17, 15 ) );
	}
	float64_t res  = fp64_add(fp64_add(fp64_add(res1, res2),res3),res4);
	return res;
	}

double dbl_julienDate( int32_t date, int32_t timezone, uint32_t time ) {
	int day = date % 100; date /= 100;
	int month = date % 100;
	int year = date / 100;
	if( month <= 2 ) {
		month += 12;
		year--;
	}
	long res1 = year * 365.25;
	long res2 = (month+1) * 30.6001;
	double res3 = day + 1720981.5;
	double res4 = (time / 10000.0 - TIMEZONE) / 24.0;
	if( verbose ) {
		Serial.print("double res1:"); Serial.println(res1);
		Serial.print("double res2:"); Serial.println(res2);
		Serial.print("double res3:"); Serial.println(res3,15);
		Serial.print("double res4:"); Serial.println(res4,15);
	}
	double res  = res1 + res2 + res3 + res4;
	return res;
	}
	
void setup() {
	Serial.begin(57600);
	
	float64_t fp64_jul = fp64_julienDate( LOCALDATE, TIMEZONE, LOCALTIME );
	double 	  dbl_jul  = dbl_julienDate( LOCALDATE, TIMEZONE, LOCALTIME );
	
	Serial.println();
	Serial.print( "Julien date of " ); 
	Serial.print( LOCALDATE ); Serial.print(" "); 
	Serial.print( LOCALTIME ); Serial.print(" "); Serial.println( TIMEZONE );
	Serial.print("  fp64: "); Serial.println( fp64_to_string( fp64_jul, 17, 15 ) );
	Serial.print("double: "); Serial.println( dbl_jul, 15 );

	float64_t diff = fp64_sub( fp64_sd(dbl_jul), fp64_jul );
	Serial.print( "Difference " ); 
	Serial.print( fp64_to_string( diff, 17, 15 ) );
	float64_t diffMin = fp64_mul( diff, fp64_uint32_to_float64(24*60) );
	Serial.print( " = " ); Serial.print( fp64_to_string( diffMin, 17, 4 ) );
	Serial.println( " minutes!" );
	Serial.println();
	
	long x = LOCALTIME;
	mySec = x % 100; x /= 100;
	myMin = x % 100; x /= 100;
	myHour = x;
	
	x = LOCALDATE;
	myDay = x % 100; x /= 100;
	myMonth = x % 100; x /= 100;
	myYear = x;

	verbose = false,
	start = millis();
}

// calculate a new julien date every second
// the following does not work for leapyears!!!
void loop() {
	now = millis();
	if( now-start >= 1000 ) {
		start = now;
		if( ++mySec > 59 ) { myMin++; mySec = 0; }
		if( myMin > 59 ) { myHour++; myMin = 0; }
		if( myHour > 23 ) { myDay++; myHour = 0; }
		if( myDay > lastDay[myMonth-1] ) { myMonth++; myDay = 1; } 
		if( myMonth > 12 ) { myYear++; myMonth = 1; };
		myTime = (myHour * 100l + myMin)*100l + mySec;
		myDate = (myYear * 100l + myMonth)*100l + myDay;
		
		float64_t fp64_jul = fp64_julienDate( myDate, TIMEZONE, myTime );
		Serial.print( myDate ); Serial.print(" "); 
		Serial.print( myTime ); Serial.print(" "); Serial.print( TIMEZONE );
		Serial.print(": "); Serial.println( fp64_to_string( fp64_jul, 17, 15 ) );
	}
}
