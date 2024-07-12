//
//  NFCView.swift
//  TaCo
//
//  Created by Harshit Garg on 22/06/24.
//

import Foundation
import AVFoundation
import SwiftUI
import Speech

func dummyAction() {
    debugPrint("Dummy Action activated")
}

struct NFCView: View {
    let delegate_ = NFCSessionDelegate()
    var AudioSynthesiser = AVSpeechSynthesizer()
    var voice = AVSpeechSynthesisVoice(language: "en-GB")
    @StateObject var speechActor = SpeechRecognizer()
    
    let readNFCQueue = DispatchQueue(label: "Read nfc queue")
    
    private func readNFCTag() {
        let reader = NFCReader(delegate: self.delegate_)
        delegate_.bWriteMessage = false
        reader.startSession()
    }
    
    private func writeNFCTag() {
        Task {
            AudioServicesPlayAlertSound(SystemSoundID(1322))
            await self.speechActor.record()
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false){ timer in
                debugPrint("Starting the stop record")
                Task {
                    var nfcMsg: String = ""
                    nfcMsg = await self.speechActor.getTranscript()
                    AudioServicesPlayAlertSound(SystemSoundID(1322))
                    await self.speechActor.stopRecord()
                    let writer = NFCReader(delegate: self.delegate_)
                    delegate_.message = nfcMsg
                    delegate_.bWriteMessage = true
                    writer.startSession()
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            Button(action: writeNFCTag) {
                Rectangle()
                    .fill(.red)
            }
            Button(action: readNFCTag) {
                Rectangle()
                    .fill(.green)
            }
        }
    }
}

struct NFCViewPreview: PreviewProvider {
    static var previews: some View {
        NFCView()
    }
}
