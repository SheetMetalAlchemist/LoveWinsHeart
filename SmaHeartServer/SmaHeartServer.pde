//import for Open Sound Control
import netP5.*;
import oscP5.*;
import ddf.minim.*;
import hypermedia.net.*;


//Networking
UDP udp; 

//Sound
Minim minim;
AudioPlayer players[];
AudioPlayer backgroundSound;

//OSC
OscP5 oscP5;
NetAddress LedLabIp = new NetAddress("192.168.1.2", 1234);
NetAddress LuminairIp = new NetAddress("192.168.1.4", 8000);


//application
final int NumBoards = 4;
int BoardStates[] = new int[NumBoards];
final int NumTouchSensorsPerBoard = 8;
StringList  LoadedFolders = new StringList();
ArrayList<StringList > LoadedSongs = new ArrayList<StringList>();
int LoadedTrackSet = 0;
Boolean ManualInputs[] = new Boolean[NumBoards];
Boolean isBackgroundPlaying = false;
int Timer = 0;
int DmxSequence = 0;
final int fade_in_time_ms = 300;
final int fade_out_time_ms = 2000;
final int background_fade_time_ms = 1000;
int default_track_set = 2;


//background track volume when nothing is playing.
//0.0 = full volume.
//-100 = off.
//try -10, -20, -30, and -40 to make it quieter. DB is weird.
final float background_volume_db = -10.0;


void setup() {
  size(600, 400);
  pixelDensity(displayDensity()); //this should make scaling work on high DPI screens, but still work normally on normal screens.

  //setup UDP
  InitUdp();

  //setup OSC
  InitOsc();

  //setup sound
  //InitSound();
  //minim = new Minim(this);
  LoadSongs();
  
  //if( default_track_set >= LoadedFolders.size() ) {
  //    default_track_set = 0;
  //}
  //StartSoundFromFolder(default_track_set);

  for ( int i = 0; i < NumBoards; ++i ) {
    BoardStates[i] = 0;
    ManualInputs[i] = false;
  }

  //UpdatePlaybackFromSavedState();
  RemoteUpdatePlaybackFromSavedState();
  

  Timer = millis();
  //exit();
}


/*
Manual Control:
 
 ??
 
 Master reset?
 
 */

void keyPressed() {

  int next_track = LoadedTrackSet;
  if( (key == '+' )|| (key == '=')) {
   println("next folder"); 
   next_track++;
   if( next_track >= LoadedFolders.size() ) {
     next_track = 0; 
   }

   //StartSoundFromFolder(next_track);
   LoadedTrackSet = next_track;
   RemoteUpdatePlaybackFromSavedState();
   return;
  } else if( key == '-' ) {
    println("previous folder");
    next_track--;
    if( next_track < 0 ) {
      next_track = LoadedFolders.size() - 1;
    }
    //StartSoundFromFolder(next_track);
    LoadedTrackSet = next_track;
    RemoteUpdatePlaybackFromSavedState();
    return;
  }

  int key_int = key - '0';

  //println("key: " + key);
  if ( true ) {
    // return;
  }
  if ( key_int == 0 ) {
    //reset stored touch states
    //this will also stop audio playback if no other keys are pressed.
    println("Resetting...");
    ManuallyResetStates();
    //Resync();
    return;
  }
  //filter out all but the numbers 1 to 4.
  if ( key_int <= 0 || key_int > NumBoards ) {
    return;
  }

  //println("keyPressed: " + key);

  if ( ManualInputs[key_int-1] != true ) {
    ManualInputs[key_int-1] = true;
    
    //new keypress, trigger LED Lab
    SendLedLabTrigger();


    //check on the DMX stuff:
    UpdateDmxFromState();

    //now that we've set our override flag, lets update playback.
    //UpdatePlaybackFromSavedState();
    RemoteUpdatePlaybackFromSavedState();
  }
}

void keyReleased() {

  int key_int = key - '0';

  //filter out all but the numbers 1 to 4.
  if ( key_int <= 0 || key_int > NumBoards ) {
    return;
  }

  if ( ManualInputs[key_int-1] != false ) {
    ManualInputs[key_int-1] = false;

    //check on the DMX stuff:
    UpdateDmxFromState();

    //now that we've cleared our override flag, lets update playback.
    //UpdatePlaybackFromSavedState();
    RemoteUpdatePlaybackFromSavedState();
  }
}

void draw()
{
  background(255);
  fill(0);
  textSize(16);
  String display_message = GetStatusMessage();

  int padding = 20;
  text(display_message, padding, padding, width-(padding*2), height-(padding*2));

  //IntervalTimer30s();
}

void IntervalTimer30s() {
  int elapsed_time = millis() - Timer;
  if ( elapsed_time < 30000 ) {
    return;
  }
  Timer = millis();

  for (int i = 0; i < NumBoards; ++i ) {
    if ( ManualInputs[i] == true ) {
      return;
    }
    if ( ( BoardStates[i] & 1 ) != 0 ) {
      return;
    }
  }

  //no input active, lets re-sync the sound sysem!
  println("30 second inactivity watchdog triggered.");
  Resync();
}

String GetStatusMessage() {
  //what track set is selected?
  //what tracks are muted/not muted?
  //what inputs are on/off?
  //system time?
  String msg = "";
  
  //inputs:
  msg += "active touch inputs:";
  for( int i = 0; i < NumBoards; ++ i ) {
    if( (BoardStates[i] & 1 ) != 0 ) {
     msg += " ON"; 
    } else {
      msg += " OFF";
    }
  }
  msg += "\n";
  msg += "manual inputs inputs:";
  for( int i = 0; i < NumBoards; ++ i ) {
    if( ManualInputs[i] == true ) {
     msg += " ON"; 
    } else {
      msg += " OFF";
    }
  }
  msg += "\n";
  msg += "Folder loaded: " + LoadedFolders.get(LoadedTrackSet) + " (" + str(LoadedTrackSet) + ")\n";
  msg += "DMX sequence: " + DmxSequence + "\n";

  return msg;
}