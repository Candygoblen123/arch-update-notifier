import Gio

struct NotificationServer {
    let dbus: DBus
    let appName: String

    init(_ appName: String, appID: String) async throws(DBusError) {
        dbus = try await DBus(appID)
        self.appName = appName
    }

    func sendNotification(_ summary: String, body: String, actions: [String] = []) async throws -> UInt32 {
        let variantActions = actions.map({ g_variant_new_string($0) })
        let argsArr = [
            g_variant_new_string(appName),
            g_variant_new_uint32(0),
            g_variant_new_string("moe.candy123-ArchUpdateNotifier"),
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
        return g_variant_get_uint32(first)
    }
}

