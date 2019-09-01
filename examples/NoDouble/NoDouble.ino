/* 
 * Example program to compare overhead regarding Double wrapper class.
 * Leibniz formular to approximate PI
 *
 */

#include <fp64lib.h>

#define MAX_COUNT   1000    // # of iterations before printing another approximation
float64_t x = float64_NUMBER_ONE;
float64_t n = fp64_sd(3.0);
float64_t delta = fp64_sd(2.0);
bool add = false;

void setup() {
	Serial.begin(57600);
}

void loop() {
	int cnt = 0;

	while(1) {
		if( add )
			x = fp64_add( x, fp64_inverse(n) );
		else
			x = fp64_sub( x, fp64_inverse(n) );
		add = !add;
		if( ++cnt == MAX_COUNT ) {
			char *s = fp64_to_string( n, 17, 0 );
			Serial.print( s );
			Serial.print(": ");
			s = fp64_to_string( x, 17, 15 );
			Serial.print( s );
			Serial.print("\t");
			float64_t pi = fp64_mul( x, fp64_sd(4.0) );
			s = fp64_to_string( pi, 17, 15 );
			Serial.println( s );
			cnt = 0;
		}
		n = fp64_add( n, delta );
	}
	
}
	