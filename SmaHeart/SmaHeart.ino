#include <EEPROM.h>

//Required libraries to install:
//Adafruit_CAP1188_Library - manual install: https://github.com/adafruit/Adafruit_CAP1188_Library (download repository as zip)
//Adafruit NeoPixel - availible through library manager.


#include <Adafruit_NeoPixel.h>
#include <Wire.h>
#include <SPI.h>         // needed for Arduino versions later than 0018
#include <Ethernet.h>
#include <EthernetUdp.h>         // UDP library from: bjoern@cs.stanford.edu 12/30/2008
#include <Adafruit_CAP1188.h>

//captouch stuff
Adafruit_CAP1188 cap = Adafruit_CAP1188();
byte last_state = 0;
bool initial_state_sent = false;

//network stuff
byte BoardId;
byte mac[] = {0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED};
IPAddress LocalIp;
IPAddress RemoteIp(192, 168, 1, 109 );
EthernetUDP Udp;
unsigned int localPort = 8888;      // local port to listen on
unsigned int remotePort = 8888;



//led stuff:
#define LED_COUNT 8
#define LED_PIN 6
Adafruit_NeoPixel strip = Adafruit_NeoPixel(LED_COUNT, LED_PIN, NEO_GRB + NEO_KHZ800);




void setup() {
  Serial.begin(9600);


  //board ID & Network stuff:
  //ClearId();
  BoardId = GetBoardId();
  mac[5] = BoardId; //set the last byte of the mac address to the board ID.
  byte ip_lower = 150 + constrain( BoardId, 0, (254 - 150));
  LocalIp = IPAddress(192, 168, 1, ip_lower );

  Serial.print("mac: ");
  for ( int i = 0; i < 6; ++i ) {
    Serial.print(mac[i], HEX);
    Serial.print(" ");
  }
  Serial.println();
  Serial.print("IP: 192.168.1.");
  Serial.println(ip_lower, DEC);

  Ethernet.begin(mac, LocalIp);
  Udp.begin(localPort);


  //captouch stuff:
  if (!cap.begin()) {
    Serial.println("CAP1188 not found");
    while (1);
  }
  Serial.println("CAP1188 found!");

  //LED stuff:
  strip.begin();
  strip.show(); // Initialize all pixels to 'off'
}


void loop() {
  ProcessTouches();
  delay(5);
}

void ProcessTouches()
{
  byte touched = cap.touched();

  if( initial_state_sent == false ) {
    initial_state_sent = true;
    HandleStateChanged( touched );
  } else {
    if( touched != last_state ) {
      HandleStateChanged( touched );
    }
    
  }
  last_state = touched;
}

void HandleStateChanged( byte state ) {
  //the input state has changed!
  Serial.print("state update: ");
  Serial.println(state, BIN);

  //send the state over the network.
  TransmitState( state, BoardId );


  //LED opperations
  for(int i = 0; i < 8; ++i ) {
    if( state & (1<<i)) {
      strip.setPixelColor( i, strip.Color(127, 127, 127) );
    } else {
      strip.setPixelColor( i, strip.Color(0, 0, 0) );
    }
  }
  strip.show();
}

void TransmitState( byte state, byte board_id ) {

  
  char tx_buffer[32];
  snprintf(tx_buffer, 32, "board:%i,state:%i\n", board_id, state);

  Serial.print("udp tx message: ");
  Serial.println(tx_buffer);
  //return;
  
  Udp.beginPacket(RemoteIp, remotePort);
  Udp.write(tx_buffer, strlen(tx_buffer));
  Udp.endPacket();
  
}
/*
void HandleTouchDown( int key )
{
  strip.setPixelColor( key, strip.Color(127, 127, 127) );
  strip.show();
  
  Serial.print("key-down event: ");
  Serial.println(key, DEC);

  Udp.beginPacket(RemoteIp, remotePort);
  Udp.write("keydown:");
  Udp.write((char)('0'+key));
  Udp.endPacket();
}

void HandleTouchUp( int key )
{
  strip.setPixelColor( key, strip.Color(0, 0, 0) );
  strip.show();
  
  Serial.print("key-up event: ");
  Serial.println(key, DEC);

  Udp.beginPacket(RemoteIp, remotePort);
  Udp.write("keyup:");
  Udp.write((char)('0'+key));
  Udp.endPacket();
}*/


void ClearId()
{
  Serial.println("manually clearing board ID and signature.");
  for ( int i = 0; i < 6; ++i )
    EEPROM.update(i, 0xFF);
}

byte GetBoardId()
{
  //check to see if a value has been set:
  char signature[5];
  char reference[5] = "MARK";
  const int signature_address = 0;
  const int board_id_address = 5;
  byte board_id = 0;
  byte read_board_id;


  //read the current signature slot.
  EEPROM.get(signature_address, signature);
  EEPROM.get(board_id_address, read_board_id);

  //print the hex values shown here.
  /*Serial.print("signature(from memory): ");
    for( int i = 0; i < 5; ++i )
    {
    Serial.print((byte)(signature[i]), HEX);
    Serial.print(" ");
    }
    Serial.println();
    Serial.print("board id(from memory): 0x");
    Serial.println(read_board_id, HEX);*/

  //check to see if the signature has been set.
  if ( strcmp( signature, reference ) == 0 ) {
    Serial.print("board id loaded: ");
    Serial.println(read_board_id, DEC);
    return read_board_id; //we're all good!

  }
  Serial.println("signature did not match!");

  Serial.println("Please enter a board ID (decimal number, 0 to 255)");

  bool valid_reply = false;

  while (true)
  {
    while ( Serial.available() <= 0 );
    int new_value = Serial.parseInt();
    if ( new_value >= 0 && new_value <= 255 ) {
      board_id = new_value;
      valid_reply = true;
      EEPROM.put(signature_address, reference);
      EEPROM.put(board_id_address, board_id);
      Serial.print("Success, the new board ID is: 0x");
      Serial.print(board_id, HEX);
      Serial.print(", ");
      Serial.println(board_id, DEC);
      return board_id;
    } else {
      Serial.println("\nInvalid entry, please try again.");
    }
  }
}

