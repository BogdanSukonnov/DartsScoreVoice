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
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    //@Published var transcription: String = ""
    
    init() {        
    }
    
//    func startRecording(completion: @escaping (String) -> Void) throws {
    
    func requestAuthorization() {
        
        // Asynchronously make the authorization request.
        SFSpeechRecognizer.requestAuthorization { authStatus in

            // Divert to the app's main thread so that the UI
            // can be updated.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    print("Authorized")
                    //self.recordButton.isEnabled = true
                    
                case .denied:
                    print("denied")
                    //self.recordButton.isEnabled = false
                    //self.recordButton.setTitle("User denied access to speech recognition", for: .disabled)
                    
                case .restricted:
                    print("restricted")
                    //self.recordButton.isEnabled = false
                    //self.recordButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                    
                case .notDetermined:
                    print("notDetermined")
                    //self.recordButton.isEnabled = false
                    //self.recordButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                    
                default:
                    print("Not authorized")
                    //self.recordButton.isEnabled = false
                }
            }
        }
    }
    
    func startRecording() throws {
        
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
                print("Text \(result.bestTranscription.formattedString)")
                self.transcription = result.bestTranscription.formattedString
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

//                self.recordButton.isEnabled = true
//                self.recordButton.setTitle("Start Recording", for: [])
            }
        }

        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Let the user know to start talking.
//        textView.text = "(Go ahead, I'm listening)"
    }
    
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
}
