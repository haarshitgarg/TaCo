//
//  SpatialSound.swift
//  TaCo
//
//  Created by Harshit Garg on 03/07/24.
//

import Foundation
import AVFAudio
import AVFoundation

enum SpatialSoundError: Error {
    case SetEnvironmentError
    case GenericError
}

class SpatialSound {
    private let audioEngine = AVAudioEngine()
    private let envNode = AVAudioEnvironmentNode()
    let playerNode = AVAudioPlayerNode()
    
    private func setup() {
        self.envNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        self.envNode.renderingAlgorithm = AVAudio3DMixingRenderingAlgorithm.HRTF
        debugPrint("Orientation of the listner \(self.envNode.listenerVectorOrientation)")
        debugPrint("Angle of the listner \(self.envNode.listenerAngularOrientation)")
        self.playerNode.sourceMode = .pointSource
    }
    

    func setEnvironment() throws {
        setup()
        guard let audioFileURL = Bundle.main.url(forResource: "countdown", withExtension: "mp3")
        else {
            debugPrint("Couldn't create url")
            throw SpatialSoundError.GenericError
        }
        let audioFile: AVAudioFile = try AVAudioFile(forReading: audioFileURL)
        
        
        let inputFormat = self.audioEngine.inputNode.inputFormat(forBus: 0)
        debugPrint("Input format channel count: \(inputFormat.channelCount)")
        debugPrint("Input format sample rate: \(inputFormat.sampleRate)")
        
        let outputFormat = self.audioEngine.outputNode.outputFormat(forBus: 0)
        debugPrint("Output format channel count: \(outputFormat.channelCount)")
        debugPrint("Output format sample rate: \(outputFormat.sampleRate)")
        
        self.audioEngine.attach(envNode)
        self.audioEngine.connect(envNode, to: audioEngine.outputNode, format: nil)
        
        self.audioEngine.attach(playerNode)
        self.audioEngine.connect(playerNode, to: envNode, format: nil)
        
        self.playerNode.scheduleFile(audioFile, at: nil)
        
        debugPrint("Here...")
        try self.audioEngine.start()
        self.playerNode.play()
        
        debugPrint("Rendering algorithm in use right now: \(self.envNode.renderingAlgorithm)")

        debugPrint("Here...")
    }
}
