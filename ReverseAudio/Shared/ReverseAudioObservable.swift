//
//  ReverseAudioObservable.swift
//  ReverseAudio
//
//  Created by Limit Point LLC on 9/26/21.
//

import Foundation
import AVFoundation

class ReverseAudioObservable: ObservableObject  {
    
    @Published var reversedAudioURL:URL?
    @Published var reversedReversedAudioURL:URL?
    
    @Published var progress:Float = 0
    
    var documentsURL:URL
    
    var audioPlayer: AVAudioPlayer? // hold on to it!
    
    func reverse(url:URL, saveTo:String, completion: @escaping (Bool, URL, String?) -> ()) {
        
        let fm = FileManager.default
        let documentsURL = try! fm.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        let reversedURL = documentsURL.appendingPathComponent(saveTo)
        
        let asset = AVAsset(url: url)
        
        asset.reverseAudio(destinationURL: reversedURL, progress: { value in
            DispatchQueue.main.async {
                self.progress = value
            }
        }) { (success, failureReason) in
            completion(success, reversedURL, failureReason)
        }
    }
    
    func reverseBundleResource(filename:String, withExtension:String) {
        if let url = Bundle.main.url(forResource: filename, withExtension: withExtension) {
            
                // 
            reverse(url: url, saveTo: "\(filename)-REVERSED.wav") { (success, reversedURL, failureReason) in
                
                if success {
                    
                    print("SUCCESS! - reversed URL = \(reversedURL)")
                    
                    self.reverse(url: reversedURL, saveTo: "\(filename)-REVERSED-REVERSED.wav") { (success, reversedURL, failureReason) in
                        
                        if success {
                            
                            print("SUCCESS! - reversed reversed URL = \(reversedURL)")
                            
                        }
                        DispatchQueue.main.async {
                            self.progress = 0
                            self.reversedReversedAudioURL = reversedURL
                        }
                        
                        
                    }
                }
                DispatchQueue.main.async {
                    self.progress = 0
                    self.reversedAudioURL = reversedURL
                }
            }
        }
    }
    
    func reverseImAfraidICantDoThat() {
        
        reversedAudioURL = nil
        reversedReversedAudioURL = nil
        
        progress = 0
        
        reverseBundleResource(filename: "I'm Afraid I Can't Do That", withExtension: "m4a")
    }
    
    func reversePiano() {
        
        reversedAudioURL = nil
        reversedReversedAudioURL = nil
        
        progress = 0
        
        reverseBundleResource(filename: "Piano", withExtension: "m4a")
    }
    
    func loadPlayAudioURL(named name:String) {
        
        var audioURL:URL?
        
        if let url = Bundle.main.url(forResource: name, withExtension: "m4a") {
            audioURL = url
        }
        else {
            if let url = Bundle.main.url(forResource: name, withExtension: "aif") {
                audioURL = url
            }
            else {
                if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
                    audioURL = url
                }
            }
        }
        
        if let audioURL = audioURL {
            playAudioURL(audioURL)
        }
        else {
            print("Can't load audio url!")
        }
    }
        
    func playAudioURL(_ url:URL) {
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)         
            
            if let audioPlayer = audioPlayer {
                audioPlayer.prepareToPlay()
                audioPlayer.play()
            }
            
        } catch let error {
            print(error.localizedDescription)
        }
        
    }
    
    init() {
        let fm = FileManager.default
        documentsURL = try! fm.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
}
