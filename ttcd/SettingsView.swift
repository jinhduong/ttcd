import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: PomodoroViewModel
    @Environment(\.dismiss) private var dismiss

    // By using local @State, we prevent the main view from re-rendering
    // and dismissing the sheet with every stepper click.
    @State private var localFocusMinutes: Int
    @State private var localShortBreakMinutes: Int
    @State private var localLongBreakMinutes: Int

    // We need a custom initializer to populate our local @State properties
    // from the view model when the view is first created.
    init(viewModel: PomodoroViewModel) {
        _localFocusMinutes = State(initialValue: viewModel.focusMinutes)
        _localShortBreakMinutes = State(initialValue: viewModel.shortBreakMinutes)
        _localLongBreakMinutes = State(initialValue: viewModel.longBreakMinutes)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title)

            Form {
                Stepper("Focus: \(localFocusMinutes) min", value: $localFocusMinutes, in: 1...60)
                Stepper("Short Break: \(localShortBreakMinutes) min", value: $localShortBreakMinutes, in: 1...15)
                Stepper("Long Break: \(localLongBreakMinutes) min", value: $localLongBreakMinutes, in: 5...30)
            }
            .padding()

            Button("Done") {
                // On dismiss, commit the local changes back to the view model.
                viewModel.focusMinutes = localFocusMinutes
                viewModel.shortBreakMinutes = localShortBreakMinutes
                viewModel.longBreakMinutes = localLongBreakMinutes
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(width: 300)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // Pass a view model instance for the preview to work.
        SettingsView(viewModel: PomodoroViewModel())
            .environmentObject(PomodoroViewModel())
    }
} 