/*
   Copyright 2009 Marcus Liang

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.


  Arduino Code for QlockTwo Clone
  http://www.flickr.com/photos/19203306@N00/sets/72157622998814956/ 
 
 */

#include <WProgram.h>
#include <Wire.h>
#include <DS1307.h>  
#include <LedControl.h>
#include <binary.h>

// lines to drive the two MAX7219 LED controllers
const int LC1CLK   = 5;
const int LC1LOAD  = 6;
const int LC1DATA  = 7;
const int LC2CLK   = 2;
const int LC2LOAD  = 3;
const int LC2DATA  = 4;
// clock (RTC) uses analog pin4 (SDA) and pin5 (CLK) for i2c communication

// four input buttons
const int BUT1 = 12;  // minute++
const int BUT2 = 11;  // hour++
const int BUT3 = 10;  // change mode++
const int BUT4 = 9;   // change LED brightness++

// LED intensity  
// Four levels of light intensity plus off
const int LEDOFF  = 0;  // not really off
const int LEDINT1 = 1;
const int LEDINT2 = 7;
const int LEDINT3 = 11;
const int LEDINT4 = 15;

// MODE
const int MODEDEFAULT = 0;
const int MODEDEFAULTSEC = 1;
const int MODESECONDS = 2;

// update/debounce delays
const int ledDelay = 200;       // ms

// Global vars for tracking;

unsigned long ledLastUpdate = 0;
int currentLEDIntensity = LEDINT2;
int currentMode = MODEDEFAULT;
boolean forceUpdate = true;

//int lHour, lMin;
int cHour, cMin, cSec;

LedControl LC1=LedControl(LC1DATA, LC1CLK, LC1LOAD, 1); 
LedControl LC2=LedControl(LC2DATA, LC2CLK, LC2LOAD, 1);

void setup(void) {

  // setup pins
  pinMode (LC1CLK, OUTPUT);
  pinMode (LC1LOAD, OUTPUT);
  pinMode (LC1DATA, OUTPUT);
  pinMode (LC2CLK, OUTPUT);
  pinMode (LC2LOAD, OUTPUT);
  pinMode (LC2DATA, OUTPUT);
  pinMode (BUT1, INPUT);
  pinMode (BUT2, INPUT);
  pinMode (BUT3, INPUT);
  pinMode (BUT4, INPUT);

  // turn on LED controller;
  LC1.shutdown(0,false);
  LC2.shutdown(0,false);

  setLEDIntensity(LEDINT3);
}


unsigned long but1LastPress = 0;  
unsigned long but2LastPress = 0;  
unsigned long but3LastPress = 0;  
unsigned long but4LastPress = 0;  
const int buttonPressDelay = 600;

void loop(void) {

  // buttons
  int but1read = digitalRead(BUT1);
  int but2read = digitalRead(BUT2);
  int but3read = digitalRead(BUT3);
  int but4read = digitalRead(BUT4);

  if ((but1read == HIGH) && ((millis() - but1LastPress) > buttonPressDelay)) {
    but1LastPress = millis();
    doButton1();
  }
  else if ((but1read == LOW) && ((millis() - but1LastPress) > buttonPressDelay ))
   but1LastPress = 0;  // reset
  
  if ((but2read == HIGH) && ((millis() - but2LastPress) > buttonPressDelay)) {
    but2LastPress = millis();
    doButton2();
  }
  else if ((but2read == LOW) && ((millis() - but2LastPress) > buttonPressDelay ))
    but2LastPress = 0;  // reset

  if ((but3read == HIGH) && ((millis() - but3LastPress) > buttonPressDelay)) {
    but3LastPress = millis();
    doButton3();
  }
  else if ((but3read == LOW) && ((millis() - but3LastPress) > buttonPressDelay ))
    but3LastPress = 0;  // reset


  if ((but4read == HIGH) && ((millis() - but4LastPress) > buttonPressDelay)) {
    but4LastPress = millis();
    doButton4();
  }
  else if ((but4read == LOW) && ((millis() - but4LastPress) > buttonPressDelay ))
    but4LastPress = 0;  // reset
    
  if ((millis() - ledLastUpdate) > ledDelay) {
    ledLastUpdate = millis();

      if (currentMode == MODEDEFAULT) mode_default();
      else if (currentMode == MODEDEFAULTSEC) mode_defaultsec();
      else if (currentMode == MODESECONDS) mode_seconds();

  }
}

