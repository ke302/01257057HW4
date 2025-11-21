//
//  _1257057HW4App.swift
//  01257057HW4
//
//  Created by user05 on 2025/11/19.
//

import SwiftUI

@main
struct _1257057HW4App: App {
    
    @State private var game = BalatroGame()
    @AppStorage("isMusicOn") private var isMusicOn = true
    @AppStorage("isSoundEffectOn") private var isSoundEffectOn = true
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainMenuView()
            }
            .environment(game)
            .preferredColorScheme(.dark)
            .onAppear {
                AudioManager.shared.updateMusicState(isMusicOn: isMusicOn)
                AudioManager.shared.isSoundEffectOn = isSoundEffectOn
            }
            .onChange(of: isMusicOn) { _, newValue in
                AudioManager.shared.updateMusicState(isMusicOn: newValue)
            }
            .onChange(of: isSoundEffectOn) { _, newValue in
                AudioManager.shared.isSoundEffectOn = newValue
            }
        }
    }
}
