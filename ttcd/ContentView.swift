//
//  ContentView.swift
//  ttcd
//
//  Created by Dinh Duong on 21/6/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: PomodoroViewModel
    @State private var showSettings = false

    // MARK: - UI Constants
    private let offWhite = Color(red: 0.96, green: 0.96, blue: 0.95)
    private let darkBlue = Color(red: 0.1, green: 0.2, blue: 0.3)
    private let teal = Color(red: 0.3, green: 0.6, blue: 0.6)

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                
                Button(action: { viewModel.reset() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(darkBlue.opacity(0.8))
                }
                .buttonStyle(.plain)
                
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(darkBlue.opacity(0.8))
                }
                .buttonStyle(.plain)
            }

            timerCircle
            
            startButton
        }
        .padding()
        .background(offWhite)
        .background( // Add our key listener as a background view
            KeyEventListenerView(onKeyDown: { event in
                // The key code for the space bar is 49.
                if event.keyCode == 49 {
                    print("Space bar pressed via KeyEventListenerView!")
                    viewModel.toggleTimer()
                }
            })
        )
        .cornerRadius(12)
        .shadow(radius: 10)
        .frame(width: 280, height: 320)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
                .environmentObject(viewModel)
        }
        .modifier(ShakeEffect(shakes: viewModel.shake))
    }

    private var timerCircle: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(darkBlue.opacity(0.2), lineWidth: 15)

            // Progress ring
            let totalDuration = viewModel.totalDuration
            let progress = totalDuration > 0 ? (totalDuration - viewModel.timeRemaining) / totalDuration : 0
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(teal, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: viewModel.timeRemaining)

            VStack {
                Text(viewModel.formattedTime)
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(darkBlue)
                
                Text(viewModel.phase.rawValue.capitalized)
                    .font(.headline)
                    .foregroundColor(darkBlue.opacity(0.7))
            }
        }
        .padding(20)
    }
    
    private var startButton: some View {
        VStack(spacing: 8) {
            Button(action: {
                viewModel.toggleTimer()
            }) {
                Text(viewModel.isActive ? "PAUSE" : "START")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .kerning(2.0)
                    .foregroundColor(darkBlue)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 40)
                    .background(viewModel.isActive ? Color.gray.opacity(0.3) : Color.clear)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)

            // Visual indicator for space bar functionality
            Text("Press SPACE to start/pause")
                .font(.caption)
                .foregroundColor(darkBlue.opacity(0.6))
                .kerning(0.5)
        }
    }
}

// MARK: - Shake Animation
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    init(shakes: Int) {
        self.animatableData = CGFloat(shakes)
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PomodoroViewModel())
    }
}
