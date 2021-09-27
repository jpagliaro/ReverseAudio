# ReverseAudio

<img width="912" alt="Sceenshot" src="https://user-images.githubusercontent.com/4062059/134825588-18043a7d-6b46-4b19-94cd-fa19433fed2f.png">

The user interface is multiplatform (macOS, iOS) SwiftUI.

Reverses audio and then reverses the reversed audio. The audio files reversed are in the app bundle, named:

"I'm Afraid I Can't Do That" and 
"Piano"

The method that reverses audio is an extension of AVAsset:

<i>func reverseAudio(destinationURL:URL, progress: @escaping (Float) -> (), completion: @escaping (Bool, String?) -> ())</i>

reverseAudio makes use of a key method that is an extension on CMSampleBuffer:

<i>func reverse(timingInfo:[CMSampleTimingInfo]) -> CMSampleBuffer?</i>

ReverseAudioObservable is an ObservableObject that performs the required tasks:

Plays and reverses the the audio files in response to buttons in the main view. 

The files generated are placed in the app's Documents folder.

The app writes uncompressed audio, saving them to .wav files.

Main Window has three parts:

1 - Two buttons to <b>reverse</b> the two audio files in the app bundle.

2 - Two buttons to <b>play</b> the two audio files in the app bundle.

3 - Two buttons to <b>play</b> the reversed and reverse of the reversed audio files.

Note that the reversed reversed audio should sound like the original audio, as an inverse operation. 
