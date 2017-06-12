

void InitOsc() {
  //listening port doesn't matter, we're not accepting OSC commands, just sending them
  oscP5 = new OscP5(this, 12000);
}

//zero indicates the first scene, which is "1" in the app.
void SelectLedLabScene(int scene ) {
  /*if( scene < 0 )
   scene = 0;
   if( scene > 4 )
   scene = 4;*/

  OscMessage myMessage = new OscMessage("/scene");
  myMessage.add(scene);
  oscP5.send(myMessage, LedLabIp); 
  println("LED Lab Scene Selected: " + str(scene));
}

void SendLedLabTrigger( ) {
  float value = random(1);

  OscMessage myMessage = new OscMessage("/trigger");
  myMessage.add(value);
  oscP5.send(myMessage, LedLabIp); 
  println("LED Lab trigger sent: " + str(value));
}

void SelectDmxScene( int scene ) {
  /*if( scene < 0 )
   scene = 0;
   if( scene > 4 )
   scene = 4;*/
  OscMessage myMessage = new OscMessage("/scenes/" + str(scene));
  myMessage.add(1); 
  oscP5.send(myMessage, LuminairIp); 
  println("Luminair Scene Selected: " + str(scene));
}

void SelectDmxSequence( int sequence ) {
  sequence++; //no sequence 0
  OscMessage myMessage = new OscMessage("/sequences/" + str(sequence) + "/activate");
  myMessage.add(1); 
  oscP5.send(myMessage, LuminairIp); 
  println("Luminair Sequence Selected: " + str(sequence));
}


/*
void Play( int track ) {
 if ( !players[track].isPlaying() ) {
 players[track].play();
 }
 
 SelectDmxScene(track+2);
 SelectLedLabScene(track);
 }
 
 void Stop(int track) {
 if ( players[track].isPlaying() ) {
 players[track].pause();
 }
 
 SelectDmxScene(1);
 SelectLedLabScene(0);
 }
 */