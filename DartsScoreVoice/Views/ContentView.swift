//
//  ContentView.swift
//  DartsScoreVoice
//
//  Created by Bogdan Sukonnov on 2/15/20.
//  Copyright © 2020 Evermind. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    let startWord: String
    
    @ObservedObject var counter: Counter
    @ObservedObject var speechRecognitionService: SpeechRecognitionService
    var speaker: TextToSpeechService
    
    init() {
        let doubleWord = "double"
        let tripleWord = "triple"
        self.startWord = "start"
        let tempSpeaker = TextToSpeechService()
        self.speaker = tempSpeaker
        let tempCounter = Counter(doubleWord: doubleWord, tripleWord: tripleWord, speaker: tempSpeaker)
        self.counter = tempCounter
        self.speechRecognitionService = SpeechRecognitionService(startWord: startWord, counter: tempCounter, doubleWord: doubleWord, tripleWord: tripleWord, speaker: tempSpeaker)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Status: \(self.speechRecognitionService.status)")
                Spacer()
                Text(self.speechRecognitionService.transcription)
                Spacer()
                Text(self.counter.count)
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
