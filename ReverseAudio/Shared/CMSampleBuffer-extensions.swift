//
//  CMSampleBuffer-extensions.swift
//  ReverseAudio
//
//  Created by Limit Point LLC on 9/26/21.
//

import Foundation
import AVFoundation

extension CMSampleBuffer {
    
    func reverse(timingInfo:[CMSampleTimingInfo]) -> CMSampleBuffer? {
        
        var blockBuffer: CMBlockBuffer? = nil
        let audioBufferList: UnsafeMutableAudioBufferListPointer = AudioBufferList.allocate(maximumBuffers: 1)
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            self,
            bufferListSizeNeededOut: nil,
            bufferListOut: audioBufferList.unsafeMutablePointer,
            bufferListSize: AudioBufferList.sizeInBytes(maximumBuffers: 1),
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer
        )
        
        if let data: UnsafeMutableRawPointer = audioBufferList.unsafePointer.pointee.mBuffers.mData {
            
            let samples = data.assumingMemoryBound(to: Int16.self)
            
            let sizeofInt16 = MemoryLayout<Int16>.size
            let dataSize = audioBufferList.unsafePointer.pointee.mBuffers.mDataByteSize
            
            let dataCount = Int(dataSize) / sizeofInt16
            
            var sampleArray = Array(UnsafeBufferPointer(start: samples, count: dataCount)) as [Int16]
            
            sampleArray.reverse()
            
            var status:OSStatus = noErr
            
            sampleArray.withUnsafeBytes { sampleArrayPtr in
                if let baseAddress = sampleArrayPtr.baseAddress {
                    let bufferPointer: UnsafePointer<Int16> = baseAddress.assumingMemoryBound(to: Int16.self)
                    let rawPtr = UnsafeRawPointer(bufferPointer)
                    
                    status = CMBlockBufferReplaceDataBytes(with: rawPtr, blockBuffer: blockBuffer!, offsetIntoDestination: 0, dataLength: Int(dataSize))
                } 
            }
            
            if status != noErr {
                return nil
            }
            
            let formatDescription = CMSampleBufferGetFormatDescription(self)
            
            let numberOfSamples = CMSampleBufferGetNumSamples(self)
            
            var newBuffer:CMSampleBuffer?
            
            guard CMSampleBufferCreate(allocator: kCFAllocatorDefault, dataBuffer: blockBuffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: formatDescription, sampleCount: numberOfSamples, sampleTimingEntryCount: timingInfo.count, sampleTimingArray: timingInfo, sampleSizeEntryCount: 0, sampleSizeArray: nil, sampleBufferOut: &newBuffer) == noErr else {
                return self
            }
            
            return newBuffer
        }
        
        return self
    }
}

