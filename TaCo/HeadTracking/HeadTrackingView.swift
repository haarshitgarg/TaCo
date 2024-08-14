//
//  HeadTrackingView.swift
//  TaCo
//
//  Created by Harshit Garg on 15/08/24.
//

import Foundation
import SwiftUI

struct HeadTrackingView: View {
    let head_tracker = HeadTracker()
    
    var body: some View {
        Button(action: head_tracker.startHeadTracking) {
            Rectangle().fill(.yellow)
        }
    }
}