void setLEDIntensity(int targetIntensity) {
   if (targetIntensity == LEDOFF) {
	  while (currentLEDIntensity > targetIntensity) {
		currentLEDIntensity = currentLEDIntensity - 1;
		LC1.setIntensity(0,currentLEDIntensity);
		LC2.setIntensity(0,currentLEDIntensity);
		delay(20);
	  }
  }
  else {
	while (currentLEDIntensity < targetIntensity) {
		currentLEDIntensity = currentLEDIntensity + 1;
		LC1.setIntensity(0,currentLEDIntensity);
		LC2.setIntensity(0,currentLEDIntensity);
		delay(50);
	}
  }
}

void doButton1() {
  // update hour
  int hour = RTC.get(DS1307_HR,true);
  if (hour == 23) hour = 0;
  else hour = hour + 1;
  RTC.set(DS1307_HR,hour);
}

void doButton2() {
  // update minutes
  int min = RTC.get(DS1307_MIN,true);
  if (min == 59) min = 0;
  else min = min+1;
  RTC.set(DS1307_MIN,min);
  RTC.set(DS1307_SEC,0);              // always zero the seconds.
}

void doButton3() {
  // mode change

  if (currentMode == MODEDEFAULT) currentMode = MODEDEFAULTSEC;
  else if (currentMode == MODEDEFAULTSEC) currentMode = MODESECONDS;
  else if (currentMode == MODESECONDS) currentMode = MODEDEFAULT;
  //else if (currentMode == MODESECONDS) currentMode = MODEDIAG;
  //else if (currentMode == MODEDIAG) currentMode = MODEDEFAULT;
  
  LED_CLEAR();
  forceUpdate = true; 

}

void doButton4() {
  // change LED intensity
  int targetIntensity;

  /*
  if (currentLEDIntensity == LEDOFF) targetIntensity = LEDINT1;
   else if (currentLEDIntensity == LEDINT1) targetIntensity = LEDINT2;
   else if (currentLEDIntensity == LEDINT2) targetIntensity = LEDINT3;
   else if (currentLEDIntensity == LEDINT3) targetIntensity = LEDINT4;
   else if (currentLEDIntensity == LEDINT4) targetIntensity = LEDOFF;
   else targetIntensity = LEDINT2; // something stupid has happened, so set back to default;
   */
  switch (currentLEDIntensity) {
	case LEDOFF:
		targetIntensity = LEDINT1;
		break;
	case LEDINT1: 
		targetIntensity = LEDINT2;
		break;
	case LEDINT2:
		targetIntensity = LEDINT3;
		break;
	case LEDINT3: 
		targetIntensity = LEDINT4;
		break;
	case LEDINT4:
		targetIntensity = LEDOFF;
		break;
	default:        // something horrible has gone wrong and the intensity has moved out of the predefined mode.
		targetIntensity = LEDINT2;
  }
  setLEDIntensity(targetIntensity);
}




// MODE DEFAULT 
// Description: This is the default mode of operation.  The words light up based on the time and the 4 corners light up 
// 				based on the minutes past 5 minutes.
//  

