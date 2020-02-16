//
//  SpeechRecognitionService.swift
//  DartsScoreVoice
//
//  Created by Bogdan Sukonnov on 2/15/20.
//  Copyright © 2020 Evermind. All rights reserved.
//

import Foundation
import Speech

class SpeechRecognitionService: ObservableObject  {
    
    @Published var transcription = ""
    
    @Published var status = "Initial"
    
    @Published var isListening = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
   
    private var isAuthorized: Bool = false
    
    private var authorisationStatus = "not checked"
    
    private let startWord: String
    
    private let endWord: String
    
    private let counter: Counter
    
    private var isTapInstalled = false
    
    
    init(startWord: String, endWord: String, counter: Counter) {
        self.startWord = startWord
        self.endWord = endWord
        self.counter = counter
    }
    
    
    private func onResult(result: SFSpeechRecognitionResult, audioSession: AVAudioSession) {
        
        print("ROBOT HEAR: \(result.bestTranscription.formattedString)")
        
        self.transcription = result.bestTranscription.formattedString.lowercased()
        
        if self.transcription.contains(self.startWord) && self.transcription.contains(self.endWord) {
                        
            let slice = self.transcription.slice(from: self.startWord, to: self.endWord) ?? ""
            
            self.transcription = "";
            self.counter.add(text: slice)
            
            self.stopRecording()
            //self.safeStartListening()
        }
    }
        
    public func initListening() throws {
        
        if !self.isAuthorized {
            self.requestAuthorization()
        } else {
            self.safeStartListening()
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
                    self.safeStartListening()
                }
            }
        }
    }
    
    private func buildStatus() {
        
        self.status = "Auth: \(self.authorisationStatus); isListening: \(self.isListening)"
    }
    
    private func safeStartListening() {
        do {
            try self.startListening()
        } catch {
        }
    }
    
    private func startListening() throws {
        
        print("Start startListening")
        
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
        recognitionRequest.contextualStrings = [self.startWord, self.endWord, "double", "triple", "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "eighteen", "nineteen", "twenty", "twentyfive", "fifty"]
        
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
                self.onResult(result: result, audioSession: audioSession)
                isFinal = result.isFinal
            }
            
            if error != nil ||  isFinal{
                
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.isListening = false
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.buildStatus()
                
                if isFinal {
                    // restart listening
                    self.safeStartListening()
                }
            }
        }

        // Configure the microphone input.
        //if !self.isTapInstalled {
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                self.recognitionRequest?.append(buffer)
                }
            self.isTapInstalled = true
        //}
        
        audioEngine.prepare()
        try
            audioEngine.start()
            self.isListening = true
        
        self.buildStatus()
        
        print("End startListening")
    }

    
    public func stopRecording() {
        
        print("Start stopRecording")
        self.isListening = false
        
        // Call this method explicitly to let the speech recognizer know that no more audio input is coming.
        self.recognitionTask?.finish()
        self.recognitionTask?.cancel()
        self.audioEngine.stop()
        self.recognitionRequest?.endAudio()
        
        //self.recognitionRequest = nil
        
        // For audio buffer–based recognition, recognition does not finish until this method is called, so be sure to call it when the audio source is exhausted.
        //self.recognitionTask?.finish()
        
        //self.recognitionTask = nil
        
        //self.audioEngine.inputNode.removeTap(onBus: 0)
        
        print("End stopRecording")
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
