//
//  ContentView.swift
//  DartsScoreVoice
//
//  Created by Bogdan Sukonnov on 2/15/20.
//  Copyright © 2020 Evermind. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    let startWord: String = "start"
    let endWord: String = "stop"
    
    @ObservedObject var counter: Counter
    @ObservedObject var speechRecognitionService: SpeechRecognitionService
    
    init() {
        let oneCounter = Counter()
        self.counter = oneCounter
        speechRecognitionService = SpeechRecognitionService(startWord: "start", endWord: "stop", counter: oneCounter)
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