void mode_default() {

   int hour = RTC.get(DS1307_HR,true);
   int min = RTC.get(DS1307_MIN,true);
   int sec = RTC.get(DS1307_SEC,false); // kinda redundant?
   
   if ((hour == cHour) && (min == cMin) && (forceUpdate == false))
		return;
   	
   int tpast5mins = min % 5; // remainder
   int t5mins = min - tpast5mins;
   int tHour = hour;
   
   if (tHour > 12) tHour = tHour - 12;
   else if (tHour == 0) tHour = 12;
   
   LED_CLEAR();
   W_ITIS();
   
   if (t5mins == 5 || t5mins == 55)     M_FIVE();        // 5 past or 5 to..
   else if (t5mins == 10 || t5mins == 50)    M_TEN();        // 10 past or 10 to..
   else if (t5mins == 15 || t5mins == 45)    M_AQUARTER();    // etc..
   else if (t5mins == 20 || t5mins == 40)    M_TWENTY();
   else if (t5mins == 25 || t5mins == 35)    M_TWENTYFIVE();
   else if (t5mins == 30)    M_HALF();

   // past or to or o'clock?
   if (t5mins == 0)	W_OCLOCK();
   else if (t5mins > 30)	W_TO();
   else W_PAST();
   
   if (t5mins > 30)	{
		tHour = tHour+1;
		if (tHour > 12) tHour = 1;
   }

   // light up the hour word
   if (tHour == 1) H_ONE(); else if (tHour == 2) H_TWO(); else if (tHour == 3) H_THREE(); else if (tHour == 4) H_FOUR();
   else if (tHour == 5) H_FIVE(); else if (tHour == 6) H_SIX(); else if (tHour == 7) H_SEVEN(); else if (tHour == 8) H_EIGHT();
   else if (tHour == 9) H_NINE(); else if (tHour == 10) H_TEN(); else if (tHour == 11) H_ELEVEN(); else if (tHour == 12) H_TWELVE();
   
   // light up aux minute LED
   // ugly but quicker 
   if (tpast5mins == 0 ) { }
   else if (tpast5mins == 1) { P_ONE(); }
   else if (tpast5mins == 2) { P_ONE(); P_TWO(); }
   if (tpast5mins == 3) { P_ONE(); P_TWO(); P_THREE(); }
   if (tpast5mins == 4) { P_ONE(); P_TWO(); P_THREE(); P_FOUR(); }

   // save last updated time
   cHour = hour;
   cMin = min;
   cSec = sec;
   forceUpdate = false;
}

