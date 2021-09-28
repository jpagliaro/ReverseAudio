//
//  ReverseAudioApp.swift
//  Shared
//
//  Created by Limit Point LLC on 9/26/21.
//

import SwiftUI

@main
struct ReverseAudioApp: App {
    var width:CGFloat = 480
    var height:CGFloat = 480
#if os(macOS)
    init() {
        if let screen = NSScreen.main {
            let rect = screen.frame
            height = rect.size.height/2
            width = rect.size.width/2
        }
    }
#endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ReverseAudioObservable())
                .frame(width: width, height: height)
        }
        
    }
}
