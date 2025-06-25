//
//  ContentView.swift
//  ttcd
//
//  Created by Dinh Duong on 21/6/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var viewModel: PomodoroViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow
    @State private var showSettings = false
    @State private var showStats = false
    @State private var showTagInput = false
    @State private var tagInputText = ""

    // MARK: - UI Constants
    private let offWhite = Color(red: 0.96, green: 0.96, blue: 0.95)
    private let darkBlue = Color(red: 0.1, green: 0.2, blue: 0.3)
    private let teal = Color(red: 0.3, green: 0.6, blue: 0.6)

    var body: some View {
        VStack(spacing: 32) {
            HStack {
                Spacer()
                HStack(spacing: 16) {
                    Spacer()
                    Button(action: { viewModel.reset() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(darkBlue.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        appState.activeView = .stats
                        openWindow(id: "main-window")
                        NSApp.activate(ignoringOtherApps: true)
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.title2)
                            .foregroundColor(darkBlue.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        appState.activeView = .settings
                        openWindow(id: "main-window")
                        NSApp.activate(ignoringOtherApps: true)
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(darkBlue.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.trailing, 0)
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
                    handleTimerButtonPress()
                }
            })
            .id("keyListener-\(showTagInput)") // Force refresh when tag input state changes
        )
        .cornerRadius(0)
        .shadow(radius: 10)
        .frame(width: 320, height: 420)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: _viewModel)
                .environmentObject(viewModel)
        }
        .onChange(of: showSettings) { isShowing in
            // Pause the timer when settings are opened to prevent the
            // MenuBarExtra label from updating and dismissing the sheet.
            if isShowing && viewModel.isActive {
                viewModel.pause()
            }
        }
        .sheet(isPresented: $showStats) {
            StatsView()
        }
        .modifier(ShakeEffect(shakes: viewModel.shake))
        .overlay(
            // Tag input overlay
            tagInputOverlay
        )
    }

    private var timerCircle: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(darkBlue.opacity(0.2), lineWidth: 20)

            // Progress ring
            let totalDuration = viewModel.totalDuration
            let progress = totalDuration > 0 ? (totalDuration - viewModel.timeRemaining) / totalDuration : 0
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(teal, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: viewModel.timeRemaining)

            VStack {
                Text(viewModel.formattedTime)
                    .font(.system(size: 70, weight: .bold, design: .rounded))
                    .foregroundColor(darkBlue)
                
                Text(viewModel.phase.rawValue.capitalized)
                    .font(.title2)
                    .foregroundColor(darkBlue.opacity(0.7))
            }
        }
        .frame(width: 220, height: 220)
        .padding(10)
    }
    
    private var startButton: some View {
        VStack(spacing: 8) {
            Button(action: {
                handleTimerButtonPress()
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
    
    // MARK: - Tag Input Overlay
    private var tagInputOverlay: some View {
        Group {
            if showTagInput {
                ZStack {
                    // Semi-transparent background
                    Color.black.opacity(0.3)
                        .onTapGesture {
                            hideTagInput()
                        }
                    
                    VStack(spacing: 16) {
                        Text("Enter a tag for this session")
                            .font(.headline)
                            .foregroundColor(darkBlue)
                        
                        TagInputTextField(
                            text: $tagInputText,
                            onCommit: {
                                startTimerWithTag()
                            },
                            onCancel: {
                                hideTagInput()
                            }
                        )
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .frame(maxWidth: 200)
                        
                        Text("Press ENTER to start timer")
                            .font(.caption)
                            .foregroundColor(darkBlue.opacity(0.7))
                    }
                    .padding(20)
                    .background(offWhite)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
            }
        }
    }
    
    private func hideTagInput() {
        showTagInput = false
        tagInputText = ""
        
        // Restore first responder to key listener after hiding tag input
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Find the KeyEventListenerView's NSView and make it first responder
            if let window = NSApp.keyWindow {
                window.makeFirstResponder(nil) // Clear current first responder
                // The KeyEventListenerView will re-establish itself as first responder
            }
        }
    }
    
    private func handleTimerButtonPress() {
        if showTagInput {
            // Ignore if tag input is already showing
            return
        }
        
        if viewModel.isActive {
            // Timer is running, pause it
            viewModel.pause()
        } else {
            // Check if the next phase will be a focus session
            if willStartFocusSession() {
                // Show tag input for focus sessions
                showTagInput = true
                tagInputText = ""
            } else {
                // Start break sessions directly without tag input
                viewModel.start()
            }
        }
    }
    
    private func willStartFocusSession() -> Bool {
        print("Current phase: \(viewModel.phase), isActive: \(viewModel.isActive)")
        
        // If currently idle, the next phase will always be focus
        if viewModel.phase == .idle {
            print("Will start focus session (from idle)")
            return true
        }
        
        // If we're about to start a break session (timer is paused and we're in break phase)
        if (viewModel.phase == .shortBreak || viewModel.phase == .longBreak) && !viewModel.isActive {
            print("Will start break session (timer paused in break phase)")
            return false
        }
        
        // If we're in a break and timer is active, this shouldn't happen but handle it
        if viewModel.phase == .shortBreak || viewModel.phase == .longBreak {
            print("Will start focus session (after break)")
            return true
        }
        
        // If currently in focus, the next phase will be a break
        print("Will start break session (from focus)")
        return false
    }
    
    private func startTimerWithTag() {
        print("startTimerWithTag called with tag: '\(tagInputText)'")
        viewModel.currentTag = tagInputText
        hideTagInput()
        viewModel.start()
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

// MARK: - Custom TextField that passes through spacebar
struct SpacePassThroughTextField: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = CustomTextField()
        textField.stringValue = text
        textField.placeholderString = ""
        textField.delegate = context.coordinator
        textField.textColor = NSColor.black
        textField.backgroundColor = NSColor.clear
        textField.isBordered = false
        textField.focusRingType = .none
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: SpacePassThroughTextField
        
        init(_ parent: SpacePassThroughTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
    }
    
    class CustomTextField: NSTextField {
        override func keyDown(with event: NSEvent) {
            if event.keyCode == 49 { // Space bar
                // Pass spacebar events to the next responder (background handler)
                nextResponder?.keyDown(with: event)
            } else {
                super.keyDown(with: event)
            }
        }
    }
}

// MARK: - Tag Input TextField
struct TagInputTextField: NSViewRepresentable {
    @Binding var text: String
    let onCommit: () -> Void
    let onCancel: () -> Void
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = TagInputNSTextField()
        textField.stringValue = text
        textField.placeholderString = "#project-name"
        textField.onCommit = onCommit
        textField.onCancel = onCancel
        textField.delegate = context.coordinator
        textField.textColor = NSColor.black
        textField.backgroundColor = NSColor.clear
        textField.isBordered = false
        textField.focusRingType = .none
        
        // Auto-focus when created
        DispatchQueue.main.async {
            textField.window?.makeFirstResponder(textField)
        }
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: TagInputTextField
        
        init(_ parent: TagInputTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            print("doCommandBy selector: \(commandSelector)")
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                print("Enter key detected via delegate")
                parent.onCommit()
                return true
            } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                print("Escape key detected via delegate")
                parent.onCancel()
                return true
            }
            return false
        }
    }
    
    class TagInputNSTextField: NSTextField {
        var onCommit: (() -> Void)?
        var onCancel: (() -> Void)?
        
        override func keyDown(with event: NSEvent) {
            if event.keyCode == 49 { // Space bar - pass through to background
                nextResponder?.keyDown(with: event)
            } else {
                super.keyDown(with: event)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PomodoroViewModel())
    }
}
