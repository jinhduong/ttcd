import SwiftUI

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - UI Constants (matching ContentView)
    private let offWhite = Color(red: 0.96, green: 0.96, blue: 0.95)
    private let darkBlue = Color(red: 0.1, green: 0.2, blue: 0.3)
    private let teal = Color(red: 0.3, green: 0.6, blue: 0.6)
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Your Stats")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(darkBlue)
                
                Spacer()
                
                Button(action: { viewModel.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(darkBlue.opacity(0.8))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
            }
            
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else {
                statsContent
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(offWhite)
        .onAppear {
            viewModel.loadStats()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: teal))
            
            Text("Loading your stats...")
                .font(.subheadline)
                .foregroundColor(darkBlue.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(darkBlue.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                viewModel.refresh()
            }
            .buttonStyle(.borderedProminent)
            .tint(teal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Stats Content
    private var statsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Total Focus Time
                statCard(
                    title: "Total Focus Time",
                    value: viewModel.stats.formattedTotalTime,
                    icon: "clock.fill",
                    color: teal
                )
                
                // Sessions Overview
                HStack(spacing: 12) {
                    statCard(
                        title: "Total Sessions",
                        value: "\(viewModel.stats.totalSessions)",
                        icon: "number.circle.fill",
                        color: darkBlue,
                        isCompact: true
                    )
                    
                    statCard(
                        title: "Avg Session",
                        value: viewModel.stats.formattedAverageSession,
                        icon: "timer",
                        color: darkBlue,
                        isCompact: true
                    )
                }
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                        .foregroundColor(darkBlue)
                    
                    HStack(spacing: 16) {
                        activityItem(
                            period: "Today",
                            count: viewModel.stats.sessionsToday,
                            color: teal
                        )
                        
                        activityItem(
                            period: "This Week",
                            count: viewModel.stats.sessionsThisWeek,
                            color: darkBlue
                        )
                        
                        activityItem(
                            period: "This Month",
                            count: viewModel.stats.sessionsThisMonth,
                            color: darkBlue.opacity(0.8)
                        )
                    }
                }
                .padding()
                .background(Color.white.opacity(0.7))
                .cornerRadius(10)
                
                // Streaks
                HStack(spacing: 12) {
                    statCard(
                        title: "Current Streak",
                        value: "\(viewModel.stats.currentStreak) days",
                        icon: "flame.fill",
                        color: .orange,
                        isCompact: true
                    )
                    
                    statCard(
                        title: "Best Streak",
                        value: "\(viewModel.stats.longestStreak) days",
                        icon: "trophy.fill",
                        color: .yellow,
                        isCompact: true
                    )
                }
                
                // Tag Statistics
                if !viewModel.stats.tagStats.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Focus Tags")
                            .font(.headline)
                            .foregroundColor(darkBlue)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.stats.tagStats, id: \.tag) { tagStat in
                                tagStatRow(tagStat: tagStat)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Stat Card
    private func statCard(
        title: String,
        value: String,
        icon: String,
        color: Color,
        isCompact: Bool = false
    ) -> some View {
        VStack(spacing: isCompact ? 4 : 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: isCompact ? 18 : 24, weight: .bold, design: .rounded))
                .foregroundColor(darkBlue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(darkBlue.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(10)
    }
    
    // MARK: - Activity Item
    private func activityItem(period: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(period)
                .font(.caption)
                .foregroundColor(darkBlue.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Tag Stat Row
    private func tagStatRow(tagStat: TagStats) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(tagStat.tag)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(darkBlue)
                
                Text(tagStat.formattedTime)
                    .font(.caption)
                    .foregroundColor(darkBlue.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(tagStat.sessionCount)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(teal)
                
                Text("sessions")
                    .font(.caption)
                    .foregroundColor(darkBlue.opacity(0.7))
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
} 
