import Foundation
import SwiftUI

@MainActor
class StatsViewModel: ObservableObject {
    @Published var stats: UserStats = UserStats.empty
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let analyticsService = AnalyticsService()
    
    /// Loads user statistics from local storage
    func loadStats() {
        Task {
            isLoading = true
            errorMessage = nil
            
            let fetchedStats = await analyticsService.fetchUserStats()
            self.stats = fetchedStats
            self.isLoading = false
        }
    }
    
    /// Refreshes the statistics
    func refresh() {
        loadStats()
    }
} 