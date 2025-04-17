import Gio

actor NotificationServer: Sendable {
    fileprivate let dbus: DBusConnection
    private var sentNotifications: [UInt32: Notification] = [:]
    let appName: String

    init(_ appName: String, appID: String) async throws(DBusError) {
        dbus = try await DBusConnection(appID)
        self.appName = appName
        _ = await dbus.signalSubscribe(
            sender: "org.freedesktop.Notifications",
            interfaceName: "org.freedesktop.Notifications",
            member: "ActionInvoked",
            objectPath: "/org/freedesktop/Notifications",
            handler: actionInvokeCallback
        )
    }

    func newNotification(_ summary: String, body: String, icon: String, actions: KeyValuePairs<String, @Sendable (Notification) async -> ()> = [:]) async throws -> Notification {
        let stringActions: [String] = actions.enumerated()
            .flatMap({(index, name) in [String(index), name.key]})
        let variantActions = stringActions.map({ g_variant_new_string($0) })
        let argsArr = [
            g_variant_new_string(appName),
            g_variant_new_uint32(0),
            g_variant_new_string(icon),
            g_variant_new_string(summary),
            g_variant_new_string(body),
            g_variant_new_array(g_variant_type_new("s"), variantActions, UInt(variantActions.count)),
            g_variant_new_array(g_variant_type_new("{sv}"), [], 0),
            g_variant_new_int32(-1)
        ]

        let newIDVariant = try await dbus.callMethod(
            busName: "org.freedesktop.Notifications",
            objectPath: "/org/freedesktop/Notifications",
            interfaceName: "org.freedesktop.Notifications",
            methodName: "Notify",
            parameters: argsArr.map({ SendableOpaquePointer($0) }),
            replyType: g_variant_type_new("(u)")
        )
        let first = g_variant_get_child_value(newIDVariant?.pointer, 0)
        let newID = g_variant_get_uint32(first)
        var actionCallbacks: [String: @Sendable (Notification) async -> ()] = [:]
        for (idx, elem) in actions.enumerated() {
            actionCallbacks[String(idx)] = elem.value
        }
        let ret = Notification(newID, self, actionCallbacks)
        sentNotifications[newID] = ret
        return ret
    }

    private func actionInvokeCallback(senderName: String?, objPath: String?, interfaceName: String?, signalName: String?, parameters: SendableOpaquePointer?) {
        guard signalName == "ActionInvoked" else { return }
        let id = g_variant_get_uint32(g_variant_get_child_value(parameters?.pointer, 0))
        let actionKey = String(cString: g_variant_get_string(g_variant_get_child_value(parameters?.pointer, 1), nil))
        guard sentNotifications.keys.contains(id) else {
            print("invalid notification ID: \(id)! Ignorning...")
            return
        }
        Task {
            await sentNotifications[id]?.actionInvokeCallback(actionKey)
        }
    }
}

struct Notification: Sendable {
    private let id: UInt32
    private let server: NotificationServer
    private let actionCallbacks: [String: @Sendable (Notification) async -> ()]

    fileprivate init(_ id: UInt32, _ server: NotificationServer, _ actionCallbacks: [String: @Sendable (Notification) async -> ()]) {
        self.id = id
        self.server = server
        self.actionCallbacks = actionCallbacks
    }

    func close() async throws {
        let argsArr = [SendableOpaquePointer(g_variant_new_uint32(id))]
        try await server.dbus.callMethod(
            busName: "org.freedesktop.Notifications",
            objectPath: "/org/freedesktop/Notifications",
            interfaceName: "org.freedesktop.Notifications",
            methodName: "CloseNotification",
            parameters: argsArr,
            replyType: nil
        )
    }

    func actionInvokeCallback(_ actionKey: String) async {
        guard actionCallbacks.keys.contains(actionKey) else {
            print("Invalid actionID: \(actionKey)! ignoring...")
            return
        }
        await actionCallbacks[actionKey]?(self)
    }
}

