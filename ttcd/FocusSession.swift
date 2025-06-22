import Foundation

struct FocusSession: Codable {
    let sessionId: UUID
    let userId: String
    let durationMinutes: Int
    let completedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case userId = "user_id"
        case durationMinutes = "duration_minutes"
        case completedAt = "completed_at"
    }
} 