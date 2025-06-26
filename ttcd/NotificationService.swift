import Foundation
import AppKit
import UserNotifications

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    private var permissionGranted = false
    private var notificationCount = 0
    
    override init() {
        super.init()
        setupNotifications()
    }
    
    private func setupNotifications() {
        // Set delegate to handle notification responses
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions with completion
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                if granted {
                    print("🔔 Notification permission granted")
                } else {
                    print("🔔 Notification permission denied")
                    if let error = error {
                        print("🔔 Notification permission error: \(error)")
                    }
                }
            }
        }
        
        // Check current permission status
        checkNotificationPermission()
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                print("🔔 Current notification status: \(settings.authorizationStatus.rawValue)")
                self?.permissionGranted = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                
                if settings.authorizationStatus == .denied {
                    print("🔔 Notifications are denied. User needs to enable them in System Preferences.")
                }
            }
        }
    }
    
    /// Manually request notification permissions (useful for troubleshooting)
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                if granted {
                    print("🔔 Notification permission granted after manual request")
                } else {
                    print("🔔 Notification permission still denied after manual request")
                    if let error = error {
                        print("🔔 Error: \(error)")
                    }
                    
                    // Show alert to guide user to system preferences
                    let alert = NSAlert()
                    alert.messageText = "Notifications Disabled"
                    alert.informativeText = "To receive timer completion notifications, please enable notifications for ttcd in System Preferences > Notifications & Focus."
                    alert.addButton(withTitle: "Open System Preferences")
                    alert.addButton(withTitle: "Cancel")
                    
                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn {
                        // Open System Preferences to Notifications
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
    }
    
    /// Test notification (useful for debugging)
    func showTestNotification() {
        print("🔔 Showing test notification...")
        
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Notification"
        content.body = "This is a test notification from ttcd."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "test-notification-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("🔔 Test notification failed: \(error)")
            } else {
                print("🔔 Test notification sent successfully")
            }
        }
    }

    /// Shows a prominent popup alert to get the user's attention
    func showSessionCompletePopup(completedPhase: PomodoroPhase, nextPhase: PomodoroPhase) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            
            // Configure alert based on completed phase
            switch completedPhase {
            case .focus:
                alert.messageText = "🎉 Focus Session Complete!"
                alert.informativeText = "Great work! You completed a \(self.formatPhase(completedPhase)) session.\n\nTime for a \(self.formatPhase(nextPhase))."
                alert.icon = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "Focus Complete")
                
            case .shortBreak, .longBreak:
                alert.messageText = "⏰ Break Time's Up!"
                alert.informativeText = "Your \(self.formatPhase(completedPhase)) is over.\n\nReady to start a \(self.formatPhase(nextPhase))?"
                alert.icon = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Break Complete")
                
            case .idle:
                return // Don't show popup for idle state
            }
            
            // Add buttons
            alert.addButton(withTitle: "Start Next Session")
            alert.addButton(withTitle: "Not Now")
            
            // Style the alert
            alert.alertStyle = .informational
            
            // Show the alert and bring app to front
            NSApp.activate(ignoringOtherApps: true)
            let response = alert.runModal()
            
            // Handle user response
            if response == .alertFirstButtonReturn {
                // User clicked "Start Next Session"
                NotificationCenter.default.post(name: .startNextSession, object: nil)
            }
            // If user clicks "Not Now" or closes, do nothing (timer stays paused)
        }
    }
    
    /// Shows a system notification (for when app is in background)
    func showSystemNotification(completedPhase: PomodoroPhase, nextPhase: PomodoroPhase) {
        print("🔔 📢 Attempting to show system notification for \(completedPhase) -> \(nextPhase)")
        
        // Check permission asynchronously to get the most current status
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let hasPermission = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                self.permissionGranted = hasPermission
                
                guard hasPermission else {
                    print("🔔 ❌ Cannot show notification: permission not granted (status: \(settings.authorizationStatus.rawValue))")
                    return
                }
                
                self.notificationCount += 1
                
                // Only clear old ttcd notifications, not all notifications
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    let ttcdRequests = requests.filter { $0.identifier.hasPrefix("ttcd-timer-") }
                    let identifiersToRemove = ttcdRequests.map { $0.identifier }
                    if !identifiersToRemove.isEmpty {
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
                    }
                }
                
                UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                    let ttcdNotifications = notifications.filter { $0.request.identifier.hasPrefix("ttcd-timer-") }
                    let identifiersToRemove = ttcdNotifications.map { $0.request.identifier }
                    if !identifiersToRemove.isEmpty {
                        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
                    }
                }
                
                self.scheduleNotification(completedPhase: completedPhase, nextPhase: nextPhase)
            }
        }
    }
    
    private func scheduleNotification(completedPhase: PomodoroPhase, nextPhase: PomodoroPhase) {
        let content = UNMutableNotificationContent()
        
        switch completedPhase {
        case .focus:
            content.title = "🎉 Focus Session Complete!"
            content.body = "Great work! Time for a \(formatPhase(nextPhase))."
            content.sound = .default
            
        case .shortBreak, .longBreak:
            content.title = "⏰ Break Time's Up!"
            content.body = "Your \(formatPhase(completedPhase)) is over. Ready for a \(formatPhase(nextPhase))?"
            content.sound = .default
            
        case .idle:
            return
        }
        
        // Add action buttons to notification
        let startAction = UNNotificationAction(
            identifier: "START_ACTION",
            title: "Start Next Session",
            options: [.foreground]
        )
        
        let laterAction = UNNotificationAction(
            identifier: "LATER_ACTION", 
            title: "Later",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "TIMER_COMPLETE",
            actions: [startAction, laterAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "TIMER_COMPLETE"
        
        // Use a simpler, more reliable identifier
        let identifier = "ttcd-timer-\(notificationCount)"
        
        // Schedule the notification
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Show immediately
        )
        
        print("🔔 📤 Scheduling notification #\(notificationCount) with ID: \(identifier)")
        print("🔔    Title: \(content.title)")
        print("🔔    Body: \(content.body)")
        
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                print("🔔 ❌ Failed to show system notification: \(error)")
            } else {
                print("🔔 ✅ System notification scheduled successfully")
                
                // Verify it was added
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    print("🔔 📋 Pending notifications after add: \(requests.count)")
                    for req in requests {
                        print("🔔    - \(req.identifier): \(req.content.title)")
                    }
                }
                
                UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                    print("🔔 📨 Delivered notifications: \(notifications.count)")
                }
            }
        }
    }
    
    /// Shows both popup and system notification for maximum visibility
    func showSessionCompleteNotification(completedPhase: PomodoroPhase, nextPhase: PomodoroPhase) {
        print("🔔 🚀 SESSION COMPLETE NOTIFICATION TRIGGERED")
        print("🔔    Completed Phase: \(completedPhase)")
        print("🔔    Next Phase: \(nextPhase)")
        print("🔔    Permission Granted: \(permissionGranted)")
        print("🔔    App Active: \(NSApp.isActive)")
        
        // Always show system notification first (works in background)
        showSystemNotification(completedPhase: completedPhase, nextPhase: nextPhase)
        
        // For menu bar apps, always show popup since the app is technically "active" 
        // even when just running in menu bar
        print("🔔 📱 Showing popup alert as well...")
        showSessionCompletePopup(completedPhase: completedPhase, nextPhase: nextPhase)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Called when notification is delivered while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 Notification will present: \(notification.request.identifier)")
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Called when user interacts with notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 Notification response received: \(response.actionIdentifier)")
        
        switch response.actionIdentifier {
        case "START_ACTION":
            // User clicked "Start Next Session" in notification
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .startNextSession, object: nil)
            }
        case "LATER_ACTION":
            // User clicked "Later" - do nothing
            break
        default:
            // Default tap on notification - bring app to front
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        
        completionHandler()
    }
    
    private func formatPhase(_ phase: PomodoroPhase) -> String {
        switch phase {
        case .focus:
            return "focus session"
        case .shortBreak:
            return "short break"
        case .longBreak:
            return "long break"
        case .idle:
            return "break"
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let startNextSession = Notification.Name("startNextSession")
} 