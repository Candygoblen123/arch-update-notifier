import Gio
import Foundation

@main
actor UpdateNotifier {
    static var notifServer: NotificationServer? = nil
    static func main() async throws {
        let mainLoop = g_main_loop_new(nil, 0)
        notifServer = try await NotificationServer("Arch update notifier", appID: "moe.candy123.ArchUpdateNotifier") 
        guard notifServer != nil else {
            return
        }

        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now(), repeating: .seconds(10))
        timer.setEventHandler {
            Task.detached {
                let _ = try await notifServer!.newNotification(
                    "Test",
                    body: "Nahida",
                    actions: [
                        "Cool": { notif in
                            print("Cool clicked")
                            try! await notif.close()
                        }
                    ]
                )
            }
        }
        timer.activate()
        g_main_loop_run(mainLoop)
    }
}

