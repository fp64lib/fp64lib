#include "Double.h"

Double x = Double( 1.0 );
Double n = Double( 3.0 );
Double delta = Double( 2.0 );
bool add = false;

void setup() {
	Serial.begin(57600);
}

void loop() {

	while(1) {
		if( add )
			x = x + Double(1.0)/n;
		else
			x = x - Double(1.0)/n;
		add = !add;
		Serial.print( n.toString() );
		Serial.print(": ");
		Serial.print( x.toString() );
		Serial.print("\t");
		Double pi = x * Double(4.0);
		Serial.println( pi.toString() );
		n = n + Double(2.0);
	}
	
}
	