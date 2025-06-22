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

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(viewModel)
        } label: {
            Text(viewModel.menuBarTitle)
                .font(.system(.body).monospacedDigit())
        }
        .menuBarExtraStyle(.window)
    }
}
