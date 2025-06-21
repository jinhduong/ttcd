# ttcd
A macOS menu bar Pomodoro timer written in Swift. The app provides configurable focus and break durations, logs each completed session to `pomodoro_log.json` in your home directory and can display a history chart of focus sessions.

## Requirements
- macOS 13+
- Xcode 14+

The project uses Swift Package Manager and the [swift-charts](https://github.com/apple/swift-charts) package.

## Building
Open the project in Xcode with:

```bash
open Package.swift
```

Build and run the `PomodoroMenuBar` target. When running, the app lives in the macOS status bar.

## Usage
Use the status bar menu to start focus or break timers. When a timer completes a notification is displayed and a record is appended to `pomodoro_log.json`. Select **Show History** from the menu to display a chart of focus sessions per day.
