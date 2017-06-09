

//runs once, searches all folders.
void LoadSongs() {
  String data_path = sketchPath() + "\\data\\";

  File data_path_file = new File(data_path);

  File top_level_files[] = data_path_file.listFiles();

  for ( File top_level_file : top_level_files ) {
    if ( top_level_file.isDirectory() ) {
      String folder_name =  top_level_file.getName();
      LoadedFolders.append(folder_name);
      LoadedSongs.add(new StringList() );
      //println( folder_name );
      File contents[] = top_level_file.listFiles();
      for ( File file : contents ) {
        if ( (file.isDirectory() == false) && (file.getName().indexOf(".mp3") >= 0) ) {
          //println( file.getName() ); 
          LoadedSongs.get(LoadedSongs.size() - 1 ).append( file.getName() );
        }
      }
    }
  }

  for ( int i = 0; i < LoadedFolders.size(); ++i ) {
    println( "folder: " + LoadedFolders.get(i) ); 
    println( join( LoadedSongs.get(i).array(), ", " ) );
  }

  backgroundSound = minim.loadFile( "background.mp3" );
  backgroundSound.setGain(-100);
  backgroundSound.loop();
}


//called to change track playback.
void StartSoundFromFolder( int folder_index ) {

  LoadedTrackSet = folder_index;
  println("starting playback from " + LoadedFolders.get(folder_index) );

  if (LoadedSongs.get(folder_index).size() != 4 ) {
    println("error, invalid number of songs found. expected 4 songs, found " + str(LoadedSongs.get(folder_index).size()) );
    return;
  }

  //we probably don't have to manually stop the old players, but I don't know what processing does when we delete the old players.
  if ( players != null ) {
    for (int i = 0; i < players.length; ++i ) {
      if ( players[i] != null && players[i].isPlaying() ) {
        players[i].pause();
      }
    }
  }

  players = new AudioPlayer[4];
  for ( int i = 0; i < 4; ++i ) {
    String file_path = LoadedFolders.get(folder_index) + "\\" + LoadedSongs.get(folder_index).get(i);
    println(file_path);
    players[i] = minim.loadFile( file_path );
    //players[i].mute(); //start muted
    //players[i].setGain(-100.0);
    //println("initial gain: " + str(players[i].getGain() ));
    HardMuteChannel(i);
  }

  //lets play them. I really hope this stays synced:
  for ( int i = 0; i < 4; ++i ) {
    players[i].loop();
  }
}

//use the touch state to decide what tracks to play.
void UpdatePlaybackFromSavedState() {

  ReportSync();


  int touch_bit = 1;

  Boolean is_manual_control = false;
  for ( int i = 0; i < 4; ++i ) {
    if ( ManualInputs[i] == true ) {
      is_manual_control = true;
      break;
    }
  }

  Boolean anything_playing = false;


  if ( is_manual_control ) {
    for ( int i = 0; i < 4; ++i ) {
      println("gain[" + str(i) + "]: " + str(players[i].getGain()) );
      if ( ( ManualInputs[i] == true ) /*&& (players[i].isMuted() == true)*/ ) {
        //players[i].setGain(0);
        PlayChannel(i);
        anything_playing = true;
        println("unmuteing " + str(i) );
      } else if ( ( ManualInputs[i] == false ) /*&& (players[i].isMuted() == false)*/ ) {
        //players[i].mute();
        MuteChannel(i);
        players[i].setGain(-100);
        println("muteing " + str(i) );
      }
    }
  } else {

    for ( int i = 0; i < 4; ++i ) {
      if ( (BoardStates[i] & touch_bit) != 0 ) {
        println("unmuting...");
        //TODO: fade with shiftVolume or shiftGain
        //players[i].unmute();
        //players[i].setGain(0);
        anything_playing = true;
        PlayChannel(i);
      } else {
        //TODO: fade with shiftVolume or shiftGain
        //players[i].mute();
        //players[i].setGain(-100);
        MuteChannel(i);
      }
    }
  }

  if ( (anything_playing == true) && (isBackgroundPlaying==true) ) {
    //stop playing the background track.
    isBackgroundPlaying = false;
    backgroundSound.shiftGain( backgroundSound.getGain(), -100, background_fade_time_ms );
  } else if ( (anything_playing == false) && (isBackgroundPlaying==false) ) {
    //start playing the background track.
    isBackgroundPlaying = true;
    backgroundSound.shiftGain( backgroundSound.getGain(), background_volume_db, background_fade_time_ms ); //volume of background track set here in dB. (-100 = off, 0.0 = normal)
  }
}

void PlayChannel(int channel) {
  players[channel].shiftGain( players[channel].getGain(), 0.0, fade_in_time_ms );
}
void MuteChannel(int channel) {
  players[channel].shiftGain( players[channel].getGain(), -100, fade_out_time_ms );
}

void HardMuteChannel(int channel) {
  players[channel].setGain(-100);
}


void Resync() {
  println("Re-syncing sound...");
  int new_position =  players[0].position();

  for ( int i = 0; i < 4; ++i ) {
    players[i].cue( new_position );
  }
}

void ReportSync() {
  int positions[] = new int[4];

  //do nothing but this for maximum speed.
  for ( int i = 0; i < 4; ++i ) {
    positions[i] = players[i].position();
  }

  int max = positions[0];
  int min = positions[0];
  for ( int i = 0; i < 4; ++i ) {
    if ( positions[i] > max )
      max = positions[i];

    if ( positions[i] < min )
      min = positions[i];
  }

  int delta = max-min;
  float delta_f = delta / 1000.0;

  println("current audio error (s): "+ str(delta_f) );

  //printArray( positions );
}