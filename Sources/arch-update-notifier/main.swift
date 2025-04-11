import Gio

var dbus = try! await DBus("moe.candy123.ArchUpdateNotifier")

let argsArr = [
    g_variant_new_string("Arch Update Notifier"),
    g_variant_new_uint32(0),
    g_variant_new_string(""),
    g_variant_new_string("Test notification"),
    g_variant_new_string("Lemon Melon Cookie"),
    g_variant_new_array(g_variant_type_new("s"), [], 0),
    g_variant_new_array(g_variant_type_new("{sv}"), [], 0),
    g_variant_new_int32(-1)
]

var tmp = try await dbus.callMethod(
    busName: "org.freedesktop.Notifications",
    objectPath: "/org/freedesktop/Notifications",
    interfaceName: "org.freedesktop.Notifications",
    methodName: "Notify",
    parameters: argsArr.map({ SendableOpaquePointer($0) }),
    replyType: g_variant_type_new("(u)")
)

print(String(cString: g_variant_get_type_string(tmp?.pointer)))

print(dbus.busName)



