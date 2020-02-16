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
                Text(speechRecognitionService.transcription)
                Text("second")
                Spacer()
                Button(action: buttonAction) {
                    Text("Start listening")
                }
            }
        }.onAppear{
//            do {
//                try self.speechRecognitionService.startRecording { (transcription) in
//                    self.name = transcription
//                    print(transcription)
//                }
//            } catch {
//                print(error)
//            }
        }
    }
    
    func buttonAction() {
        if !self.isListening {
            self.speechRecognitionService.requestAuthorization()
            do {
                try self.speechRecognitionService.startRecording()
            } catch {
            }
            self.isListening = true
        }
        
        //name += "a"
//        do {
//            try self.speechRecognitionService.startRecording { (transcription) in
//                self.name = transcription
//                print(transcription)
//            }
//        } catch {
//            print(error)
//        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
