//
//  TextToSpeechService.swift
//  DartsScoreVoice
//
//  Created by Bogdan Sukonnov on 2/16/20.
//  Copyright © 2020 Evermind. All rights reserved.
//

import Foundation

//    private func recognize(completion: @escaping (String) -> Void) throws {
//        let node = audioEngine.inputNode
//        let recordingFormat = node.outputFormat(forBus: 0)
//
//        node.installTap(onBus: 0, bufferSize: 1024,
//                       format: recordingFormat) { [unowned self]
//                           (buffer, _) in
//                           self.request.append(buffer)
//        }
//
//        audioEngine.prepare()
//        try audioEngine.start()
//
//        recognitionTask = speechRecognizer?.recognitionTask(with: request) { (result, _) in
//           if let transcription = result?.bestTranscription {
//               print(transcription.formattedString)
//               completion(transcription.formattedString)
//               //self.textLabel.text = transcription.formattedString
//           }
//        }
//    }
