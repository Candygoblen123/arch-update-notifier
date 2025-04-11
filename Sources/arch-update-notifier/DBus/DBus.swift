import Gio

actor DBus: @unchecked Sendable {
    private func _ownName(
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
            { (conn, name, usrData) in
                print("Lost name \(String(cString: name!)) on session bus")
                if let swift = usrData {
                    let holder = Unmanaged<DBusOwnNameClosureHolder>.fromOpaque(swift)
                    holder.release()
                }
            },
            opaqueHolder,
            nil
        )
        return rt
    }

    public func ownNameSync(
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

    public func ownName(_ name: String) async -> (SendableOpaquePointer?, String) {
        await withCheckedContinuation { continuation in
            let mainLoop = g_main_loop_new(nil, 0)
            _ = ownNameSync(name) { conn, name in
                continuation.resume(returning: (.init(conn), String(cString: name!)))
                g_main_loop_quit(mainLoop)
            }
            g_main_loop_run(mainLoop)

        }
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

struct SendableOpaquePointer: @unchecked Sendable {
    let pointer: OpaquePointer?

    init(_ pointer: OpaquePointer?) {
        self.pointer = pointer
    }
}


