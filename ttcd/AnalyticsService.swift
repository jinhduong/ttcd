import Foundation
import Supabase

class AnalyticsService {
    
    private let fileURL: URL
    private let supabase: SupabaseClient
    
    init() {
        // --- PASTE YOUR CREDENTIALS HERE ---
        let supabaseURL = URL(string: "https://dlfrbzefsnnesrujtsre.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRsZnJiemVmc25uZXNydWp0c3JlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1Njg5NDUsImV4cCI6MjA2NjE0NDk0NX0.Rvs5_NQbwCzo9omkjJhh608BiJjYXusYPxiAkb9FVh4"
        
        self.supabase = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
        
        // Store the log file in the user's home directory.
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        self.fileURL = homeDirectory.appendingPathComponent(".ttcd_sessions.jsonl")
    }
    
    /// Records a completed focus session.
    func record(focusMinutes: Int) {
        let session = FocusSession(
            sessionId: UUID(),
            userId: DeviceIdentifier.getUniqueId(),
            durationMinutes: focusMinutes,
            completedAt: Date()
        )
        
        // Save to a local file for now.
        saveLocally(session: session)
        
        // Send the data to Supabase.
        sendToSupabase(session: session)
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