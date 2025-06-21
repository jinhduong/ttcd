import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var endDate: Date?

    let focusDurationKey = "focusDuration"
    let shortBreakKey = "shortBreakDuration"
    let longBreakKey = "longBreakDuration"

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "Pomodoro"
        constructMenu()
    }

    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Start Focus", action: #selector(startFocus), keyEquivalent: "f"))
        menu.addItem(NSMenuItem(title: "Start Short Break", action: #selector(startShortBreak), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Start Long Break", action: #selector(startLongBreak), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "Stop", action: #selector(stopTimer), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Show History", action: #selector(showHistory), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    // MARK: - Actions
    @objc func startFocus() { startTimer(type: "focus", minutes: UserDefaults.standard.integer(forKey: focusDurationKey, default: 25)) }
    @objc func startShortBreak() { startTimer(type: "short_break", minutes: UserDefaults.standard.integer(forKey: shortBreakKey, default: 5)) }
    @objc func startLongBreak() { startTimer(type: "long_break", minutes: UserDefaults.standard.integer(forKey: longBreakKey, default: 15)) }

    func startTimer(type: String, minutes: Int) {
        endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick(type: type)
        }
    }

    func tick(type: String) {
        guard let end = endDate else { return }
        let remaining = Int(end.timeIntervalSinceNow)
        if remaining <= 0 {
            stopTimer()
            logSession(type: type, start: Date(timeInterval: -TimeInterval(Int(end.timeIntervalSinceNow)), since: end), end: Date())
            showNotification(title: "Timer", text: "\(type.replacingOccurrences(of: "_", with: " ").capitalized) completed")
        } else {
            let minutes = remaining / 60
            let seconds = remaining % 60
            statusItem.button?.title = String(format: "%02d:%02d", minutes, seconds)
        }
    }

    @objc func stopTimer() {
        timer?.invalidate()
        timer = nil
        statusItem.button?.title = "Pomodoro"
    }

    func logSession(type: String, start: Date, end: Date) {
        let logURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("pomodoro_log.json")
        var data: [[String: String]] = []
        if let existing = try? Data(contentsOf: logURL) {
            if let decoded = try? JSONSerialization.jsonObject(with: existing) as? [[String: String]] {
                data = decoded
            }
        }
        let formatter = ISO8601DateFormatter()
        data.append([
            "type": type,
            "start_time": formatter.string(from: start),
            "end_time": formatter.string(from: end)
        ])
        if let output = try? JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted]) {
            try? output.write(to: logURL)
        }
    }

    @objc func showHistory() {
        HistoryWindowController.show()
    }

    func showNotification(title: String, text: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = text
        NSUserNotificationCenter.default.deliver(notification)
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

extension UserDefaults {
    func integer(forKey key: String, default defaultValue: Int) -> Int {
        let value = integer(forKey: key)
        return value == 0 ? defaultValue : value
    }
}
