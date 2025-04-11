import Gio

internal struct DBusOwnName {
    private static func _ownName(
        _ name: String,
        data: DBusOwnNameClosureHolder,
        aquiredHandler: @convention(c) @escaping (OpaquePointer?, UnsafePointer<gchar>?, gpointer) -> (),
        connectedHandler: @convention(c) @escaping (OpaquePointer?, UnsafePointer<gchar>?, gpointer) -> ()
    ) -> UInt32 {
        let opaqueHolder = Unmanaged.passRetained(data).toOpaque()
        let aquiredCallback = unsafeBitCast(aquiredHandler, to: GBusNameAcquiredCallback.self)
        let connectedCallback = unsafeBitCast(connectedHandler, to: GBusAcquiredCallback.self)
        let rt =  g_bus_own_name(
            G_BUS_TYPE_SESSION,
            name,
            G_BUS_NAME_OWNER_FLAGS_ALLOW_REPLACEMENT,
            connectedCallback,
            aquiredCallback,
            nil,
            opaqueHolder,
            { usrData in
                if let swift = usrData {
                    let holder = Unmanaged<DBusOwnNameClosureHolder>.fromOpaque(swift)
                    holder.release()
                }
            }
        )
        return rt
    }

    internal static func ownNameSync(
        _ name: String,
        aquiredCallback: @escaping (OpaquePointer?, UnsafePointer<gchar>?) -> (),
        connectedCallback: ((OpaquePointer?, UnsafePointer<gchar>?) -> ())? = nil
    ) -> UInt32 {
        let rt = _ownName(name, data: DBusOwnNameClosureHolder(aquiredCallback, connectedCallback), aquiredHandler: { (conn, name, swift) in
            let holder = Unmanaged<DBusOwnNameClosureHolder>.fromOpaque(swift).takeRetainedValue()
            holder.aquiredCall(conn, name)
        }, connectedHandler: { (conn, name, swift) in
            let holder = Unmanaged<DBusOwnNameClosureHolder>.fromOpaque(swift).takeUnretainedValue()
            holder.connectedCall?(conn, name)
        })
        return rt
    }
}

private class DBusOwnNameClosureHolder {
    public let aquiredCall: (OpaquePointer?, UnsafePointer<gchar>?) -> ()
    public let connectedCall: ((OpaquePointer?, UnsafePointer<gchar>?) -> ())?

    public init(_ aquiredClosure: @escaping (OpaquePointer?, UnsafePointer<gchar>?) -> (), _ connectedClosure:  ((OpaquePointer?, UnsafePointer<gchar>?) -> ())?) {
        self.aquiredCall = aquiredClosure
        self.connectedCall = connectedClosure
    }
}
