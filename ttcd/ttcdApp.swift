//
//  ttcdApp.swift
//  ttcd
//
//  Created by Dinh Duong on 21/6/25.
//

import SwiftUI

@main
struct ttcdApp: App {
    @StateObject private var viewModel = PomodoroViewModel()
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(appState)
        } label: {
            Text(viewModel.menuBarTitle)
                .font(.system(.body).monospacedDigit())
        }
        .menuBarExtraStyle(.window)
        
        Window("ttcd", id: "main-window") {
            MainAppView()
                .environmentObject(viewModel)
                .environmentObject(appState)
        }
        .windowResizability(.contentSize)
    }
}
