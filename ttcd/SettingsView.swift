import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: PomodoroViewModel

    // MARK: - UI Constants
    private let offWhite = Color(red: 0.96, green: 0.96, blue: 0.95)
    private let darkBlue = Color(red: 0.1, green: 0.2, blue: 0.3)
    private let teal = Color(red: 0.3, green: 0.6, blue: 0.6)

    var body: some View {
        VStack(spacing: 20) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    settingCard(
                        title: "Focus",
                        value: $viewModel.focusMinutes,
                        range: 1...60,
                        icon: "brain.head.profile",
                        color: teal
                    )
                    
                    settingCard(
                        title: "Short Break",
                        value: $viewModel.shortBreakMinutes,
                        range: 1...20,
                        icon: "cup.and.saucer.fill",
                        color: darkBlue
                    )
                    
                    settingCard(
                        title: "Long Break",
                        value: $viewModel.longBreakMinutes,
                        range: 1...60,
                        icon: "bed.double",
                        color: .blue
                    )
                    
                    longBreakIntervalCard(
                        title: "Long Break After",
                        value: $viewModel.longBreakInterval,
                        range: 2...8,
                        icon: "repeat.circle.fill",
                        color: .orange
                    )
                }
                .padding()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(offWhite)
    }

    private var header: some View {
        HStack {
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(darkBlue)
            
            Spacer()
        }
    }

    private func settingCard(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(darkBlue)
                
                Spacer()
            }
            
            HStack {
                Text("\(value.wrappedValue) minutes")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(darkBlue)
                
                Spacer()
                
                Stepper("Duration", value: value, in: range)
                    .labelsHidden()
                    .tint(darkBlue)
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(10)
    }
    
    private func longBreakIntervalCard(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(darkBlue)
                
                Spacer()
            }
            
            HStack {
                Text("\(value.wrappedValue) sessions")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(darkBlue)
                
                Spacer()
                
                Stepper("Sessions", value: value, in: range)
                    .labelsHidden()
                    .tint(darkBlue)
            }
            
            Text("Take a long break after every \(value.wrappedValue) focus sessions")
                .font(.caption)
                .foregroundColor(darkBlue.opacity(0.6))
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(10)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(PomodoroViewModel())
    }
} 