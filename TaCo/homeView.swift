//
//  homeView.swift
//  TaCo
//
//  Created by Harshit Garg on 22/06/24.
//

import Foundation
import SwiftUI
import AVFoundation

struct DummyView: View {
    var body: some View {
        Text("Coming soon")
            .bold()
    }
}
struct HomeView: View {
    private func dummyAction() {
        print("Dummy Action used")
    }
    var body: some View {
        NavigationStack{
            VStack {
                HStack{
                    NavigationLink(destination: NFCView()) {
                        Rectangle().fill(.blue)
                    }
                    NavigationLink(destination: SpatialView()) {
                        Rectangle().fill(.yellow)
                    }
                }
                HStack{
                    NavigationLink(destination: HeadTrackingView()) {
                        Rectangle().fill(.orange)
                    }
                    NavigationLink(destination: DummyView()) {
                        Rectangle().fill(.purple)
                    }
                }
            }
        }
    }
}

struct HomeViewPreview: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
