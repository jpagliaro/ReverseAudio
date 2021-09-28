//
//  ContentView.swift
//  Shared
//
//  Created by Limit Point LLC on 9/26/21.
//

import SwiftUI

struct ContentView: View {
     
    @EnvironmentObject var reverseAudioObservable:ReverseAudioObservable
    
    var body: some View {
        VStack {
            
            #if os(macOS)
            VStack {
                Text("Files generated into Documents folder.")
                    .fontWeight(.bold)
                    .padding(2)
                Text("This app reverses and then reverses the reversed.")
                
                Button("Go to Documents", action: { 
                    NSWorkspace.shared.open(reverseAudioObservable.documentsURL)
                }).padding(2)
            }
            #else 
            Text("Files generated into Documents folder.")
                .fontWeight(.bold)
                .padding(2)
            #endif
            
            VStack {
                Text("Tap to reverse and reverse reverse:")
                    .foregroundColor(.green)
                    .padding(2)
                
                Button("I'm Afraid I Can't Do That (4 sec)", action: { 
                    reverseAudioObservable.reverseImAfraidICantDoThat()
                }).padding(2)
                
                Button("Piano (47 sec)", action: { 
                    reverseAudioObservable.reversePiano()
                }).padding(2)
                
                ProgressView("Progress:", value: reverseAudioObservable.progress, total: 1)
                    .padding(2)
                    .frame(width: 100)
                
            }
            
            
            Text("Play:")
                .foregroundColor(.green)
                .padding(2)
            
            Button("I'm Afraid I Can't Do That", action: { 
                reverseAudioObservable.loadPlayAudioURL(named: "I'm Afraid I Can't Do That")
            }).padding(2)
            
            Button("Piano", action: { 
                reverseAudioObservable.loadPlayAudioURL(named: "Piano")
            }).padding(2)
            
            Text("Results (tap button above to reverse):")
                .foregroundColor(.green)
                .padding(2)
            
            if let audioURL = reverseAudioObservable.reversedAudioURL {
                Button("Play Reversed Audio", action: { 
                    reverseAudioObservable.playAudioURL(audioURL)
                }).padding(2)
            }
            else {
                Text("No reversed to play.")
                    .padding(2)
            }
            
            if let audioURL = reverseAudioObservable.reversedReversedAudioURL {
                Button("Play Reversed Reversed Audio", action: { 
                    reverseAudioObservable.playAudioURL(audioURL)
                }).padding(2)
            }
            else {
                Text("No reversed reversed to play.")
                    .padding(2)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ReverseAudioObservable())
    }
}
