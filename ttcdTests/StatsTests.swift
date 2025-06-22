import XCTest
@testable import ttcd

final class StatsTests: XCTestCase {
    
    func testUserStatsEmptyState() {
        let stats = UserStats.empty
        
        XCTAssertEqual(stats.totalSessions, 0)
        XCTAssertEqual(stats.totalFocusMinutes, 0)
        XCTAssertEqual(stats.averageSessionLength, 0)
        XCTAssertEqual(stats.sessionsToday, 0)
        XCTAssertEqual(stats.sessionsThisWeek, 0)
        XCTAssertEqual(stats.sessionsThisMonth, 0)
        XCTAssertEqual(stats.longestStreak, 0)
        XCTAssertEqual(stats.currentStreak, 0)
        XCTAssertEqual(stats.formattedTotalTime, "0m")
        XCTAssertEqual(stats.formattedAverageSession, "0m")
    }
    
    func testUserStatsFormattedValues() {
        let stats = UserStats(
            totalSessions: 10,
            totalFocusMinutes: 125,
            averageSessionLength: 12.5,
            sessionsToday: 2,
            sessionsThisWeek: 5,
            sessionsThisMonth: 8,
            longestStreak: 7,
            currentStreak: 3
        )
        
        XCTAssertEqual(stats.formattedTotalTime, "2h 5m")
        XCTAssertEqual(stats.formattedAverageSession, "12m")
    }
    
    func testUserStatsMinutesOnly() {
        let stats = UserStats(
            totalSessions: 5,
            totalFocusMinutes: 45,
            averageSessionLength: 9.0,
            sessionsToday: 1,
            sessionsThisWeek: 3,
            sessionsThisMonth: 4,
            longestStreak: 2,
            currentStreak: 1
        )
        
        XCTAssertEqual(stats.formattedTotalTime, "45m")
        XCTAssertEqual(stats.formattedAverageSession, "9m")
    }
} 