// MODE DEFAULTSEC
// Description: This is like Mode default except that the dots in the four corners will change every second.
void mode_defaultsec() {
   int hour = RTC.get(DS1307_HR,true);
   int min = RTC.get(DS1307_MIN,false);
   int sec = RTC.get(DS1307_SEC,true); 
   
   // minute or hour has changed,..
   if ((hour != cHour) || (min != cMin) || (forceUpdate == true))  {
  
	   int tpast5mins = min % 5; // remainder
	   int t5mins = min - tpast5mins;
	   int tHour = hour;

           // we don't do 24H clocks
           if (tHour > 12) tHour = tHour - 12;
           else if (tHour == 0) tHour = 12;
  
	   
	   LED_CLEAR();
	   W_ITIS();
  	   
       if (t5mins == 5 || t5mins == 55)     M_FIVE();        // 5 past or 5 to..
       else if (t5mins == 10 || t5mins == 50)    M_TEN();        // 10 past or 10 to..
       else if (t5mins == 15 || t5mins == 45)    M_AQUARTER();    // etc..
       else if (t5mins == 20 || t5mins == 40)    M_TWENTY();
       else if (t5mins == 25 || t5mins == 35)    M_TWENTYFIVE();
       else if (t5mins == 30)    M_HALF();
           
	   // past or to or o'clock?
	   if (t5mins == 0)	W_OCLOCK();
	   else if (t5mins > 30)	W_TO();
	   else W_PAST();
	   
	   if (t5mins > 30)	{
			tHour = tHour+1;
			if (tHour > 12) tHour = 1;
	   }
		
	   // light up the hour word
	   if (tHour == 1) H_ONE(); else if (tHour == 2) H_TWO(); else if (tHour == 3) H_THREE(); else if (tHour == 4) H_FOUR();
	   else if (tHour == 5) H_FIVE(); else if (tHour == 6) H_SIX(); else if (tHour == 7) H_SEVEN(); else if (tHour == 8) H_EIGHT();
	   else if (tHour == 9) H_NINE(); else if (tHour == 10) H_TEN(); else if (tHour == 11) H_ELEVEN(); else if (tHour == 12) H_TWELVE();
	}
	
	if (sec != cSec) {
		// update the seconds;
		//P_CLEAR();
		int r = sec % 10;

                if (r > 5) r = r - 5;

		// 4 patterns.
		// 0-4,   5-9,   10-14, 15-19 then repeat.
		// 20-24, 25-29, 30-34, 35-39
		// 40-44, 45-49, 50-54, 55-59
	
		if (((sec > 0) && (sec < 5)) || ((sec > 20) && (sec < 25)) || ((sec > 40) && (sec < 45))) {
			if (r == 1) { P_ONE(); }
			else if (r == 2) {  P_ONE();  P_TWO(); }
			else if (r == 3) {  P_ONE(); P_TWO();  P_THREE();}
			else if (r == 4) {  P_ONE(); P_TWO(); P_THREE(); P_FOUR();}
		}
	
		else if (((sec > 5) && (sec < 10)) || ((sec > 25) && (sec < 30)) || ((sec > 45) && (sec < 50))) {
			if (r == 1) { P_TWO(); }
			else if (r == 2) { P_TWO(); P_THREE(); }
			else if (r == 3) { P_TWO(); P_THREE(); P_FOUR();}
			else if (r == 4) { P_TWO(); P_THREE(); P_FOUR(); P_ONE();}
		}
		
		else if (((sec > 10) && (sec < 15)) || ((sec > 30) && (sec < 35)) || ((sec > 50) && (sec < 55)))  {
			if (r == 1) { P_THREE(); }
			else if (r == 2) { P_THREE(); P_FOUR(); }
			else if (r == 3) { P_THREE(); P_FOUR(); P_ONE();}
			else if (r == 4) { P_THREE(); P_FOUR(); P_ONE(); P_TWO();}
		}
				
		else if (((sec > 15) && (sec < 20)) || ((sec > 35) && (sec < 40)) || ((sec > 55) && (sec < 60)))  {
			if (r == 1) { P_FOUR(); }
			else if (r == 2) { P_FOUR(); P_ONE(); }
			else if (r == 3) { P_FOUR(); P_ONE(); P_TWO();}
			else if (r == 4) { P_FOUR(); P_ONE(); P_TWO(); P_THREE();}
		}
		
		else if ((r == 0)  || (r == 5)) {
    		      P_CLEAR();
		}
	}

	// save last updated time
   cHour = hour;
   cMin = min;
   cSec = sec;
   forceUpdate = false;   
}


// MODE SECONDS
// Description: The entire face will show the "seconds" the clock is on
void mode_seconds() {
   
   int hour = RTC.get(DS1307_HR,true);
   int min = RTC.get(DS1307_MIN,false);
   int sec = RTC.get(DS1307_SEC,true); 

   // no seconds change, do nothing
   if (sec == cSec) return;
 
   int tsec = sec;
    
   // decide if we only want to draw the right number of both numbers.
   // reduce the apparentness of the flicker of the non changing digit.
   if ((tsec - (tsec % 10) != cSec - (cSec % 10)) || (forceUpdate == true)) {
     LED_CLEAR();   
     if (tsec < 10) L_ZERO();
     else if (tsec < 20)  L_ONE();
     else if (tsec < 30)  L_TWO();
     else if (tsec < 40)  L_THREE();
     else if (tsec < 50)  L_FOUR();
     else L_FIVE();
   }
   else {
    R_CLEAR();
   }  
   
   // seconds have changed, draw the seconds.
	
	tsec = tsec % 10;

	if (tsec == 0) R_ZERO();
	if (tsec == 1) R_ONE();
	if (tsec == 2) R_TWO();
	if (tsec == 3) R_THREE();
	if (tsec == 4) R_FOUR();
	if (tsec == 5) R_FIVE();
	if (tsec == 6) R_SIX();
	if (tsec == 7) R_SEVEN();
	if (tsec == 8) R_EIGHT();
	if (tsec == 9) R_NINE();
   
   // save last updated time
   cHour = hour;
   cMin = min;
   cSec = sec;   
   forceUpdate = false;   
   
}


