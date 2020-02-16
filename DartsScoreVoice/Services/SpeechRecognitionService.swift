//
//  SpeechRecognitionService.swift
//  DartsScoreVoice
//
//  Created by Bogdan Sukonnov on 2/15/20.
//  Copyright © 2020 Evermind. All rights reserved.
//

import Speech
import Foundation

class SpeechRecognitionService: ObservableObject {
    
    @Published var transcription = ""
    @Published var status = "Initial"
    @Published var isListening = false
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var isAuthorized: Bool = false
    var authorisationStatus = "not checked"
    let startWord: String
    let endWord: String
    let counter: Counter
    
    init(startWord: String, endWord: String, counter: Counter) {
        self.startWord = startWord
        self.endWord = endWord
        self.counter = counter
    }
    
    private func onResult(result: SFSpeechRecognitionResult) {
        
        print("ROBOT HEAR: \(result.bestTranscription.formattedString)")
        
        self.transcription = result.bestTranscription.formattedString.lowercased()
        
        if self.transcription.contains(self.startWord) && self.transcription.contains(self.endWord) {
                        
            let slice = self.transcription.slice(from: self.startWord, to: self.endWord) ?? ""
            self.counter.add(text: slice)
        }
    }
        
    func initListening() throws {
        
        if !self.isAuthorized {
            self.requestAuthorization()
        } else {
            do {
                try self.startListening()
            } catch {
            }
            
        }
    }
    
    private func requestAuthorization() {
        
        // Asynchronously make the authorization request.
        SFSpeechRecognizer.requestAuthorization { authStatus in

            // Divert to the app's main thread so that the UI
            // can be updated.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.isAuthorized = true
                    self.authorisationStatus = "Authorized"
                    
                case .denied:
                    self.authorisationStatus = "User denied access to speech recognition"
                    
                case .restricted:
                    self.authorisationStatus = "Speech recognition restricted on this device"
                    
                case .notDetermined:
                    self.authorisationStatus = "Speech recognition not yet authorized"
                    
                default:
                    self.authorisationStatus = "Not authorized"
                }
                print(self.authorisationStatus)
                self.buildStatus()
                if self.isAuthorized {
                    do {
                        try self.startListening()
                    } catch {
                    }
                }
            }
        }
    }
    
    private func buildStatus() {
        
        self.status = "Auth: \(self.authorisationStatus); isListening: \(self.isListening)"
    }
    
    private func startListening() throws {
        
        // Cancel the previous task if it's running.
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode

        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep speech recognition data on device
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.isFinal = result.isFinal
                self.onResult(result: result)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.isListening = false
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.buildStatus()
            }
        }

        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try
            audioEngine.start()
            self.isListening = true
        
        self.buildStatus()
                
    }
}

extension String {

    func slice(from: String, to: String) -> String? {

        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}
