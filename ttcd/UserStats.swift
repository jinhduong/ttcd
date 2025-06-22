import Foundation

struct TagStats: Codable {
    let tag: String
    let sessionCount: Int
    let totalMinutes: Int
    
    var formattedTime: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct UserStats: Codable {
    let totalSessions: Int
    let totalFocusMinutes: Int
    let averageSessionLength: Double
    let sessionsToday: Int
    let sessionsThisWeek: Int
    let sessionsThisMonth: Int
    let longestStreak: Int
    let currentStreak: Int
    let tagStats: [TagStats]
    
    // Computed properties for display
    var totalFocusHours: Int {
        totalFocusMinutes / 60
    }
    
    var totalFocusMinutesRemainder: Int {
        totalFocusMinutes % 60
    }
    
    var formattedTotalTime: String {
        if totalFocusHours > 0 {
            return "\(totalFocusHours)h \(totalFocusMinutesRemainder)m"
        } else {
            return "\(totalFocusMinutes)m"
        }
    }
    
    var formattedAverageSession: String {
        let minutes = Int(averageSessionLength)
        return "\(minutes)m"
    }
    
    // Default empty stats
    static let empty = UserStats(
        totalSessions: 0,
        totalFocusMinutes: 0,
        averageSessionLength: 0,
        sessionsToday: 0,
        sessionsThisWeek: 0,
        sessionsThisMonth: 0,
        longestStreak: 0,
        currentStreak: 0,
        tagStats: []
    )
} 