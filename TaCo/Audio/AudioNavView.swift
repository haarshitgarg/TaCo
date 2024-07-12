//
//  AudioNavView.swift
//  TaCo
//
//  Created by Harshit Garg on 12/07/24.
//

import Foundation
import SwiftUI

struct NavView: View {
    @State private var env = SpatialEnv()
    @State var x: Float = 10
    @State var isEditing: Bool = false
    private func playSound() {
        debugPrint("Playing sound")
        do {
            try env.playSpatialAudio()
        }
        catch {
            debugPrint("Unable to play the coutdown because: \(error)")
        }
    }
    
    func modifySoure(loc: Float) {
        self.env.modifySourceLocation(x: loc)
    }
    
    var body: some View {
        VStack {
            Button(action: playSound){
                Rectangle().fill(.blue)
            }
            Slider(
                value: $x, 
                in: 0...30, 
                onEditingChanged:{
                    editing in
                    isEditing = editing
                    modifySoure(loc: x)
                    
                }
            )
        }
    }
}

struct NavViewPreview: PreviewProvider {
    static var previews: some View {
        NavView()
    }
}
