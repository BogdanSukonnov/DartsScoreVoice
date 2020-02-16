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
    
    @Published var transcription: String = ""
    @Published var status: String = "Initial"
    var isListening: Bool = false
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var isAuthorized: Bool = false
    var authorisationStatus: String = "not checked"
    
    init() {        
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
    
    func buildStatus() {
        
        self.status = "Auth: \(self.authorisationStatus); isListening: \(self.isListening)"
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
                print("ROBOT LISTEN: \(result.bestTranscription.formattedString)")
                self.transcription = result.bestTranscription.formattedString
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.isListening = false
                self.recognitionRequest = nil
                self.recognitionTask = nil
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
