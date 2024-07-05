//
//  NavView.swift
//  TaCo
//
//  Created by Harshit Garg on 03/07/24.
//

import Foundation
import SwiftUI
import AVFoundation

struct NavView: View {
    let sound = SpatialSound()
    let soundQueue = DispatchQueue(label: "Sound queue")
    
    @State var x: Float = 0
    @State var y: Float = 0
    @State var z: Float = 0

    @State var isediting: Bool = false
    
    func startSound() {
        debugPrint("Starting the sound")
            soundQueue.async {
                do {
                    try sound.setEnvironment()
                }
                catch {
                    debugPrint("Error bro: \(error)")
                }
            }
    }
    
    var body: some View {
        VStack {
            Button(action: startSound) {
                Rectangle().fill(.red)
            }
            Slider(value: $x, in: -10...10, onEditingChanged: {edit in
                self.sound.playerNode.position = AVAudio3DPoint(x: self.x, y: self.y, z: self.z)
                debugPrint("position: \(self.sound.playerNode.position)")
                isediting = edit
            })
            Slider(value: $y, in: -10...10, onEditingChanged: {edit in
                self.sound.playerNode.position = AVAudio3DPoint(x: self.x, y: self.y, z: self.z)
                debugPrint("position: \(self.sound.playerNode.position)")
                isediting = edit
            })
            Slider(value: $z, in: -10...10, onEditingChanged: {edit in
                self.sound.playerNode.position = AVAudio3DPoint(x: self.x, y: self.y, z: self.z)
                debugPrint("position: \(self.sound.playerNode.position)")
                isediting = edit
            })
        }
    }
}

struct NavViewPreview: PreviewProvider {
    static var previews: some View {
        NavView()
    }
}


