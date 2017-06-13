using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows;
using NAudio.Wave;
using NAudio.Wave.SampleProviders;
using System.Windows.Input;

//this code was taken from here and lightly modified:
//http://mark-dot-net.blogspot.com/2014/12/mixing-and-looping-with-naudio.html
//thanks so much for this!


namespace SmaAudioPlayer
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        List<WavePlayer> Clips = new List<WavePlayer>();
        WavePlayer BackgroundClip;

        string[] directories;
        string[] files;
        string background_path;
        private IWavePlayer audioOutput;
        int FolderSet = 0;
        UdpListener Listener;

        Dictionary<Key, bool> ControlKeys = new Dictionary<Key, bool>() { { Key.D1, false }, { Key.D2, false }, { Key.D3, false }, { Key.D4, false } };
        bool[] NetworkState = new bool[ 4 ] { false, false, false, false };

        public MainWindow()
        {
            InitializeComponent();




        }

        private void Window_Loaded( object sender, RoutedEventArgs e )
        {
            string exe_path = Environment.CurrentDirectory;
            if( exe_path.Contains( "LoveWinsHeart" ) == false )
                throw new Exception( "unable to self locate audio files" );
            string audio_data_folder = exe_path.Substring( 0, exe_path.IndexOf( "LoveWinsHeart" ) + "LoveWinsHeart".Length );
            audio_data_folder += "\\SmaHeartServer\\data";

            directories = System.IO.Directory.GetDirectories( audio_data_folder );
            background_path = audio_data_folder + "\\background.mp3";

            audioOutput = new WaveOut();


            Listener = new UdpListener();
            Listener.NewMessageReceived += Listener_NewMessageReceived;
            Listener.StartListener( 30 );
            //play?
            PlayFolderSet( directories[ FolderSet ] );

        }

        private void Listener_NewMessageReceived( object sender, MyMessageArgs e )
        {
            if( e.data.Length != 5 )
            {
                Console.WriteLine( "invalid packet received!" );
                return;
            }

            int[] data = e.data.Select( x => int.Parse( new string( ( char )x, 1 ) ) ).ToArray();

            int new_track_set = data[ 0 ];

            if( new_track_set != FolderSet )
            {
                FolderSet = new_track_set;
                PlayFolderSet( directories[ FolderSet ] );
            }


            for( int i = 0; i < 4; ++i  )
            { 
                NetworkState[ i ] = data[ i + 1 ] == 1 ? true : false;
            }
            UpdatePlaybackFromState();

            Console.WriteLine( String.Join( " ", e.data.Select( x => ( char )x ) ) );
        }

        private void PlayFolderSet( string folder )
        {
            Console.WriteLine( "starting to play fodler " + folder );
            files = System.IO.Directory.GetFiles( folder );

            if( audioOutput != null )
            {
                audioOutput.Stop();
                foreach( WavePlayer clip in Clips )
                {
                    clip.Dispose();
                }
                if( BackgroundClip  != null)
                BackgroundClip.Dispose();
                BackgroundClip = null;
                Clips.Clear();
                audioOutput.Dispose();
                audioOutput = new WaveOut();
            }

            foreach( string file in files )
            {
                Clips.Add( new WavePlayer( file, true ) { FadeInTime = 300, FadeOutTime = 1000 } );
            }
            BackgroundClip = new WavePlayer( background_path, false ) { FadeInTime = 1000, FadeOutTime = 1000 };
            var mixer = new MixingSampleProvider( Clips.Select( c => c.Fader ) );
            mixer.AddMixerInput( BackgroundClip.Fader );

            audioOutput.Init( mixer );
            //audioOutput.Volume = 0.25f;
            audioOutput.Play();

            UpdatePlaybackFromState();

        }


        private void UpdatePlaybackFromState()
        {
            //check manual overrides first:
            if( ControlKeys.Any( x => x.Value == true))
            {
                Clips[ 0 ].FadeState = ControlKeys[ Key.D1 ];
                Clips[ 1 ].FadeState = ControlKeys[ Key.D2 ];
                Clips[ 2 ].FadeState = ControlKeys[ Key.D3 ];
                Clips[ 3 ].FadeState = ControlKeys[ Key.D4 ];
            }
            else
            {
                for( int i = 0; i < 4; ++i )
                    Clips[ i ].FadeState = NetworkState[ i ];
            }

            if( Clips.Any( x => x.FadeState == true ) )
                BackgroundClip.FadeState = false;
            else
                BackgroundClip.FadeState = true;


        }


        


        private void Window_KeyDown( object sender, System.Windows.Input.KeyEventArgs e )
        {
            if( ControlKeys.ContainsKey( e.Key )  )
            {
                ControlKeys[ e.Key ] = true;
                UpdatePlaybackFromState();


            }
            else if( e.Key == Key.Add || e.Key == Key.OemPlus)
            {
                FolderSet++;
                if( FolderSet >= directories.Count() )
                    FolderSet = 0;

                PlayFolderSet( directories[ FolderSet ] );
            }
            else if( e.Key == Key.Subtract || e.Key == Key.OemMinus )
            {
                FolderSet--;
                if( FolderSet < 0 )
                    FolderSet = directories.Count() - 1;

                PlayFolderSet( directories[ FolderSet ] );
            }
            else
            {
               // Console.WriteLine( "key pressed: " + e.Key.ToString() );

            }

            
        }

        private void Window_KeyUp( object sender, System.Windows.Input.KeyEventArgs e )
        {
            if( ControlKeys.ContainsKey( e.Key ) )
            {
                ControlKeys[ e.Key ] = false;
                UpdatePlaybackFromState();
            }
        }



        /*
        private void PlayButton_Click(object sender, RoutedEventArgs e)
        {
            if (PlayButton.Content.ToString() == "Play")
            {
                if (played)
                {
                    foreach (WavePlayer clip in Clips)
                    {
                        clip.Dispose();
                    }
                    Clips.Clear();
                    System.Console.WriteLine( "volume: " + audioOutput.Volume.ToString() );
                    audioOutput.Dispose();
                    audioOutput = new DirectSoundOut();
                    
                }

                
                foreach (string file in files)
                {
                    Clips.Add(new WavePlayer( file ) );                    
                }
               // var mixer = new MixingWaveProvider32(Clips.Select(c => c.Channel));
                var mixer = new MixingSampleProvider( Clips.Select( c => c.Fader ) );
                audioOutput.Init(mixer);
                

                PlayButton.Content = "Stop";
                played = true;

                
                audioOutput.Play();
                
                SetBeatVolume();
                SetBassVolume();
                SetGuitarVolume();
                SetPianoVolume();

            }
            else
            {
                audioOutput.Stop();
                PlayButton.Content = "Play";
            }

        }
        */


        /*
private void PianoCheckBox_Checked(object sender, RoutedEventArgs e)
{
FadeIn( 0 );
if( Clips.Count > 0 )
PianoSlider.Value = 100;

}

private void PianoCheckBox_Unchecked(object sender, RoutedEventArgs e)
{
FadeOut( 0 );
if( Clips.Count > 0 )
PianoSlider.Value = 0;

}

private void BeatCheckBox_Checked(object sender, RoutedEventArgs e)
{
FadeIn( 1 );
if (Clips.Count > 0)
BeatSlider.Value = 100;
}

private void BeatCheckBox_Unchecked(object sender, RoutedEventArgs e)
{
FadeOut( 1 );
if (Clips.Count > 0)
BeatSlider.Value = 0;
}

private void BassCheckBox_Checked(object sender, RoutedEventArgs e)
{
FadeIn( 2 );
if (Clips.Count > 0)
BassSlider.Value = 100;
}

private void BassCheckBox_Unchecked(object sender, RoutedEventArgs e)
{
FadeOut( 2 );
if (Clips.Count > 0)
BassSlider.Value = 0;
}

private void AcousticCheckBox_Checked(object sender, RoutedEventArgs e)
{
FadeIn( 3 );
if (Clips.Count > 0)
GuitarSlider.Value = 100;

}

private void AcousticCheckBox_Unchecked(object sender, RoutedEventArgs e)
{
FadeOut( 3 );
if (Clips.Count > 0)
GuitarSlider.Value = 0;
}

private void BeatSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
{
if (Clips.Count > 0)
{
SetBeatVolume();
}
}

void SetBeatVolume()
{
if( IsVolumeFixed )
{
Clips[ 0 ].Channel.Volume = FixedVolume;
return;
}

Clips[0].Channel.Volume = (float)BeatSlider.Value / 100.0f;
BeatCheckBox.IsChecked = (Clips[0].Channel.Volume > 0f);
}

private void BassSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
{
if (Clips.Count > 0)
{
SetBassVolume();
}
}

void SetBassVolume()
{
if( IsVolumeFixed )
{
Clips[ 2 ].Channel.Volume = FixedVolume;
return;
}
Clips[2].Channel.Volume = (float)BassSlider.Value / 100.0f;
BassCheckBox.IsChecked = (Clips[2].Channel.Volume > 0f);
}

private void PianoSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
{
if (Clips.Count > 0)
{
SetPianoVolume();
}
}

void SetPianoVolume()
{
if( IsVolumeFixed )
{
Clips[ 1 ].Channel.Volume = FixedVolume;
return;
}
Clips[1].Channel.Volume = (float)PianoSlider.Value / 100.0f;
PianoCheckBox.IsChecked = (Clips[1].Channel.Volume > 0f);
}

private void GuitarSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
{
if (Clips.Count > 0)
{
SetGuitarVolume();
}
}

void SetGuitarVolume()
{
if( IsVolumeFixed )
{
Clips[ 3 ].Channel.Volume = FixedVolume;
return;
}
Clips[3].Channel.Volume = (float)GuitarSlider.Value / 100.0f;
AcousticCheckBox.IsChecked = (Clips[3].Channel.Volume > 0f);
}*/
    }


    public class WavePlayer
    {
        WaveFileReader WavReader;
        Mp3FileReader Mp3Reader;
        public WaveChannel32 Channel { get; set; }
        public FadeInOutSampleProvider Fader {  get; set; }

        public int FadeInTime { get; set; }
        public int FadeOutTime { get; set; }

        //true means playing
        public bool FadeState
        {
            get
            {
                return _FadeState;
            }
            set
            {
                if( value != _FadeState )
                {
                    if( value )
                        Fader.BeginFadeIn( FadeInTime );
                    else
                        Fader.BeginFadeOut( FadeOutTime );
                    _FadeState = value;
                }
            }
        }
        private bool _FadeState;

        string FileName { get; set; }

        public WavePlayer (string FileName, bool initiallySilent = false )
        {
            this._FadeState = !initiallySilent;

            this.FileName = FileName;
            
            LoopStream loop;
            if( this.FileName.ToLower().EndsWith("mp3") )
            {
                Mp3Reader = new Mp3FileReader( FileName );
                loop = new LoopStream( Mp3Reader );
            }
            else if( this.FileName.ToLower().EndsWith( "wav" ) )
            {
                WavReader = new WaveFileReader( FileName );
                loop = new LoopStream( WavReader );
            }
            else
            {
                throw new System.Exception( "invalid audio file format" );
            }
            //Reader = new WaveFileReader(FileName);
            Channel = new WaveChannel32(loop) { PadWithZeroes = false };
            Fader = new FadeInOutSampleProvider( loop.ToSampleProvider(), initiallySilent );
            
        }

        public void Dispose()
        {
            if (Channel != null)
            {
                Channel.Dispose();
                if( Mp3Reader != null)
                    Mp3Reader.Dispose();
                if( WavReader != null )
                    WavReader.Dispose();
            }
        }

    }

    /// <summary>
    /// Stream for looping playback
    /// </summary>
    public class LoopStream : WaveStream
    {
        WaveStream sourceStream;

        /// <summary>
        /// Creates a new Loop stream
        /// </summary>
        /// <param name="sourceStream">The stream to read from. Note: the Read method of this stream should return 0 when it reaches the end
        /// or else we will not loop to the start again.</param>
        public LoopStream(WaveStream sourceStream)
        {
            this.sourceStream = sourceStream;
            this.EnableLooping = true;
        }

        /// <summary>
        /// Use this to turn looping on or off
        /// </summary>
        public bool EnableLooping { get; set; }

        /// <summary>
        /// Return source stream's wave format
        /// </summary>
        public override WaveFormat WaveFormat
        {
            get { return sourceStream.WaveFormat; }
        }

        /// <summary>
        /// LoopStream simply returns
        /// </summary>
        public override long Length
        {
            get { return sourceStream.Length; }
        }

        /// <summary>
        /// LoopStream simply passes on positioning to source stream
        /// </summary>
        public override long Position
        {
            get { return sourceStream.Position; }
            set { sourceStream.Position = value; }
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            int totalBytesRead = 0;

            while (totalBytesRead < count)
            {
                int bytesRead = sourceStream.Read(buffer, offset + totalBytesRead, count - totalBytesRead);
                if (bytesRead == 0)
                {
                    if (sourceStream.Position == 0 || !EnableLooping)
                    {
                        // something wrong with the source stream
                        break;
                    }
                    // loop
                    sourceStream.Position = 0;
                }
                totalBytesRead += bytesRead;
            }
            return totalBytesRead;
        }
    }
}
