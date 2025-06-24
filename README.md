# ttcd: The Simple, Focused Pomodoro Timer

**ttcd** is a minimalist Pomodoro timer designed for the macOS menu bar. It's built for developers, designers, and anyone who wants to improve their focus without the clutter of complex apps. Stay on task, take meaningful breaks, and keep your session history synced effortlessly.

## Download

You can download the latest version of **ttcd** from the [**GitHub Releases**](https://github.com/jinhduong/ttcd/releases) page.

## Features

-   **Simple & Clean**: Lives in your menu bar, staying out of your way until you need it.
-   **Cloud-Synced Stats**: Your session history is automatically saved, providing insights into your work patterns from anywhere.
-   **Configurable Timers**: Easily adjust the duration for your focus, short break, and long break intervals.
-   **Keyboard First**: Start and stop the timer instantly with the **Space Bar**.
-   **Instant Notifications**: Get a clear notification when it's time to switch tasks.

## Requirements

-   macOS 13.0 or later
-   Xcode 14.0 or later

## Generating the App Icon

Place your 1024×1024 PNG (e.g. a tomato 🍅) at the project root named `AppIcon-1024.png`, then run:

```bash
chmod +x scripts/generate_app_icon.sh
./scripts/generate_app_icon.sh
```

This creates an `Icon.icns` inside `ttcd/Assets.xcassets/AppIcon.appiconset`, which Xcode will use as the app's icon.

## Getting Started

1.  Clone the repository.
2.  Open `ttcd.xcodeproj` in Xcode.
3.  Press `Cmd+R` to build and run.

The app will appear as a 🍅 icon in your macOS menu bar. Click it to start your first focus session!

## Configuration

`ttcd` uses Supabase for storing session history. To keep your API
credentials out of the source code, the app reads them from environment
variables at runtime:

```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_KEY="your-anon-key"
```

You can set these in your shell profile or add them to an `.env` file and
load it with your preferred tool when developing locally.
