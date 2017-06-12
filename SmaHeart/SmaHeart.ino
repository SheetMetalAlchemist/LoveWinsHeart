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

//button stuff:
#define BUTTON_PIN  5



void setup() {
  Serial.begin(115200);


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

  //InitCapSense();

  //init button:
  pinMode(BUTTON_PIN, INPUT_PULLUP);

  //LED stuff:
  strip.begin();
  strip.show(); // Initialize all pixels to 'off'
}



void InitCapSense()
{

  //captouch stuff:
  if (!cap.begin()) {
    Serial.println("CAP1188 not found");
    while (1);
  }
  Serial.println("CAP1188 found!");
  //delay(1000);
  cap.writeRegister( 0x00, 0 << 6 ); // set gain to 1 (default 0)

  cap.writeRegister(0x1F, 0x0F); //sensitivty = 7F least sensitive, 1F most sensitive, 3F default;
  cap.writeRegister(CAP1188_STANDBYCFG, 0x70); //number of samples averaged 0x30 = 8 = default, 0x70 = 128

  //input enable
  cap.writeRegister( 0x21, 0x01 ); //disable all inputs but #1

  cap.writeRegister( 0x26, 0x01 ); //init recal on input 1.
  delay(600); //wait for call to finish, 600 ms?

}

void loop() {

  //Serial.println("loop");
  //ProcessTouches();
  //DebugPrintCapSense();
  ProcessButton();
  delay(5);
}

void ProcessButton()
{
  bool activated = digitalRead(BUTTON_PIN) == LOW; //internal pull-up reads high when not-active.
  //Serial.print("state: ");
  //Serial.println(activated);
  byte new_state = 0;
  if( activated == true ) {
    new_state = 1;
  }
  if( !initial_state_sent ) {
    initial_state_sent = true;
    HandleStateChanged(new_state);
    last_state = new_state;
    return;
  }

  if( new_state != last_state ) {

    HandleStateChanged(new_state);
  }
  last_state = new_state;
}

void ProcessTouches()
{
  byte touched = cap.touched();

  if ( initial_state_sent == false ) {
    initial_state_sent = true;
    HandleStateChanged( touched );
  } else {
    if ( touched != last_state ) {
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
  return;

  //LED opperations
  for (int i = 0; i < 8; ++i ) {
    if ( state & (1 << i)) {
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
  //Serial.println("finished sending packet");
}


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

void DebugPrintCapSense()
{
  byte sensor_1_input_delta_count = cap.readRegister( 0x10 );
  byte sensor_8_input_delta_count = cap.readRegister( 0x17 );

  byte sensor_1_input_delta_count_threshold = cap.readRegister( 0x30 );
  byte sensor_8_input_delta_count_threshold = cap.readRegister( 0x37 );

  byte sensor_imput_noise_threshold = cap.readRegister( 0x38 );

  byte sensor_1_base_count = cap.readRegister( 0x50 );
  byte sensor_8_base_count = cap.readRegister( 0x57 );

  byte sensor_1_input_cal = cap.readRegister( 0xB1 );
  byte sensor_8_input_cal = cap.readRegister( 0xB8 );

  byte sensors_1_to_4_lsb_cal = cap.readRegister( 0xB9 );
  byte sensors_5_to_8_lsb_cal = cap.readRegister( 0xBA );

  byte touched = cap.touched();

  Serial.print("\n\n");
  Serial.print("touched: ");
  Serial.println(touched, BIN);
  Serial.print("sensor_1_input_delta_count ");
  Serial.println( sensor_1_input_delta_count, HEX );
  Serial.print("sensor_8_input_delta_count ");
  Serial.println( sensor_8_input_delta_count, HEX );

  Serial.print("sensor_1_input_delta_count_threshold ");
  Serial.println( sensor_1_input_delta_count_threshold, HEX );
  Serial.print("sensor_8_input_delta_count_threshold ");
  Serial.println( sensor_8_input_delta_count_threshold, HEX );

  Serial.print("sensor_imput_noise_threshold ");
  Serial.println( sensor_imput_noise_threshold, HEX );


  Serial.print("sensor_1_base_count ");
  Serial.println( sensor_1_base_count, HEX );
  Serial.print("sensor_8_base_count ");
  Serial.println( sensor_8_base_count, HEX );

  Serial.print("sensor_1_input_cal ");
  Serial.println( sensor_1_input_cal, HEX );
  Serial.print("sensor_8_input_cal ");
  Serial.println( sensor_8_input_cal, HEX );

  Serial.print("sensors_1_to_4_lsb_cal ");
  Serial.println( sensors_1_to_4_lsb_cal, HEX );
  Serial.print("sensors_5_to_8_lsb_cal ");
  Serial.println( sensors_5_to_8_lsb_cal, HEX );


  //ProcessTouches();

}

