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
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainMenuView()
            }
            .environment(game)
            .preferredColorScheme(.dark)
        }
    }
}