/* For the LED code below to work, the LEDs need to be wired in a very specific way
   
   Normally a MAX7219's matrix is wired this way (8x8)

    dp| a| b| c| d| e| f| g
  0
  1
  2
  4
  5
  6
  7
   
  However, since the clock is 10x11 we wire 2x MAX7219 this way.
  Essentially, row 5,6,7 is transposed into column 9,10,11
    
  [dp,5]                         [g,5]
  -----------------------------------
   dp| a| b| c| d| e| f| g| 5| 6| 7
  0                       |         e
  1                       |         d
  2                       |         c
  3                       |         b
  4                       |         a
  -----------------------------------
   dp| a| b| c| d| e| f| g| 5| 6| 7
  0                       |         e
  1                       |         d
  2                       |         c
  3                       |         b
  4                       |         a
  ------------------------------------
  [dp,5]                         [g,5]
 
*/

// LED Turn on/off procedures
void LED_CLEAR() {
  LC1.clearDisplay(0);
  LC2.clearDisplay(0);
}
void R_CLEAR() {
  LC1.setColumn(0,6,B00000000);
  LC1.setColumn(0,7,B00000000);
  LC1.setRow(0,5,B00000000);
  LC1.setRow(0,6,B00000000);
  LC1.setRow(0,7,B00000000);
  LC2.setColumn(0,6,B00000000);
  LC2.setColumn(0,7,B00000000);
  LC2.setRow(0,5,B00000000);
  LC2.setRow(0,6,B00000000);
  LC2.setRow(0,7,B00000000);
  
}

void M_FIVE() {
	LC1.setRow(0,2,B00000011); // FI
	LC1.setLed(0,5,3, true); // V
	LC1.setLed(0,6,3, true); // E
}
void M_TEN() {
	LC1.setRow(0,3,B00000111);
}
void M_AQUARTER() {
	LC1.setRow(0,1,B10111111); // A QUARTE
	LC1.setLed(0,5,4, true); // R
}
void M_TWENTY() {
	LC1.setRow(0,2,B11111100); // TWENTY
}
void M_TWENTYFIVE() {
	LC1.setRow(0,2,B11111111); // TWENTYFI
	LC1.setLed(0,5,3, true); // V
	LC1.setLed(0,6,3, true); // E
}
void M_HALF() {
	LC1.setRow(0,3,B11110000); // HALF
}
void W_ITIS() {
	// Row0 "IT IS" (R0=216) OO.OO.......
	LC1.setRow(0,0,B11011000);  // IT IS
}
void W_OCLOCK() {
	LC2.setLed(0,4,5,true); // O'
	LC2.setLed(0,4,6,true); // C
	LC2.setLed(0,4,7,true);	// L
	LC2.setLed(0,5,1,true); // O
	LC2.setLed(0,6,1,true); // C
	LC2.setLed(0,7,1,true);	// K
}
void W_TO() {
	LC1.setLed(0,6,2,true); // T
	LC1.setLed(0,7,2,true); // O
}

void W_PAST(){
	//LC1.setRow(0,0,B11110000); // PAST
	LC1.setLed(0,4,0,true); // P
	LC1.setLed(0,4,1,true); // A
	LC1.setLed(0,4,2,true); // S
	LC1.setLed(0,4,3,true); // T
}

void H_ONE(){
	LC2.setRow(0,0,B11100000); // ONE
}

void H_TWO(){
	LC2.setLed(0,5,4,true); // T
	LC2.setLed(0,6,4,true); // W
	LC2.setLed(0,7,4,true);  // O
}
void H_THREE(){
	LC2.setRow(0,0,B00000011); // TH
	LC2.setLed(0,5,5, true); //R
	LC2.setLed(0,6,5, true); //E
	LC2.setLed(0,7,5, true); //E
}
void H_FOUR(){
	LC2.setRow(0,1,B11110000); // FOUR
}
void H_FIVE(){
	LC2.setRow(0,1,B00001111); // FIVE
}
void H_SIX(){
	LC2.setRow(0,0,B00011100); // SIX
}
void H_SEVEN(){
	LC2.setRow(0,3,B11111000); // SEVEN...
}

void H_EIGHT(){
	LC2.setRow(0,2,B11111000);  //EIGHT...
}

