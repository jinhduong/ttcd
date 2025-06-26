import Foundation

class AnalyticsService {
    
    private let fileURL: URL
    
    init() {
        // Store the log file in the user's Application Support directory for better organization
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportURL.appendingPathComponent("ttcd")
        
        // Create the directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        
        self.fileURL = appDirectory.appendingPathComponent("sessions.json")
        
        #if DEBUG
        print("📁 [DEBUG] Sessions stored at: \(fileURL.path)")
        #endif
    }
    
    /// Records a completed focus session.
    func record(focusMinutes: Int, tag: String?) {
        let session = FocusSession(
            sessionId: UUID(),
            userId: DeviceIdentifier.getUniqueId(),
            durationMinutes: focusMinutes,
            completedAt: Date(),
            tag: tag
        )
        
        // Save to local file
        saveLocally(session: session)
    }
    
    /// Fetches user statistics from local storage
    func fetchUserStats() async -> UserStats {
        let sessions = loadLocalSessions()
        return calculateStats(from: sessions)
    }
    
    /// Loads all sessions from local storage
    private func loadLocalSessions() -> [FocusSession] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let sessions = try decoder.decode([FocusSession].self, from: data)
            return sessions
        } catch {
            print("Error loading local sessions: \(error)")
            return []
        }
    }
    
    /// Saves a session to local storage
    private func saveLocally(session: FocusSession) {
        var sessions = loadLocalSessions()
        sessions.append(session)
        
        // Keep only the last 1000 sessions to prevent the file from growing too large
        if sessions.count > 1000 {
            sessions = Array(sessions.suffix(1000))
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(sessions)
            try data.write(to: fileURL)
            
            #if DEBUG
            print("💾 Session saved locally. Total sessions: \(sessions.count)")
            #endif
        } catch {
            print("Error saving session locally: \(error)")
        }
    }
    
    /// Calculates user statistics from session data
    private func calculateStats(from sessions: [FocusSession]) -> UserStats {
        guard !sessions.isEmpty else { return UserStats.empty }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate date ranges
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        // Filter sessions by time periods
        let sessionsToday = sessions.filter { $0.completedAt >= startOfToday }
        let sessionsThisWeek = sessions.filter { $0.completedAt >= startOfWeek }
        let sessionsThisMonth = sessions.filter { $0.completedAt >= startOfMonth }
        
        // Calculate totals
        let totalSessions = sessions.count
        let totalFocusMinutes = sessions.reduce(0) { $0 + $1.durationMinutes }
        let averageSessionLength = totalSessions > 0 ? Double(totalFocusMinutes) / Double(totalSessions) : 0
        
        // Calculate streaks
        let (longestStreak, currentStreak) = calculateStreaks(from: sessions)
        
        // Calculate tag statistics
        let tagStats = calculateTagStats(from: sessions)
        
        return UserStats(
            totalSessions: totalSessions,
            totalFocusMinutes: totalFocusMinutes,
            averageSessionLength: averageSessionLength,
            sessionsToday: sessionsToday.count,
            sessionsThisWeek: sessionsThisWeek.count,
            sessionsThisMonth: sessionsThisMonth.count,
            longestStreak: longestStreak,
            currentStreak: currentStreak,
            tagStats: tagStats
        )
    }
    
    /// Calculates the longest and current streaks from session data
    private func calculateStreaks(from sessions: [FocusSession]) -> (longest: Int, current: Int) {
        guard !sessions.isEmpty else { return (0, 0) }
        
        let calendar = Calendar.current
        let sortedSessions = sessions.sorted { $0.completedAt < $1.completedAt }
        
        // Group sessions by day
        var sessionsByDay: [Date: [FocusSession]] = [:]
        for session in sortedSessions {
            let day = calendar.startOfDay(for: session.completedAt)
            sessionsByDay[day, default: []].append(session)
        }
        
        let daysWithSessions = sessionsByDay.keys.sorted()
        
        var currentStreak = 0
        var maxStreak = 0
        var tempStreak = 0
        
        for i in 0..<daysWithSessions.count {
            let currentDay = daysWithSessions[i]
            
            if i == 0 {
                tempStreak = 1
            } else {
                let previousDay = daysWithSessions[i - 1]
                let daysBetween = calendar.dateComponents([.day], from: previousDay, to: currentDay).day ?? 0
                
                if daysBetween == 1 {
                    // Consecutive day
                    tempStreak += 1
                } else {
                    // Gap in streak
                    maxStreak = max(maxStreak, tempStreak)
                    tempStreak = 1
                }
            }
        }
        
        // Update max streak with the final temp streak
        maxStreak = max(maxStreak, tempStreak)
        
        // Calculate current streak (from today backwards)
        let today = calendar.startOfDay(for: Date())
        var checkDate = today
        
        while sessionsByDay[checkDate] != nil {
            currentStreak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        return (maxStreak, currentStreak)
    }
    
    /// Calculates tag statistics from session data
    private func calculateTagStats(from sessions: [FocusSession]) -> [TagStats] {
        var tagCounts: [String: (sessionCount: Int, totalMinutes: Int)] = [:]
        
        for session in sessions {
            let tag = session.tag?.isEmpty == false ? session.tag! : "No Tag"
            
            if let existing = tagCounts[tag] {
                tagCounts[tag] = (
                    sessionCount: existing.sessionCount + 1,
                    totalMinutes: existing.totalMinutes + session.durationMinutes
                )
            } else {
                tagCounts[tag] = (sessionCount: 1, totalMinutes: session.durationMinutes)
            }
        }
        
        return tagCounts.map { tag, stats in
            TagStats(tag: tag, sessionCount: stats.sessionCount, totalMinutes: stats.totalMinutes)
        }.sorted { $0.sessionCount > $1.sessionCount }
    }
    
    /// Exports all session data as JSON (useful for backup)
    func exportSessionsData() -> Data? {
        let sessions = loadLocalSessions()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(sessions)
    }
    
    /// Imports session data from JSON (useful for restore)
    func importSessionsData(_ data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importedSessions = try decoder.decode([FocusSession].self, from: data)
            
            // Merge with existing sessions and remove duplicates
            var existingSessions = loadLocalSessions()
            let existingIds = Set(existingSessions.map { $0.sessionId })
            
            let newSessions = importedSessions.filter { !existingIds.contains($0.sessionId) }
            existingSessions.append(contentsOf: newSessions)
            
            // Sort by completion date
            existingSessions.sort { $0.completedAt < $1.completedAt }
            
            // Save merged data
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let mergedData = try encoder.encode(existingSessions)
            try mergedData.write(to: fileURL)
            
            print("Successfully imported \(newSessions.count) new sessions")
            return true
        } catch {
            print("Error importing sessions: \(error)")
            return false
        }
    }
    
    /// Clears all local session data (useful for testing or reset)
    func clearAllData() {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("All session data cleared")
            }
        } catch {
            print("Error clearing data: \(error)")
        }
    }
} 