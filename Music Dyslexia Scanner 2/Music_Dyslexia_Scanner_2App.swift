//
//  Music_Dyslexia_Scanner_2App.swift
//  Music Dyslexia Scanner 2
//
//  Created by Asher Julius Zaczepinski on 5/8/25.
//

import SwiftUI

@main
struct Music_Dyslexia_Scanner_2App: App {
    @StateObject private var appSettings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appSettings)
        }
    }
}