void H_NINE(){
	LC1.setLed(0,4,7,true); // N
   	LC1.setLed(0,5,1,true); // I
  	LC1.setLed(0,6,1,true); // N
  	LC1.setLed(0,7,1,true); // E
}

void H_TEN(){
	LC2.setLed(0,4,0,true); // T
	LC2.setLed(0,4,1,true); // E
	LC2.setLed(0,4,2,true);	// N
}

void H_ELEVEN(){
	LC2.setRow(0,2,B00000111); //ELE
	LC2.setLed(0,5,3,true); //V
	LC2.setLed(0,6,3,true); //E
	LC2.setLed(0,7,3,true); //N
}
void H_TWELVE(){
	LC2.setRow(0,3,B00000111); // TWE
	LC2.setLed(0,5,2,true); //L
	LC2.setLed(0,6,2,true); //V
	LC2.setLed(0,7,2,true); //E
}

void P_ONE() {
    LC1.setLed(0,5,0,true); // top left
}
void P_TWO() {
	LC1.setLed(0,5,7,true); // top right
}
void P_THREE() {
	LC2.setLed(0,5,7,true);// bottom right

}
void P_FOUR() {
	LC2.setLed(0,5,0,true); // bottom left
}


// SECONDS COUNTER MODE
void L_ZERO(){
	LC1.setRow(0,2,B01110000);
	LC1.setRow(0,3,B10001000);
	LC1.setRow(0,4,B10011000);
	LC2.setRow(0,0,B10101000);
	LC2.setRow(0,1,B11001000);
	LC2.setRow(0,2,B10001000);
	LC2.setRow(0,3,B01110000);
}

void L_ONE(){
	LC1.setRow(0,2,B00100000);
	LC1.setRow(0,3,B01100000);
	LC1.setRow(0,4,B00100000);
	LC2.setRow(0,0,B00100000);
	LC2.setRow(0,1,B00100000);
	LC2.setRow(0,2,B00100000);
	LC2.setRow(0,3,B01110000);
}
void L_TWO(){
	LC1.setRow(0,2,B01110000);
	LC1.setRow(0,3,B10001000);
	LC1.setRow(0,4,B00001000);
	LC2.setRow(0,0,B00010000);
	LC2.setRow(0,1,B00100000);
	LC2.setRow(0,2,B01000000);
	LC2.setRow(0,3,B11111000);
}
void L_THREE(){
	LC1.setRow(0,2,B11111000);
	LC1.setRow(0,3,B00010000);
	LC1.setRow(0,4,B00100000);
	LC2.setRow(0,0,B00010000);
	LC2.setRow(0,1,B00001000);
	LC2.setRow(0,2,B10001000);
	LC2.setRow(0,3,B01110000);
}
void L_FOUR(){
	LC1.setRow(0,2,B00010000);
	LC1.setRow(0,3,B00110000);
	LC1.setRow(0,4,B01010000);
	LC2.setRow(0,0,B10010000);
	LC2.setRow(0,1,B11111000);
	LC2.setRow(0,2,B00010000);
	LC2.setRow(0,3,B00010000);
}
void L_FIVE(){
	LC1.setRow(0,2,B11111000);
	LC1.setRow(0,3,B10000000);
	LC1.setRow(0,4,B10000000);
	LC2.setRow(0,0,B11110000);
	LC2.setRow(0,1,B00001000);
	LC2.setRow(0,2,B10001000);
	LC2.setRow(0,3,B01110000);
}
void R_ZERO(){
	LC1.setColumn(0,6,B00011000);
	LC1.setLed(0,2,7,true);
        LC1.setLed(0,5,3,true);
	LC1.setRow(0,6,B01010000);
	LC1.setRow(0,7,B01100000);
	LC2.setColumn(0,6,B11100000);
	LC2.setColumn(0,7,B01010000);
	LC2.setRow(0,5,B00100100);
	LC2.setRow(0,6,B00100000);
        LC2.setRow(0,7,B00011100);
}
void R_ONE(){
	LC1.setLed(0,3,7,true);
	LC1.setRow(0,5,B01110000);
	LC2.setRow(0,5,B00111100);
	LC2.setLed(0,3,7,true);
	LC2.setLed(0,6,2,true);
}
void R_TWO(){
	LC1.setLed(0,3,6,true);
	LC1.setLed(0,2,7,true);
	LC1.setLed(0,5,3,true);
	LC1.setLed(0,6,3,true);
	LC1.setRow(0,7,B01100000);
	
	LC2.setLed(0,3,6,true);
	LC2.setColumn(0,7,B00110000);
	LC2.setRow(0,5,B00101000);
	LC2.setRow(0,6,B00100100);
	LC2.setLed(0,7,2,true);
}

