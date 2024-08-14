//
//  SpatialView.swift
//  TaCo
//
//  Created by Harshit Garg on 02/08/24.
//

import Foundation
import SwiftUI
import AVFoundation

struct SpatialView: View {
    @State var x: Float = 0
    @State var y: Float = 0
    @State var z: Float = 0
    
    var soundPlayer = SpatialAudio()
    var body: some View {
        VStack {
            Button(action: soundPlayer.playSpatialSound) {
                Rectangle()
                    .fill(.blue)
            }
            Button(action: soundPlayer.rotateTheSource) {
                Rectangle().fill(.clear)
            }
            Slider(value: $x, in: -10...10){onEditing in
                soundPlayer.updateListnerLocation(x: x, y: y, z: z)
            }
            Slider(value: $y, in: -10...10){onEditing in
                soundPlayer.updateListnerLocation(x: x, y: y, z: z)
            }
            Slider(value: $z, in: -10...10){onEditing in
                soundPlayer.updateListnerLocation(x: x, y: y, z: z)
            }
        }
    }
}

struct SpatialViewPreview: PreviewProvider {
    static var previews: some View {
        SpatialView()
    }
}
