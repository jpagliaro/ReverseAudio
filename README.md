# ReverseAudio

The user interface is multiplatform (macOS, iOS) SwiftUI.

Reverses audio and then reverses the reversed audio. The audio files reversed are in the app bundle, named:

"I'm Afraid I Can't Do That"
"Piano"

The method that reverses audio is an extension of AVAsset:

func reverseAudio(destinationURL:URL, progress: @escaping (Float) -> (), completion: @escaping (Bool, String?) -> ())

reverseAudio makes use of a key method that is an extension on CMSampleBuffer:

func reverse(timingInfo:[CMSampleTimingInfo]) -> CMSampleBuffer?

ReverseAudioObservable is an ObservableObject that performs the required tasks:

Plays and reverses the the audio files in response to buttons in the main view. 

The files generated are placed in the app's Documents folder.

The app writes uncompressed audio, saving them to .wav files.