void R_THREE(){
	LC1.setLed(0,2,6,true);
	LC1.setLed(0,2,7,true);
	LC1.setRow(0,5,B01010000);
	LC1.setRow(0,6,B00110000);
	LC1.setLed(0,7,3,true);

	LC2.setLed(0,2,6,true);
	LC2.setLed(0,3,7,true);
	LC2.setLed(0,5,2,true);
	LC2.setRow(0,6,B00100100);
	LC2.setRow(0,7,B00011000);
}

void R_FOUR(){
	LC1.setLed(0,4,7,true);
	LC1.setLed(0,5,2,true);
	LC1.setRow(0,6,B01110000);
	
	LC2.setColumn(0,6,B11000000);
	LC2.setLed(0,1,7,true);
	LC2.setLed(0,5,4,true);
	LC2.setRow(0,6,B00111100);
	LC2.setLed(0,7,4,true);
}

void R_FIVE(){
	LC1.setColumn(0,6,B00111000);
	LC1.setLed(0,2,7,true);
	LC1.setLed(0,5,3,true);
	LC1.setLed(0,6,3,true);
	LC1.setLed(0,7,3,true);
	
	LC2.setColumn(0,6,B10100000);
	LC2.setColumn(0,7,B10010000);
	LC2.setRow(0,5,B00100100);
	LC2.setRow(0,6,B00100100);
	LC2.setRow(0,7,B00011000);
}

void R_SIX(){
	LC1.setLed(0,4,6,true);
	LC1.setLed(0,3,7,true);
	LC1.setLed(0,5,3,true);
	LC1.setLed(0,6,3,true);
	
	LC2.setColumn(0,6,B11100000);
	LC2.setColumn(0,7,B10010000);
	LC2.setRow(0,5,B00100100);
	LC2.setRow(0,6,B00100100);
	LC2.setRow(0,7,B00011000);	
}

void R_SEVEN(){
	LC1.setLed(0,2,6,true);
	LC1.setLed(0,2,7,true);
	LC1.setLed(0,5,3,true);
	LC1.setRow(0,6,B01010000);
	LC1.setRow(0,7,B00110000);
	
	LC2.setColumn(0,7,B01110000);
	LC2.setLed(0,5,5,true);
}

void R_EIGHT(){
	LC1.setColumn(0,6,B00011000);
	LC1.setLed(0,2,7,true);
	LC1.setLed(0,5,3,true);
	LC1.setLed(0,6,3,true);
	LC1.setRow(0,7,B01100000);
	
	LC2.setColumn(0,6,B01100000);
	LC2.setColumn(0,7,B10010000);
	LC2.setRow(0,5,B00100100);
	LC2.setRow(0,6,B00100100);
	LC2.setRow(0,7,B00011000);	
}

void R_NINE(){
	LC1.setColumn(0,6,B00011000);
	LC1.setLed(0,2,7,true);
	LC1.setLed(0,5,3,true);
	LC1.setLed(0,6,3,true);
	LC1.setRow(0,7,B01100000);
	
	LC2.setColumn(0,7,B10010000);
	LC2.setRow(0,5,B00100100);
	LC2.setRow(0,6,B00010100);
	LC2.setRow(0,7,B00001100);
}

// for dot mode - clear the 4 dots only.
void P_CLEAR() {
	LC1.setLed(0,5,0,false); // top left
	LC1.setLed(0,5,7,false); // top right
	LC2.setLed(0,5,0,false); // top left	
	LC2.setLed(0,5,7,false); // bottom right
}



