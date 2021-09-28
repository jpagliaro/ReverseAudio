//
//  AVAsset-extensions.swift
//
//  Created by Limit Point LLC on 9/26/21.
//

import Foundation
import AVFoundation
import CoreServices

let kAudioReaderSettings = [
    AVFormatIDKey: Int(kAudioFormatLinearPCM) as AnyObject, // must be kAudioFormatLinearPCM - see AVAssetReaderOutput
    AVLinearPCMBitDepthKey: 16 as AnyObject,
    AVLinearPCMIsBigEndianKey: false as AnyObject,
    AVLinearPCMIsFloatKey: false as AnyObject,
    AVLinearPCMIsNonInterleaved: false as AnyObject]

let kAudioWriterExpectsMediaDataInRealTime = false // due to a problem with Linear PCM video
let kReverseAudioQueue = "com.limit-point.reverse-audio-queue"

extension AVAsset {
    
    func audioReader(outputSettings: [String : Any]?) -> (audioTrack:AVAssetTrack?, audioReader:AVAssetReader?, audioReaderOutput:AVAssetReaderTrackOutput?) {
        
        if let audioTrack = self.tracks(withMediaType: .audio).first {
            if let audioReader = try? AVAssetReader(asset: self)  {
                let audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
                return (audioTrack, audioReader, audioReaderOutput)
            }
        }
        
        return (nil, nil, nil)
    }
    
    func reverseAudio(destinationURL:URL, progress: @escaping (Float) -> (), completion: @escaping (Bool, String?) -> ())  {
        
        do {
                // AVAssetWriter will not write over an existing file.
            try FileManager.default.removeItem(at: destinationURL)
        } catch _ {}
        
            // this outputs the reversed audio file to url
        guard let assetWriter = try? AVAssetWriter(outputURL: destinationURL, fileType: AVFileType.wav) else {
            completion(false, "Can't create asset writer.")
            return
        }
        
            // MARK: SETUP READER
        
            // AVAssetReaderTrackOutput can only produce uncompressed output.  For audio output settings, this means that AVFormatIDKey must be kAudioFormatLinearPCM in kAudioReaderSettings
        let (_, reader, readerOutput) = self.audioReader(outputSettings: kAudioReaderSettings)
        
        guard let audioReader = reader,
              let audioReaderOutput = readerOutput
        else {
            completion(false, "Can't create audio reader.")
            return
        }
        
        if audioReader.canAdd(audioReaderOutput) {
            audioReader.add(audioReaderOutput)
        }
        else {
            completion(false, "Can't add audio reader.")
            return
        }
        
            // MARK: READ decompressed SAMPLES
        
        var audioSamples:[CMSampleBuffer] = []
        var timingInfos:[CMSampleTimingInfo] = []
        
        var invalidTimingCount = false
        
        if audioReader.startReading() {
            
            while audioReader.status == .reading {
                
                autoreleasepool { () -> Void in
                    
                    if let sampleBuffer = audioReaderOutput.copyNextSampleBuffer() {
                        
                        var timingInfoCount: CMItemCount = 0
                        CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: 0, arrayToFill: nil, entriesNeededOut: &timingInfoCount)
                        
                        if timingInfoCount != 1 {
                            audioReader.cancelReading()
                            invalidTimingCount = true
                            return
                        }
                        
                        var timingInfo = CMSampleTimingInfo()
                        CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: 0, arrayToFill: &timingInfo, entriesNeededOut: &timingInfoCount)
                        
                        let presentationTime = timingInfo.presentationTimeStamp
                        let duration = CMSampleBufferGetDuration(sampleBuffer)
                        
                        let endTime = CMTimeAdd(presentationTime, duration)
                        let newPresentationTime = CMTimeSubtract(self.duration, endTime)
                        timingInfo.presentationTimeStamp = newPresentationTime
                        
                        timingInfos.append(timingInfo)
                        
                        audioSamples.append(sampleBuffer)
                    }
                    else {
                        audioReader.cancelReading() // Seems to be okay to call cancelReading even if reader is done. 
                    }
                }
            }
        }
        
        if invalidTimingCount {
            completion(false, "Unexpected timing info.")
            return
        }
        
            // MARK: SETUP WRITER
        
            // create 'audioCompressionSettings' using an uncompressed sample buffer
            // Using the format desriptor form the track doesn't work, I think because the track has compressed data
        let sampleBuffer = audioSamples[0]
        
        let sourceFormat = CMSampleBufferGetFormatDescription(sampleBuffer)
        
        let audioCompressionSettings = [AVFormatIDKey: kAudioFormatLinearPCM] as [String : Any]
        
        if assetWriter.canApply(outputSettings: audioCompressionSettings, forMediaType: AVMediaType.audio) == false {
            completion(false, "Can't apply compression settings to asset writer.")
            return
        }
        
            // Note - sourceFormatHint is required also for 'passthrough' - which is when outputSettings is nil
        let audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings:audioCompressionSettings, sourceFormatHint: sourceFormat)
        
            // This is often cause for issues: true or false?
        audioWriterInput.expectsMediaDataInRealTime = kAudioWriterExpectsMediaDataInRealTime
        
        if assetWriter.canAdd(audioWriterInput) {
            assetWriter.add(audioWriterInput)
            
        } else {
            completion(false, "Can't add audio input to asset writer.")
            return
        }
        
            // MARK: WRITE SAMPLES
        
        let serialQueue: DispatchQueue = DispatchQueue(label: kReverseAudioQueue)
        
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: CMTime.zero)
        
        var progressValue:Float = 0
        let nbrSamples = audioSamples.count
        
        var index = 0
        
        func finishWriting() {
            assetWriter.finishWriting {
                switch assetWriter.status {
                    case .failed:
                        
                        var errorMessage = ""
                        if let error = assetWriter.error {
                            
                            let nserr = error as NSError
                            
                            let description = nserr.localizedDescription
                            errorMessage = description
                            
                            if let failureReason = nserr.localizedFailureReason {
                                print("error = \(failureReason)")
                                errorMessage += ("Reason " + failureReason)
                            }
                        }
                        completion(false, errorMessage)
                        return
                    case .completed:
                        completion(true, nil)
                        return
                    default:
                        completion(false, nil)
                        return
                }
            }
        }
        
        audioWriterInput.requestMediaDataWhenReady(on: serialQueue) {
            
            while audioWriterInput.isReadyForMoreMediaData, index < nbrSamples {
                
                progressValue = Float(index)/Float(nbrSamples)
                
                print("progress = \(progressValue)")
                progress(progressValue)
                
                let sampleBuffer = audioSamples[nbrSamples - 1 - index]
                
                let timingInfo = timingInfos[index]
                
                if let reversedBuffer = sampleBuffer.reverse(timingInfo: [timingInfo]), audioWriterInput.append(reversedBuffer) == true {
                    index += 1
                }
                else {
                    index = nbrSamples
                }
                
                if index == nbrSamples {
                    audioWriterInput.markAsFinished()
                    
                    finishWriting()
                }
            }
        }
    }
}
