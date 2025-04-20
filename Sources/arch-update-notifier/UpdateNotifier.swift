import Gio
import Foundation

@main
actor UpdateNotifier {
    static var notifServer: NotificationServer?
    static var config: Config?
    static var lastNotif: Notification?
    static func main() async throws {
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: ".config/ArchUpdateNotifier.conf").path()
        config = try Config.load(from: configPath)
        guard let config = config else {
            fatalError("Config object is null. This should never happen. What did you do?")
        }

        let mainLoop = g_main_loop_new(nil, 0)
        notifServer = try await NotificationServer("Arch update notifier", appID: "moe.candy123.ArchUpdateNotifier")
        guard let notifServer = notifServer else {
            fatalError("NotificationServer is null. This should never happen. What did you do?")
        }

        let sig = DispatchSource.makeSignalSource(signal: SIGINT)
        sig.setEventHandler {
            Task.detached {
                await notifServer.close()
                exit(0)
            }
        }
        sig.activate()

        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now(), repeating: .seconds(config.checkUpdateInterval))
        timer.setEventHandler {
                Task.detached {
                    do {
                        // Get list of running `faked` PIDs
                        let beforeFakedPID = Set(try await Runner.runProgram("/usr/bin/ps", ["-o", "pid", "-C", "faked", "--no-headers"])
                            .split(separator: "\n")
                            .map({ $0.trimmingCharacters(in: .whitespaces)}))

                        // Run the configured commands
                        let pacCheckCmd = config.checkRepoCommand.split(separator: " ").map({ String($0) })
                        let yayCheckCmd = config.checkAURCommand.split(separator: " ").map({ String($0) })
                        async let pacCount = Runner.runProgram(pacCheckCmd[0], Array(pacCheckCmd.suffix(from: 1))).split(separator: "\n").count
                        async let yayCount = Runner.runProgram(yayCheckCmd[0], Array(yayCheckCmd.suffix(from: 1))).split(separator: "\n").count
                        guard try await pacCount + yayCount != 0 else { return }

                        // Get list of `faked` PIDs again
                        let afterFakedPID = Set(try await Runner.runProgram("/usr/bin/ps", ["-o", "pid", "-C", "faked", "--no-headers"])
                            .split(separator: "\n")
                            .map({ $0.trimmingCharacters(in: .whitespaces)}))
                        // Get list of the newly spawned faked PIDs
                        let newFaked = afterFakedPID.symmetricDifference(beforeFakedPID)
                        for fakedPID in newFaked {
                            _ = try await Runner.runProgram("/usr/bin/kill", ["-9", fakedPID]) // kill the hung faked PIDs
                        }

                        // Close the previous notification
                        if let lastNotif = lastNotif {
                            try await lastNotif.close()
                        }

                        // Send a new notification
                        let notif = try await notifServer.newNotification(
                            "Updates Available",
                            body: "Outdated from repos: \(pacCount)\nOutdated from AUR: \(yayCount)",
                            icon: config.icon ?? "computer",
                            actions: [
                                "Update": { notif in
                                    let yayUpdateCmd = config.updateCommand.split(separator: " ").map({ String($0) })
                                    try? Runner.runDetached(yayUpdateCmd[0], Array(yayUpdateCmd.suffix(from: 1)))
                                }, "Update only Repo": { notif in
                                    let pacUpdateCmd = config.updateRepoCommand.split(separator: " ").map({ String($0) })
                                    try! Runner.runDetached(pacUpdateCmd[0], Array(pacUpdateCmd.suffix(from: 1)))
                                }
                            ]
                        )
                        lastNotif = notif
                    } catch {
                        print("Error: \(error)")
                    }
                }
        }
        timer.activate()
        g_main_loop_run(mainLoop)
    }
}

