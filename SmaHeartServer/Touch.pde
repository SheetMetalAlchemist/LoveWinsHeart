

void InitUdp() {
  udp = new UDP( this, 8888 );  // create a new datagram connection on port 6000
  //udp.log( true );     // <-- printout the connection activity
  udp.listen( true );           // and wait for incoming message
}

void ManuallyResetStates() {
  for ( int i = 0; i < NumBoards; ++i ) {
    BoardStates[i] = 0;
  }
  //UpdatePlaybackFromSavedState();
  RemoteUpdatePlaybackFromSavedState();
}


void HandleStateChange( int state, int board_id ) {

  board_id--; //the board ID comes in 1 to 4, we convert to 0 to 3.
  if ( board_id >= NumBoards ) {
    println("board ID out of range");
    return;
  }

  //detect touch, any device, to trigger LED Lab.
  if ( ((BoardStates[board_id] & 1) == 0 ) &&  ((state & 1) != 0 ) ) {
    println("generic hit trigger!");
    //SendLedLabTrigger();
  }

  //update the saved states.
  BoardStates[board_id] = state;

  //this handles counting the active states and setting the correct DMX sequence.
  UpdateDmxFromState();

  //call over to the Sound File.
  //UpdatePlaybackFromSavedState();
  RemoteUpdatePlaybackFromSavedState();
}

void UpdateDmxFromState() {
  int SensorTouchCounts[] = new int[NumTouchSensorsPerBoard];

  int touch_count = 0;
  for ( int i = 0; i < 4; ++i ) {
    if ( ManualInputs[i] == true ) {
      touch_count++;
    }
  }

  if ( touch_count == 0 ) {
    for (int i = 0; i < NumBoards; ++i ) {
      if ( (BoardStates[i] & 1) != 0 ) {
        touch_count++;
      }
    }
  }

  if( DmxSequence != touch_count ) {
    DmxSequence = touch_count;
    SelectDmxSequence( DmxSequence );
    SelectLedLabScene( DmxSequence );
  }

  println("input has " + str( touch_count ) + " activations");
}


void receive( byte[] data ) {       // <-- default handler
  //void receive( byte[] data, String ip, int port ) {  // <-- extended handler

  String msg = new String(data);
  //message format: "board:%i,state:%i\n"
  String key_1 = "board:";
  String key_2 = ",state:";
  String key_3 = "\n";

  int index_1 = msg.indexOf(key_1);
  int index_2 = msg.indexOf(key_2);
  int index_3 = msg.indexOf(key_3);

  if ( index_1 < 0 || index_2 < 0 || index_3 < 0 ) {
    println("message parsing error: " + msg);
  }

  int board_id = int( msg.substring( index_1+key_1.length(), index_2 ) );
  int state = int( msg.substring( index_2+key_2.length(), index_3 ) );

  HandleStateChange( state, board_id );
  //println("board id: " + str(board_id) );
  //println("state: " + str(state) );
  return;
}