import Gio

internal struct DBusCallMethod {
    private static func _callMethod(
        _ connection: OpaquePointer?,
        busName: String,
        objectPath: String,
        interfaceName: String,
        methodName: String,
        parameters: [SendableOpaquePointer?],
        replyType: GVariantType_autoptr?,
        data: DBusCallMethodClosureHolder,
        handler: @convention(c) @escaping (UnsafeMutablePointer<GObject>?, OpaquePointer?, gpointer?) -> ()
    ) {
        let opaqueHolder = Unmanaged.passRetained(data).toOpaque()
        g_dbus_connection_call(
            connection,
            busName,
            objectPath,
            interfaceName,
            methodName,
            g_variant_new_tuple(parameters.map({ $0?.pointer }), UInt(parameters.count)),
            replyType,
            G_DBUS_CALL_FLAGS_NONE,
            -1,
            nil,
            handler,
            opaqueHolder
        )
    }

    internal static func callMethodSync(
        _ connection: OpaquePointer?,
        busName: String,
        objectPath: String,
        interfaceName: String,
        methodName: String,
        parameters: [SendableOpaquePointer?],
        replyType: SendableOpaquePointer?,
        handler: @escaping (SendableOpaquePointer?, GError?) -> ()
    ) {
        _callMethod(
            connection,
            busName: busName,
            objectPath: objectPath,
            interfaceName: interfaceName,
            methodName: methodName,
            parameters: parameters,
            replyType: replyType?.pointer,
            data: DBusCallMethodClosureHolder(handler)
        ) { srcObj, res, swift in
            if let swift = swift {
                var err: UnsafeMutablePointer<GError>? = nil
                let retValues = g_dbus_connection_call_finish(.init(srcObj), res, &err)
                let holder = Unmanaged<DBusCallMethodClosureHolder>.fromOpaque(swift).takeRetainedValue()
                holder.callback(SendableOpaquePointer(retValues), err?.pointee)
            }
        }
    }
}

extension GError: @retroactive @unchecked Sendable {}

private class DBusCallMethodClosureHolder {
    public let callback: (SendableOpaquePointer?, GError?) -> ()

    init(_ callback: @escaping (SendableOpaquePointer?, GError?) -> ()) {
        self.callback = callback
    }
}
