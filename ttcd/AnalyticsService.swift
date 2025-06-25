import Foundation
import Supabase

class AnalyticsService {
    
    private let fileURL: URL
    private let supabase: SupabaseClient
    
    init() {
        let env = ProcessInfo.processInfo.environment
        
        // Try to get from environment variables first
        var urlString: String?
        var key: String?
        
        if let envUrl = env["SUPABASE_URL"], let envKey = env["SUPABASE_KEY"] {
            urlString = envUrl
            key = envKey
        } else {
            // Fallback to Info.plist configuration
            if let infoPlist = Bundle.main.infoDictionary {
                urlString = infoPlist["SUPABASE_URL"] as? String
                key = infoPlist["SUPABASE_KEY"] as? String
            }
        }

        guard
            let finalUrlString = urlString,
            let finalKey = key,
            let supabaseURL = URL(string: finalUrlString)
        else {
            fatalError("SUPABASE_URL and SUPABASE_KEY must be set in environment variables or Info.plist")
        }

        self.supabase = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: finalKey)
        
        // Store the log file in the user's home directory.
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        self.fileURL = homeDirectory.appendingPathComponent(".ttcd_sessions.jsonl")
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
        
        // Save to a local file for now.
        saveLocally(session: session)
        
        // Send the data to Supabase.
        sendToSupabase(session: session)
    }
    
    /// Fetches user statistics from Supabase
    func fetchUserStats() async -> UserStats {
        let userId = DeviceIdentifier.getUniqueId()
        
        do {
            // Fetch all sessions for the user
            let response: [FocusSession] = try await supabase
                .from("focus_sessions")
                .select()
                .eq("user_id", value: userId)
                .order("completed_at", ascending: false)
                .execute()
                .value
            
            return calculateStats(from: response)
            
        } catch {
            print("Error fetching stats from Supabase: \(error)")
            return UserStats.empty
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
        
        var currentStreak = 0
        var maxStreak = 0
        
        var currentDate: Date?
        
        for session in sortedSessions {
            let sessionDate = calendar.startOfDay(for: session.completedAt)
            
            if let current = currentDate {
                let daysBetween = calendar.dateComponents([.day], from: current, to: sessionDate).day ?? 0
                
                if daysBetween == 1 {
                    // Consecutive day
                    currentStreak += 1
                } else if daysBetween == 0 {
                    // Same day, don't increment streak
                    continue
                } else {
                    // Gap in streak
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                // First session
                currentStreak = 1
            }
            
            currentDate = sessionDate
        }
        
        // Check if current streak is the longest
        maxStreak = max(maxStreak, currentStreak)
        
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
    
    private func saveLocally(session: FocusSession) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(session) else { return }
        
        // Append the new session as a new line in the file.
        if let dataWithNewline = (String(data: data, encoding: .utf8)! + "\n").data(using: .utf8) {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(dataWithNewline)
                    fileHandle.closeFile()
                }
            } else {
                try? dataWithNewline.write(to: fileURL)
            }
        }
    }
    
    private func sendToSupabase(session: FocusSession) {
        Task {
            do {
                try await supabase
                    .from("focus_sessions")
                    .insert(session)
                    .execute()
                print("Successfully saved session to Supabase.")
            } catch {
                print("Error saving to Supabase: \(error)")
            }
        }
    }
} 