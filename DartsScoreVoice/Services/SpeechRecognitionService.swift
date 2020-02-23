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
    
    private let doubleWord: String
    
    private let tripleWord: String
    
    private let counter: Counter
    
    private var isTapInstalled = false
    
    private let pattern: String
    
    private var speaker: TextToSpeechService
    
    init(startWord: String, counter: Counter, doubleWord: String, tripleWord: String, speaker: TextToSpeechService) {
        self.doubleWord = doubleWord
        self.tripleWord = tripleWord
        self.startWord = startWord
        self.counter = counter
        self.pattern = "\(self.startWord).*?([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,25,50]+)"
        self.speaker = speaker
    }
    
    
    private func onTempResult(result: SFSpeechRecognitionResult, audioSession: AVAudioSession) {
   
        print("ROBOT HEAR: \(result.bestTranscription.formattedString)")
        
        transcription = result.bestTranscription.formattedString.lowercased()
        
        if transcription.contains(startWord) && isCountString(fullString: transcription) {
                        
            stopRecording()
        }
    }
    
    private func onFinalResult(result: SFSpeechRecognitionResult, audioSession: AVAudioSession) {
        
        transcription = result.bestTranscription.formattedString.lowercased()
        
        let countString = getCountString(fullString: transcription)
        
        if countString == "" {
            speaker.say(text: "pardon?")
            return
        }
        
        var multiplier: Multiplier = .noMultiplier;
        if transcription.contains(tripleWord) {
            multiplier = .triple
        } else if transcription.contains(doubleWord) {
            multiplier = .double
        }
        
        counter.add(text: countString, multiplier: multiplier)
        
        transcription = "";
    }
    
    private func isCountString(fullString: String) -> Bool {
        
        return getCountString(fullString: fullString) != ""
    }
    
    private func getCountString(fullString: String) -> String {

        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)

        if let match = regex?.firstMatch(in: fullString, options: [], range: NSRange(location: 0, length: fullString.utf16.count)) {
            // match.range(at: 0) - whole match, match.range(at: 1) - first group
            if let fullMatchRange = Range(match.range(at: 0), in: fullString), let countRange = Range(match.range(at: 1), in: fullString) {
                // cut from transcription all before start word
                self.transcription = String(fullString[fullMatchRange])
            return String(fullString[countRange])
          }
        }
        
        return ""
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
        try audioSession.setCategory(.playAndRecord, mode: .default, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        try audioSession.overrideOutputAudioPort(.speaker)
        let inputNode = audioEngine.inputNode

        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.contextualStrings = [self.startWord, self.doubleWord, self.tripleWord, "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "25", "50"]
        
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
                isFinal = result.isFinal
                if isFinal {
                    self.onFinalResult(result: result, audioSession: audioSession)
                } else {
                    self.onTempResult(result: result, audioSession: audioSession)
                }
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

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
            }
        self.isTapInstalled = true
        
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
        
        self.recognitionTask?.finish()
        self.recognitionTask?.cancel()
        self.audioEngine.stop()
        self.recognitionRequest?.endAudio()
        
        print("End stopRecording")
    }
}
