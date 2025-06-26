# ttcd - Terminal Timer for Concentrated Development

A minimal Pomodoro timer for macOS that lives in your menu bar.

## Features

- 🍅 **Pomodoro Timer**: 25-minute focus sessions with 5-minute breaks
- 📊 **Session Tracking**: Automatic tracking of completed sessions with tags
- 📈 **Statistics**: View your productivity stats and streaks
- 🔔 **Notifications**: Get notified when sessions complete
- ⌨️ **Keyboard Shortcuts**: Space bar to start/pause, quick access controls
- 🏷️ **Session Tags**: Categorize your focus sessions
- 💾 **Local Storage**: All data stored locally on your machine
- 🌙 **Menu Bar Integration**: Unobtrusive timer display in your menu bar

## Installation

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/ttcd.git
   cd ttcd
   ```

2. Open the project in Xcode:
   ```bash
   open ttcd.xcodeproj
   ```

3. Build and run the project (⌘+R)

### Using the Build Script

For development builds:
```bash
./scripts/build.sh
```

## Data Storage

`ttcd` stores all session data locally on your machine in JSON format. The data is stored in:
```
~/Library/Application Support/ttcd/sessions.json
```

### Data Management

The app includes several data management features:

- **Automatic Cleanup**: Keeps the last 1000 sessions to prevent excessive storage usage
- **Export/Import**: Built-in functions to backup and restore session data
- **Local Only**: No external services or cloud storage required

### Backup Your Data

To backup your session data, you can copy the sessions file:
```bash
cp ~/Library/Application\ Support/ttcd/sessions.json ~/Desktop/ttcd-backup.json
```

## Usage

1. **Start a Session**: Click the 🍅 in your menu bar and press Space or click "Start"
2. **Add Tags**: Type in the tag field to categorize your session
3. **View Stats**: Click "Stats" to see your productivity metrics
4. **Customize Settings**: Adjust timer durations and preferences

### Keyboard Shortcuts

- **Space**: Start/pause the current timer
- **R**: Reset the current timer

## Configuration

The app uses sensible defaults but can be customized:

- **Focus Duration**: Default 25 minutes
- **Short Break**: Default 5 minutes  
- **Long Break**: Default 15 minutes
- **Long Break Interval**: Every 4 sessions

## Development

### Project Structure

```
ttcd/
├── ttcd/                   # Main app source
│   ├── ttcdApp.swift      # App entry point
│   ├── ContentView.swift  # Main UI
│   ├── PomodoroViewModel.swift # Timer logic
│   ├── AnalyticsService.swift  # Local data storage
│   ├── NotificationService.swift # Notifications
│   └── ...
├── scripts/               # Build and utility scripts
└── docs/                 # Documentation and screenshots
```

### Building

Requirements:
- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

### Testing

Run tests with:
```bash
xcodebuild test -scheme ttcd
```

## Privacy

ttcd is designed with privacy in mind:
- All data stays on your local machine
- No telemetry or analytics sent to external servers
- No account creation or sign-up required
- Session data is stored in standard JSON format for transparency

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

If you encounter issues or have feature requests, please open an issue on GitHub.
