import Gio
import Foundation

@main
actor UpdateNotifier {
    static var notifServer: NotificationServer?
    static func main() async throws {
        let mainLoop = g_main_loop_new(nil, 0)
        notifServer = try await NotificationServer("Arch update notifier", appID: "moe.candy123.ArchUpdateNotifier")
        guard let notifServer = notifServer else {
            fatalError("NotificationServer is null. This should never happen. What did you do?")
        }

        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now(), repeating: .seconds(3600))
        timer.setEventHandler {
            Task.detached {
                do {
                    let pacCount = try await Runner.runProgram("/usr/bin/checkupdates").split(separator: "\n").count
                    let yayCount = try await Runner.runProgram("/usr/bin/yay", ["-Qua", "--devel"]).split(separator: "\n").count
                    guard pacCount + yayCount != 0 else { return }
                    let _ = try await notifServer.newNotification(
                        "Updates Available",
                        body: "Outdated from repos: \(pacCount)\nOutdated from AUR: \(yayCount)",
                        actions: [
                            "Update": { notif in
                                try! Runner.runDetached("/usr/bin/ghostty", ["-e", "/usr/bin/yay --sudoloop"])
                            }, "Update only Repo": { notif in
                                try! Runner.runDetached("/usr/bin/ghostty", ["-e", "/usr/bin/sudo pacman -Syu"])
                            }
                        ]
                    )
                } catch {
                    print("Error: \(error)")
                }
            }
        }
        timer.activate()
        g_main_loop_run(mainLoop)
    }
}

