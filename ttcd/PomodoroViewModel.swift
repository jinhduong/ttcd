import Foundation
import SwiftUI
import Combine
import AppKit // Using AppKit for NSSound

class PomodoroViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var phase: PomodoroPhase = .idle
    @Published var timeRemaining: TimeInterval = 0
    @Published var isActive: Bool = false
    @Published var shake: Int = 0
    @Published var currentTag: String = ""

    // MARK: - AppStorage for Persistence
    @AppStorage("focusMinutes") var focusMinutes: Int = 25
    @AppStorage("shortBreakMinutes") var shortBreakMinutes: Int = 5
    @AppStorage("longBreakMinutes") var longBreakMinutes: Int = 15
    @AppStorage("longBreakInterval") var longBreakInterval: Int = 4
    
    // State persistence
    @AppStorage("sessionCount") private var sessionCount: Int = 0
    @AppStorage("phaseOnExit") private var phaseOnExitRaw: String = PomodoroPhase.idle.rawValue
    @AppStorage("timeRemainingOnExit") private var timeRemainingOnExit: TimeInterval = 0
    @AppStorage("exitTime") private var exitTime: TimeInterval = 0
    
    // MARK: - Private Properties
    private var engine = PomodoroEngine()
    private var timerSubscription: AnyCancellable?
    private let analyticsService = AnalyticsService()

    var totalDuration: TimeInterval {
        engine.duration(for: phase, settings: settings)
    }

    var settings: Settings {
        Settings(focusMinutes: focusMinutes, shortBreakMinutes: shortBreakMinutes, longBreakMinutes: longBreakMinutes, longBreakInterval: longBreakInterval)
    }

    var menuBarTitle: String {
        if phase == .idle {
            return "🍅"
        } else {
            return formattedTime
        }
    }
    
    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init() {
        self.engine.sessionCount = self.sessionCount
        restoreTimerState()
        
        // This notification is a reliable way to save state before the app quits.
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: NSApplication.willTerminateNotification, object: nil)
    }

    // MARK: - Timer Control
    func toggleTimer() {
        if isActive {
            pause()
        } else {
            start()
        }
    }

func start() {
        if phase == .idle {
            // Start the first focus session
            let (nextPhase, newSessionCount) = engine.nextPhase(settings: settings)
            self.phase = nextPhase
            self.sessionCount = newSessionCount
            self.timeRemaining = engine.duration(for: self.phase, settings: settings)
        }
        
        guard phase != .idle else { return }
        
        isActive = true
        
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        isActive = false
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    func reset() {
        pause()
        engine.reset()
        phase = .idle
        sessionCount = 0
        timeRemaining = 0
        currentTag = ""
    }

    // MARK: - State Persistence
    
    /// Saves the current timer state to AppStorage just before the app quits.
    @objc func appWillTerminate() {
        if isActive {
            phaseOnExitRaw = phase.rawValue
            timeRemainingOnExit = timeRemaining
            exitTime = Date().timeIntervalSince1970
        } else {
            // Mark as idle so we don't try to restore next time
            phaseOnExitRaw = PomodoroPhase.idle.rawValue
            timeRemainingOnExit = 0
            exitTime = 0
        }
    }

    /// Restores the timer state after the app has been quit and reopened.
    private func restoreTimerState() {
        let phaseOnExit = PomodoroPhase(rawValue: phaseOnExitRaw) ?? .idle
        
        guard phaseOnExit != .idle, exitTime > 0 else {
            self.phase = .idle
            return
        }
        
        let timePassed = Date().timeIntervalSince1970 - exitTime
        let newTimeRemaining = timeRemainingOnExit - timePassed
        
        self.phase = phaseOnExit
        self.engine.phase = phaseOnExit

        if newTimeRemaining > 0 {
            // The timer was running and still has time left.
            self.timeRemaining = newTimeRemaining
        } else {
            // The timer finished while the app was closed.
            // Advance to the next phase but leave it paused.
            let (nextPhase, newSessionCount) = engine.nextPhase(settings: settings)
            self.phase = nextPhase
            self.sessionCount = newSessionCount
            self.timeRemaining = engine.duration(for: self.phase, settings: settings)
        }
        
        // Clear the saved state so it's not reused on next launch
        self.exitTime = 0
    }


    // MARK: - Private Helpers
    private func tick() {
        guard timeRemaining > 1 else {
            timeRemaining = 0
            advanceToNextPhase()
            return
        }
        timeRemaining -= 1
    }

    private func advanceToNextPhase() {
        // Record the event if the completed phase was a focus session.
        if self.phase == .focus {
            analyticsService.record(focusMinutes: self.focusMinutes, tag: self.currentTag)
            
            // Clear the tag for the next session
            DispatchQueue.main.async {
                self.currentTag = ""
            }
        }
        
        // Play sound and shake just before changing the phase
        playSound()
        triggerShake()

        let (nextPhase, newSessionCount) = engine.nextPhase(settings: settings)
        self.phase = nextPhase
        self.sessionCount = newSessionCount
        self.timeRemaining = engine.duration(for: self.phase, settings: settings)
        
        // After advancing, pause the timer and wait for the user to explicitly start the next phase.
        pause()
    }

    private func playSound() {
        // Use NSSound for a more reliable way to play system sounds.
        NSSound(named: "Glass")?.play()
    }
    
    private func triggerShake() {
        withAnimation(.default) {
            shake += 1
        }
    }
} 
