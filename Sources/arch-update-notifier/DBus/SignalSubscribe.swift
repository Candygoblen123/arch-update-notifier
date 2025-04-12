import Gio

internal struct DBusSignalSubscribe {
    private static func _signalSubscribe(
        _ connection: OpaquePointer?,
        sender: String,
        interfaceName: String,
        member: String,
        objectPath: String,
        data: DBusSignalSubscribeClosureHolder,
        handler: @convention(c) @escaping (OpaquePointer?, UnsafePointer<gchar>?, UnsafePointer<gchar>?, UnsafePointer<gchar>?, UnsafePointer<gchar>?, OpaquePointer?, gpointer?) -> Void
    ) -> UInt32 {
        let opaqueHolder = Unmanaged.passRetained(data).toOpaque()
        return g_dbus_connection_signal_subscribe(
            connection,
            sender,
            interfaceName,
            member,
            objectPath,
            nil,
            G_DBUS_SIGNAL_FLAGS_NONE,
            handler,
            opaqueHolder,
            { usrData in
                if let swift = usrData {
                    let holder = Unmanaged<DBusSignalSubscribeClosureHolder>.fromOpaque(swift)
                    holder.release()
                }
            }
        )
    }

    internal static func signalSubscribe(
        _ connection: SendableOpaquePointer?,
        sender: String,
        interfaceName: String,
        member: String,
        objectPath: String,
        handler: @escaping (SendableOpaquePointer?, UnsafePointer<gchar>?, UnsafePointer<gchar>?, UnsafePointer<gchar>?, UnsafePointer<gchar>?, SendableOpaquePointer?) -> ()
    ) -> UInt32 {
        _signalSubscribe(
            connection?.pointer,
            sender: sender,
            interfaceName: interfaceName,
            member: member,
            objectPath: objectPath,
            data: DBusSignalSubscribeClosureHolder(handler)
        ) { connection, senderName, objectPath, interfaceName, signalName, parameters, swift in
            if let swift = swift {
                let holder = Unmanaged<DBusSignalSubscribeClosureHolder>.fromOpaque(swift).takeUnretainedValue()
                holder.callback(SendableOpaquePointer(connection), senderName, objectPath, interfaceName, signalName, SendableOpaquePointer(parameters))
            }
        }
    }
}


private class DBusSignalSubscribeClosureHolder {
    public let callback: (SendableOpaquePointer?, UnsafePointer<gchar>?, UnsafePointer<gchar>?, UnsafePointer<gchar>?, UnsafePointer<gchar>?, SendableOpaquePointer?) -> ()

    init(_ callback: @escaping (SendableOpaquePointer?, UnsafePointer<gchar>?, UnsafePointer<gchar>?, UnsafePointer<gchar>?, UnsafePointer<gchar>?, SendableOpaquePointer?) -> ()) {
        self.callback = callback
    }
}
