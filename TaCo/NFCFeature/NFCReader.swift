//
//  NFCReader.swift
//  TaCo
//
//  Created by Harshit Garg on 22/06/24.
//

import Foundation
import AVFoundation
import CoreNFC

class NFCSessionDelegate: NSObject, NFCNDEFReaderSessionDelegate {
    var message: String = "sample message"
    var bWriteMessage: Bool = false
    var AudioSynthesizer = AVSpeechSynthesizer()
    var voice = AVSpeechSynthesisVoice(language: "en-GB")
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        debugPrint("[Delegate] Session became active")
    }
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {
        session.invalidate()
        debugPrint("Error: \(error.localizedDescription)")
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        debugPrint("[Delegate] Detected the NDEF tag")
    }
    
    private func readFromTag(tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        tag.readNDEF{ ndefMsg, error in
            if let error = error {
                debugPrint("Error: \(error)")
                session.invalidate(errorMessage: "Could not read the message")
                return
            }
            
            guard let data = ndefMsg?.records[0].payload
            else {
                session.invalidate(errorMessage: "Could not read the message. No payload")
                return
            }
            
            guard let temp = String(data: data, encoding: .utf8)
            else {
                session.invalidate(errorMessage: "Could not parse the data")
                return
            }
            debugPrint("Message: \(temp)")
            self.SpeakTheWords(words: temp)
            session.invalidate()
        }
    }
    
    private func writeToTag(tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        guard let data = message.data(using: .utf8)
        else {
            debugPrint("Cannot convert message to Data")
            self.message = "Sample message"
            session.invalidate(errorMessage: "Faulty message")
            return
        }
        self.message = "Sample message"
        
        let payload = NFCNDEFPayload(format: .media, type: "application/octet-stream".data(using: .utf8)!, identifier: Data(), payload: data)
        let ndefMsg = NFCNDEFMessage(records: [payload])
        
        tag.writeNDEF(ndefMsg) { error in
            if let error = error {
                session.invalidate(errorMessage: error.localizedDescription)
                return
            }
            session.alertMessage = "Wrote data to the tag"
            debugPrint("[Delegate] Wrote message to the tag")
            session.invalidate()
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [any NFCNDEFTag]) {
        debugPrint("[Delegate] Detected a tag")
        if tags.count > 1 {
            session.alertMessage = "Multiple tags detected"
            let interval = DispatchTimeInterval.milliseconds(500)
            DispatchQueue.global().asyncAfter(deadline: .now() + interval, execute: session.restartPolling)
            return
        }

        let tag = tags.first!
        session.connect(to: tag) { (error: Error?) in
            if nil != error {
                debugPrint("Unable to connect to the tag")
                session.invalidate(errorMessage: "Unable to connect to the NDEF tag")
                return
            }
            
            debugPrint("[Delegate] Connected to the tag")
            tag.queryNDEFStatus { status, capacity, error in
                if let error = error {
                    session.invalidate(errorMessage: "Error: \(error.localizedDescription)")
                    return
                }
                
                debugPrint("[Delegate] Capacity: \(capacity)")
                var errorMessage: String = "Application closed the session"
                switch status {
                case .notSupported:
                    errorMessage = "Tag not supported"
                    session.invalidate(errorMessage: errorMessage)
                case .readOnly:
                    errorMessage = "Tag is read only"
                    session.invalidate(errorMessage: errorMessage)
                case .readWrite:
                    debugPrint("[Delegate] Perform read or write here")
                    if self.bWriteMessage {
                        self.writeToTag(tag: tag, session: session)
                    }
                    else {
                        self.readFromTag(tag: tag, session: session)
                    }
                default:
                    debugPrint("No clue")
                    session.invalidate(errorMessage: errorMessage)
                }
            }
        }
    }
}

extension NFCSessionDelegate {
    private func SpeakTheWords(words: String) {
        let utterance = AVSpeechUtterance(string: words)
        utterance.volume = 0.8
        utterance.voice = self.voice
        self.AudioSynthesizer.speak(utterance)
        
    }
}

struct NFCReader{
    let sessionQueue_ = DispatchQueue(label: "Session Queue")
    let nfcNDEFSession_: NFCNDEFReaderSession

    public func startSession() {
        nfcNDEFSession_.alertMessage = "Sample alert message"
        nfcNDEFSession_.begin()
        debugPrint("Session started")
    }

    init(delegate: NFCSessionDelegate) {
        self.nfcNDEFSession_ = NFCNDEFReaderSession(delegate: delegate, queue: self.sessionQueue_, invalidateAfterFirstRead: false)
    }
    
}
