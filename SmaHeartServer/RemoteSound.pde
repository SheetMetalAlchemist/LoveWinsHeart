Boolean[] RemoteStates = new Boolean[]{false, false, false, false};
int RemoteTrack = 0;

void RemoteUpdatePlaybackFromSavedState()
{
  
  Boolean[] new_states = new Boolean[4];
  
  int touch_bit = 1;
  
  Boolean anything_playing = false;

  Boolean is_manual_control = false;
  for ( int i = 0; i < 4; ++i ) {
    if ( ManualInputs[i] == true ) {
      is_manual_control = true;
      new_states[i] = true;
      anything_playing = true;
    }
    else
    {
     new_states[i] = false; 
    }
  }
  
  if( is_manual_control == false ) {
    for ( int i = 0; i < 4; ++i ) {
      if ( (BoardStates[i] & touch_bit) != 0 ) {
        new_states[i] = true;
        anything_playing = true;
      }
    }
  }
  
  
  //any action required?
  Boolean update_required = false;
  for ( int i = 0; i < 4; ++i ) {
   if(  new_states[i] != RemoteStates[i] ) {
     update_required = true;
     RemoteStates[i] = new_states[i];
   }
  }
  
  if( LoadedTrackSet != RemoteTrack ) {
    update_required = true;
  }

  if( update_required ) {
    String message = str(LoadedTrackSet);
    for ( int i = 0; i < 4; ++i ) {
      message += new_states[i] == true ? "1" : "0";
    }
    
    RemoteTrack = LoadedTrackSet;
    udp.send( message, "127.0.0.1", 2003 );
  }
  
}