import Cocoa
import SwiftUI
import Charts

struct Session: Codable {
    let type: String
    let start_time: Date
    let end_time: Date
}

class HistoryWindowController: NSWindowController {
    static func show() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                              styleMask: [.titled, .closable, .miniaturizable],
                              backing: .buffered,
                              defer: false)
        let controller = HistoryWindowController(window: window)
        controller.window?.center()
        controller.window?.title = "History"
        controller.showWindow(nil)
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        let view = HistoryView()
        let hosting = NSHostingView(rootView: view)
        hosting.frame = window!.contentView!.bounds
        hosting.autoresizingMask = [.width, .height]
        window?.contentView?.addSubview(hosting)
    }
}

struct HistoryView: View {
    struct ChartItem: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }

    var sessions: [Session] {
        let logURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("pomodoro_log.json")
        guard let data = try? Data(contentsOf: logURL),
              let decoded = try? JSONDecoder().decode([Session].self, from: data) else {
            return []
        }
        return decoded.filter { $0.type == "focus" }
    }

    var body: some View {
        let grouped = Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.start_time)
        }
        let items = grouped.map { ChartItem(date: $0.key, count: $0.value.count) }.sorted { $0.date < $1.date }

        return Chart {
            ForEach(items) { item in
                BarMark(
                    x: .value("Date", item.date),
                    y: .value("Sessions", item.count)
                )
            }
        }
        .frame(width: 360, height: 240)
        .padding()
    }
}
