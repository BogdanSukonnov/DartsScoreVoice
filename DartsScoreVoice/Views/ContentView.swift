//
//  ContentView.swift
//  DartsScoreVoice
//
//  Created by Bogdan Sukonnov on 2/15/20.
//  Copyright © 2020 Evermind. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var speechRecognitionService = SpeechRecognitionService()
    @State private var isListening: Bool = false
    var body: some View {
        NavigationView {
            VStack {
                Text("Status: \(speechRecognitionService.status)")
                Text(speechRecognitionService.transcription)
                Text("second")
                Spacer()
                Button(action: buttonAction) {
                    Text("Button")
                }
            }
        }.onAppear{
            do {
                try self.speechRecognitionService.initListening()
            } catch {
            }
        }
    }
    
    func buttonAction() {
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
