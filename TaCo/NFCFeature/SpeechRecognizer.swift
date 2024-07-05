//
//  SpeechRecognizer.swift
//  TaCo
//
//  Created by Harshit Garg on 29/06/24.
//

import Foundation
import AVFoundation
import AVFAudio
import Speech

actor SpeechRecognizer: ObservableObject {
    enum AuthStatus {
        case authorised
        case unauthorised
        case notDetermined
    }
    
    enum RecogniserStatus {
        case InitState
        case TranscribeState
        case FailedState
    }
    
    @MainActor private var transcript: String = ""
    private var audioSession: AVAudioSession? = nil
    private var audioEngine: AVAudioEngine? = nil
    private var request: SFSpeechAudioBufferRecognitionRequest? = nil
    private var task: SFSpeechRecognitionTask? = nil
    private let speechRecogniser: SFSpeechRecognizer?
    private var auth: SFSpeechRecognizerAuthorizationStatus {
        didSet{
            if self.auth == .notDetermined {
                SFSpeechRecognizer.requestAuthorization(authHandler)
            }
            else if self.auth == .authorized && self.recordAudio {
                Task {
                    await startTranscribe()
                }
            }
        }
    }
    
    public var recordAudio: Bool {
        didSet {
            if auth == .authorized && self.recordAudio {
                Task {
                    await startTranscribe()
                }
            }
            if self.recordAudio == false {
                self.reset()
            }
        }
    }
    
    private func updateAuthStatus(status: SFSpeechRecognizerAuthorizationStatus) {
        debugPrint("Updating the auth status to \(status)")
        self.auth = status
    }
    
    public func record() {
        debugPrint("Starting to record")
        self.recordAudio = true
    }
    
    public func stopRecord(){
        debugPrint("Stopping the recording")
        self.recordAudio = false
    }
    
    @MainActor public func startTranscribe() {
        Task {
            debugPrint("Starting to transcribe...")
            await self.transcribe()
        }
    }
    
    @MainActor public func getTranscript() -> String {
        return self.transcript
    }
    
    private func prepareAudioEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest, AVAudioSession) {
        let audioEngine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        let audioSession = AVAudioSession.sharedInstance()
        
        try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        debugPrint("Audio session started")
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat){ (buffer, time) in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request, audioSession)
    }
    
    private func transcribe() {
        guard let speechRecogniser, speechRecogniser.isAvailable else {
            debugPrint("Couldn't transcribe")
            self.reset()
            return
        }
        
        do {
            let (audioEngine, request, audioSession) = try self.prepareAudioEngine()
            
            self.audioEngine = audioEngine
            self.request = request
            self.audioSession = audioSession
            
            self.task = self.speechRecogniser?.recognitionTask(with: request, resultHandler: { [weak self] result, error in
                self?.recognitionTaskHandler(audioEngine: audioEngine, audioSession: audioSession, result: result, error: error)
            })
        }
        catch {
            debugPrint("Faced the error: \(error)")
            self.reset()
        }
    }
    
    private nonisolated func recognitionTaskHandler(audioEngine: AVAudioEngine, audioSession: AVAudioSession, result: SFSpeechRecognitionResult?, error: Error?) {
        let receivedFinalMessage = result?.isFinal ?? false
        let receivedError = error != nil
        
        if receivedError || receivedFinalMessage {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            debugPrint("Received the final message or an error")
            do {
                try audioSession.setCategory(.soloAmbient, mode:.default, options: .defaultToSpeaker)
                debugPrint("Reset the audioSession")
            }
            catch {
                debugPrint("Couldn't deactivate the session")
            }
        }
        
        if let result {
            debugPrint("Writing to the transcript")
            Task{ @MainActor in
                self.transcript = result.bestTranscription.formattedString
            }
        }
    }
    
    private func reset() {
        debugPrint("Resetting the variables of speech recogniser")
        
        self.task?.cancel()
        self.audioEngine?.stop()
        self.audioEngine = nil
        self.task = nil
        self.request = nil
        self.audioSession = nil
        Task { @MainActor in
            self.transcript = ""
        }
    }
    
    nonisolated func authHandler(status: SFSpeechRecognizerAuthorizationStatus) {
        Task {
            await self.updateAuthStatus(status: status)
        }
    }
    
    init() {
        self.auth = .notDetermined
        self.recordAudio = false
        speechRecogniser = SFSpeechRecognizer()
        guard speechRecogniser != nil else {
            debugPrint("Could not initialise the speech recogniser")
            return
        }
        
        self.auth = SFSpeechRecognizer.authorizationStatus()
    }
}