/* 

void vocabSingleTest() {
	int dly = 800;
	LED_CLEAR();

	W_ITIS();
	delay(dly); LED_CLEAR();
	M_AQUARTER();
	delay(dly); LED_CLEAR();
	M_TWENTY();
	delay(dly); LED_CLEAR();
	M_FIVE();
	delay(dly); LED_CLEAR();
	M_TWENTYFIVE();
	delay(dly); LED_CLEAR();
	M_HALF();
	delay(dly); LED_CLEAR();
	M_TEN();
	delay(dly); LED_CLEAR();
	W_TO();
	delay(dly); LED_CLEAR();
	W_PAST();
	delay(dly); LED_CLEAR();
	H_NINE();
	delay(dly); LED_CLEAR();
	H_ONE();
	delay(dly); LED_CLEAR();
	H_SIX();
	delay(dly); LED_CLEAR();
	H_THREE();
	delay(dly); LED_CLEAR();
	H_FOUR();
	delay(dly); LED_CLEAR();
	H_FIVE();
	delay(dly); LED_CLEAR();
	H_TWO();
	delay(dly); LED_CLEAR();
	H_EIGHT();
	delay(dly); LED_CLEAR();
	H_ELEVEN();
	delay(dly); LED_CLEAR();
	H_SEVEN();
	delay(dly); LED_CLEAR();
	H_TWELVE();
	delay(dly); LED_CLEAR();
	H_TEN();
	delay(dly); LED_CLEAR();
	W_OCLOCK();
	delay(dly); LED_CLEAR();
	P_ONE();
	delay(dly); LED_CLEAR();
	P_TWO();
	delay(dly); LED_CLEAR();
	P_THREE();
	delay(dly); LED_CLEAR();
	P_FOUR();
	delay(dly); LED_CLEAR();
	
	L_ZERO();
	delay(dly); LED_CLEAR();
	L_ONE();
	delay(dly); LED_CLEAR();
	L_TWO();
	delay(dly); LED_CLEAR();
	L_THREE();
	delay(dly); LED_CLEAR();
	L_FOUR();
	delay(dly); LED_CLEAR();
	L_FIVE();
	delay(dly); LED_CLEAR();

	R_ZERO();
	delay(dly); LED_CLEAR();
	R_ONE();
	delay(dly); LED_CLEAR();
	R_TWO();
	delay(dly); LED_CLEAR();
	R_THREE();
	delay(dly); LED_CLEAR();
	R_FOUR();
	delay(dly); LED_CLEAR();
	R_FIVE();
	delay(dly); LED_CLEAR();
	R_SIX();
	delay(dly); LED_CLEAR();
	R_SEVEN();
	delay(dly); LED_CLEAR();
	R_EIGHT();
	delay(dly); LED_CLEAR();
	R_NINE();
	delay(dly); LED_CLEAR();
	

	L_ZERO();
	R_ZERO();
	delay(dly); LED_CLEAR();
	L_ZERO();
	R_ONE();
	delay(dly); LED_CLEAR();
	L_ZERO();
	R_TWO();
	delay(dly); LED_CLEAR();
	L_ZERO();
	R_THREE();
	delay(dly); LED_CLEAR();
	L_ZERO();
	R_FOUR();
	delay(dly); LED_CLEAR();
	L_ZERO();
	R_FIVE();
	delay(dly); LED_CLEAR();
	L_ZERO();
	R_SIX();
	delay(dly); LED_CLEAR();
	L_ZERO();
	R_SEVEN();
	delay(dly); LED_CLEAR();
	L_ZERO();
	R_EIGHT();
	delay(dly); LED_CLEAR();
	L_ZERO();
	R_NINE();
	delay(dly); LED_CLEAR();

}

void glowTest() {
    while (true) {
    for  (int i=1; i <= 15; i++) {
      LC1.setIntensity(0,i);
      LC2.setIntensity(0,i);
      delay(50);
    }

    for  (int i=14; i >= 0; i--) {
      LC1.setIntensity(0,i);
      LC2.setIntensity(0,i);
      delay(50);
    }
    }
}

*/