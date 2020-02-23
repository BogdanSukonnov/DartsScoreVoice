//
//  Counter.swift
//  DartsScoreVoice
//
//  Created by Bogdan Sukonnov on 2/16/20.
//  Copyright © 2020 Evermind. All rights reserved.
//

import Foundation

class Counter: ObservableObject {
    
    @Published var count = "initial count"
    private let speaker: TextToSpeechService
    
    let doubleWord: String
    let tripleWord: String
    
    init(doubleWord: String, tripleWord: String, speaker: TextToSpeechService) {
        self.doubleWord = doubleWord
        self.tripleWord = tripleWord
        self.speaker = speaker
    }
    
    func add(text: String, multiplier: Multiplier) {
        var multiplierWord: String
        switch multiplier {
        case .double:
            multiplierWord = doubleWord + " "
        case .triple:
            multiplierWord = tripleWord + " "
        default:
            multiplierWord = ""
        }
        self.count = self.count + "; " + text;
        print("COUNT: " + self.count)
        speaker.say(text: multiplierWord + text)
    }
}
