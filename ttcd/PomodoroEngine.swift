import Foundation

/// Defines the different states or phases of the Pomodoro timer.
enum PomodoroPhase: String, Codable {
    case focus
    case shortBreak
    case longBreak
    case idle
}

/// A pure-logic, testable struct that manages the Pomodoro cycle.
struct PomodoroEngine {
    /// The current phase of the Pomodoro cycle.
    var phase: PomodoroPhase = .idle

    /// The number of completed focus sessions, used to determine when to take a long break.
    var sessionCount: Int = 0

    /// Calculates the duration for a given phase based on user settings.
    ///
    /// - Parameters:
    ///   - phase: The phase for which to get the duration.
    ///   - settings: The user's configured settings for durations.
    /// - Returns: The duration of the phase in seconds.
    func duration(for phase: PomodoroPhase, settings: Settings) -> TimeInterval {
        switch phase {
        case .focus:
            return TimeInterval(settings.focusMinutes * 60)
        case .shortBreak:
            return TimeInterval(settings.shortBreakMinutes * 60)
        case .longBreak:
            return TimeInterval(settings.longBreakMinutes * 60)
        case .idle:
            return 0
        }
    }

    /// Determines the next phase in the Pomodoro cycle.
    ///
    /// The cycle is: Focus -> Short Break, repeated. After a set number of focus sessions,
    /// a Long Break is initiated.
    ///
    /// - Returns: A tuple containing the next phase and the updated session count.
    mutating func nextPhase() -> (phase: PomodoroPhase, sessionCount: Int) {
        switch phase {
        case .focus:
            let newSessionCount = sessionCount + 1
            // After 3 short breaks (meaning 4 focus sessions), take a long break.
            if newSessionCount % 4 == 0 {
                phase = .longBreak
            } else {
                phase = .shortBreak
            }
            sessionCount = newSessionCount
        case .shortBreak, .longBreak:
            phase = .focus
        case .idle:
            phase = .focus
        }
        return (phase, sessionCount)
    }

    /// Resets the cycle to its initial state.
    mutating func reset() {
        phase = .idle
        sessionCount = 0
    }
}

/// A simple struct to hold user-configurable settings.
/// This could be expanded to include sound preferences, etc.
struct Settings {
    var focusMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int
} 