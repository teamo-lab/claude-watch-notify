import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var onClickCommand: String?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                self.sendNotification()
            } else {
                // fallback: just exit
                exit(1)
            }
        }
    }
    
    func sendNotification() {
        let args = CommandLine.arguments
        let title = args.count > 1 ? args[1] : "Claude Code"
        let body = args.count > 2 ? args[2] : ""
        onClickCommand = args.count > 3 ? args[3] : nil
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound(named: UNNotificationSoundName("Glass.aiff"))
        
        let request = UNNotificationRequest(identifier: "claude-\(ProcessInfo.processInfo.globallyUniqueString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if error != nil {
                exit(1)
            }
            // Wait a bit then exit if not clicked
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                exit(0)
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let cmd = onClickCommand {
            let task = Process()
            task.launchPath = "/bin/bash"
            task.arguments = ["-c", cmd]
            try? task.run()
            task.waitUntilExit()
        }
        completionHandler()
        exit(0)
    }
    
    // Show notification even when app is foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
