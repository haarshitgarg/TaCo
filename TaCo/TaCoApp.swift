//
//  TaCoApp.swift
//  TaCo
//
//  Created by Harshit Garg on 22/06/24.
//

import SwiftUI
import os

let logger = Logger(subsystem: "com.harshit.taco", category: "Games")

@main
struct TaCoApp: App {

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
