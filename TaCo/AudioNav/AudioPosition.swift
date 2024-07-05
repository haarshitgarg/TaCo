//
//  AudioPosition.swift
//  TaCo
//
//  Created by Harshit Garg on 03/07/24.
//

import Foundation
import AVFoundation
import AVFAudio

class AudioPosition {
    private var audioSourcePosition: AVAudio3DPoint = AVAudio3DPoint(x: 1, y: 1, z: 0)
    
    public func getAudioSourcePosition() -> AVAudio3DPoint {
        return audioSourcePosition
    }
}
