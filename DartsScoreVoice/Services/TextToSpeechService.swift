//
//  TextToSpeechService.swift
//  DartsScoreVoice
//
//  Created by Bogdan Sukonnov on 2/16/20.
//  Copyright © 2020 Evermind. All rights reserved.
//

import Foundation
import AVFoundation

class TextToSpeechService {
       
    private let synthesizer = AVSpeechSynthesizer()
    
    init() {}
    
    public func say(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.6
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }
}
