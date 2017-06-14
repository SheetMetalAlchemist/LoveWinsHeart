# Sheet Metal Alchemist Love Wins Heart


## Processing Setup

Load the processing file SmaHeartServer.pde.

Set the IP address of the iPad running LED Lab into the `LedLabIp` global variable.
Set the IP address of the iPad running Luminair into the `LuminairIp` global variable.

In the data folder, place 1 folder for each set of 4 tracks to be played.

In the data folder. place a single file titled "background.mp3" to be used as the background track.

Set the static IP of the server to the same value set in the Arduinos, `192.168.1.109`

In LED Lab, go to the External Control Setup screen, and set Scene invocation to OSC, and set the address to `/scene`. 

If we decide to go back to using OSC packets for the trigger, then in LED Lab, set the active scene to trigger from OSC, and set the single address to `/trigger`. This isn't actually in use right now.

In Luminair, open the settings, scroll down to "remote control", and select OSC input. Enable this, with the default port 8000.

In Luminair, make sure there are 5 different sequences to choose between. The app will use sequences 1 to 5.

Start the software. You should see the status printed to the application screen.

Keys:

'+'     advances to the next set of tracks.
'-'     goes to the previous set of tracks.
'1', '2', '3', '4'      manually triggers the 4 inputs, respectively.
'0'     clears the state of the 4 inputs (in case something got stuck on.) Also re-syncs the audio tracks.


Operation:
when any manual input is active, the hardware inputs are disabled.

the DMX sequence changes whenever the number of active inputs (either hardware or manual) changes.
Sequence 0 is activated every time the last input is released.
Sequence 1 is activate when the first touch sensor is activated.
Sequence 2 is activated when 2 touch sensors are engaged at the same time.
So on for sequences 3 and 4.

The LED Lab scene selection changes the same way that the DMX (Luminair) sequence changes.

**On this branch, the Processing app does not produce sound**

The default set of tracks loaded is set to the 3rd folder (2, in a zero based indexing system). If fewer than 3 folders are present, it will default to the first folder. This can be changed with the `default_track_set` variable.

## Setting up external sound program (required for this branch, `alternate-audio-playback`)

#### Install Visual Studio 2017 (done once)

Install visual studio 2017 community edition.

During the install process, be sure to check ".NET desktop development" It's on the first screen of the installer.

#### Running SmaAudioPlayer

Open the SmaAudioPlayer folder and open the SmaAudioPlayer solution file, SmaAudioPlayer.sln.

Press run.

A black window should appear that says "loading..." that will never change - I never added debug stuff.

This app has it's own manual control, AND it works with the manual control from the processing app. Press & hold keys 1-4 as usual, and press +/- to change folder sets. It should just work. Make sure that the window is selected when you do this.

Fire up the processing app if it's not already running. the processing app no longer makes any sound at all - instead it forwards sound control to the new app. test out the manual control there. Make sure the processing window is selected when you do this.

Turn on Arduinos, make sure LED Lab and Luminair are good to go. Test everything.

Test out closing everything and switching to the master branch. Or, better yet, have both branches on your computer in different folders, at the same time. Make sure you can close everything and switch to the original, and then switch back.


#### Troubleshooting SmaAudioPlayer

**Note:** when SmaAudioPlayer has the focus, the keyboard will control sound, but that's it. When the processing app has the focus, the keyboard controls everything (sound, LED Lab, Luminar)


If it crashes, it could be having trouble locating the audio files - it assumes you checked out the whole repo, and it goes looking for the audio files in the processing project's data directory.

If anything goes wrong, close visual studio and processing, and checkout the `master` branch. Re-open processing and precede with the original audio quality.


## LED Lab troubleshooting:

If Scene selection isn't working in LED Lab, do the following:

1. check the IP address - does it match the one in the processing sketch?
2. Restart LED Lab
3. In LED Lab,go to the External Control Setup screen, and set Scene invocation to OSC, and set the address to `/scene`.

## Hardware notes:

Connect Ethernet first, then power. If the Arduino turns on before Ethernet is connected, you will need to restart the Arduino.

If the button feels stuck and is not clicking properly, it is probably being pushed up against the bottom plate inside of the enclosure. 

Button Connections: Connect 1 pin on the button to pin 5, and the other pin to ground. You can swap these two.

use the center tab of the 3 tabs on the arcade button, and the tab at the end of the button. It's the tab that's mounded on the back instead of the side.


## Replacing parts:

**Ethernet Shield:** Just swap these out, nothing to worry about. The one that already failed has a black X on the RJ-45 jack.

**Arduino:** This is a little more of a pain. Each Arduino has a number stored in memory - it's not in the code, it's in the storage on the chip. The Arduinos in use are numbered 1 to 4. A sticker on the back of each Arduino shows the number.

The extra board is number 5. The software by default will ignore it. To make it work, you need to make 1 change in the processing software, near the top of SmaHeartServer.

First, look at the back of the Arduino you are removing. It should have a number 1 to 4. Then, find this line in the code:

`final int ReplacementBoardId = -1;`

If you are replacing, say, board #3, replace `-1` with `3`.

Run the program. Board #5 should now act like board #3.

Be sure to connect the button as mentioned in the hardware notes, to pins 5 and ground.

