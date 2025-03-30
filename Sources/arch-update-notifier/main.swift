import CGio

let mainLoop = g_main_loop_new(nil, 0)

let ownerId = g_bus_own_name(G_BUS_TYPE_SESSION, "moe.candy123.ArchUpdaterNotifier", G_BUS_NAME_OWNER_FLAGS_ALLOW_REPLACEMENT, { (conn, name, userData) in
        print("Connected to session bus: \(String(cString: name!))")
    }, { (conn, name, userData) in
        print("got name \(String(cString: name!)) on session bus")
        var err: UnsafeMutablePointer<GError>? = nil

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

        let reply = g_dbus_connection_call_sync(
            conn,
            "org.freedesktop.Notifications",
            "/org/freedesktop/Notifications",
            "org.freedesktop.Notifications",
            "Notify",
            g_variant_new_tuple(argsArr, UInt(argsArr.count)),
            g_variant_type_new("(u)"),
            G_DBUS_CALL_FLAGS_NONE,
            -1,
            nil,
            &err
        )
        guard let reply = reply else {
            print("Message send error: \(err!.pointee.domain) - \(err!.pointee.code): \(String(cString: err!.pointee.message))")
            return
        }
        let strReply = g_variant_print(reply, 1)
        print("\(String(cString: strReply!))")

    }, { (conn, name, userData) in
        print("Lost name \(String(cString: name!)) on session bus")
    }, nil, nil)

g_main_loop_run(mainLoop)

g_bus_unown_name(ownerId)
