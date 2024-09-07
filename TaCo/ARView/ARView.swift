//
//  ARView.swift
//  TaCo
//
//  Created by Harshit Garg on 07/09/24.
//

import Foundation
import SwiftUI
import AVFoundation

struct ARView: View {
    let ar_controller_ = ARController()
    
    public func ButtonAction() {
        let session_status = ar_controller_.IsSessionActive()
        if(session_status) {
            ar_controller_.StopSound()
            ar_controller_.StopARSession()
        }
        else {
            ar_controller_.StartARSession()
            ar_controller_.PlaySound()
        }
    }
    var body: some View {
        Button(action: ButtonAction) {
            Rectangle()
                .fill(.blue)
        }
    }
}

struct ARViewPreview: PreviewProvider {
    static var previews: some View {
        ARView()
    }
}
