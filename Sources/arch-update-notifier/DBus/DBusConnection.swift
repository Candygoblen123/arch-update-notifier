import Gio

actor DBusConnection {
    let connection: SendableOpaquePointer
    let busName: String

    init(_ name: String) async throws(DBusError) {
        let (connection, busName) = await DBusConnection.ownName("moe.candy123.ArchUpdateNotifier")
        if let connection = connection {
            self.connection = connection
            self.busName = busName
        } else {
            throw DBusError.connectionFail
        }
    }

    private static func ownName(_ name: String) async -> (SendableOpaquePointer?, String) {
        await withCheckedContinuation { continuation in
            let mainLoop = g_main_loop_new(nil, 0)
            _ = DBusOwnName.ownNameSync(name) { conn, name in
                continuation.resume(returning: (.init(conn), String(cString: name!)))
                g_main_loop_quit(mainLoop)
            }
            g_main_loop_run(mainLoop)
        }
    }

    @discardableResult
    func callMethod(
        busName: String,
        objectPath: String,
        interfaceName: String,
        methodName: String,
        parameters: [SendableOpaquePointer?],
        replyType: GVariantType_autoptr?
    ) async throws -> SendableOpaquePointer? {
        try await withCheckedThrowingContinuation { continuation in
            let mainLoop = g_main_loop_new(nil, 0)
            DBusCallMethod.callMethodSync(connection.pointer,
                busName: busName,
                objectPath: objectPath,
                interfaceName: interfaceName,
                methodName: methodName,
                parameters: parameters,
                replyType: SendableOpaquePointer(replyType)
            ) { value, error in
                guard let value = value else {
                    let message = String(cString: error!.message)
                    continuation.resume(throwing: DBusError.methodCallError(message))
                    g_main_loop_quit(mainLoop)
                    return
                }
                continuation.resume(returning: value)
                g_main_loop_quit(mainLoop)

            }
            g_main_loop_run(mainLoop)
        }
    }

    func signalSubscribe(
        sender: String,
        interfaceName: String,
        member: String,
        objectPath: String,
        handler: @escaping (String?, String?, String?, String?, SendableOpaquePointer?) -> ()
    ) -> UInt32 {
        let id = DBusSignalSubscribe.signalSubscribe(connection, sender: sender, interfaceName: interfaceName, member: member, objectPath: objectPath) { _ , senderName, objPath, interfaceName, signalName, parameters in
            handler(DBusConnection.stringOrNil(senderName), DBusConnection.stringOrNil(objPath), DBusConnection.stringOrNil(interfaceName), DBusConnection.stringOrNil(signalName), parameters)
        }
        return id

    }

    private static func stringOrNil(_ cString: UnsafePointer<gchar>?) -> String? {
        if let cString = cString {
            return String(cString: cString)
        } else {
            return nil
        }
    }
}

struct SendableOpaquePointer: @unchecked Sendable {
    let pointer: OpaquePointer?

    init(_ pointer: OpaquePointer?) {
        self.pointer = pointer
    }
}

enum DBusError: Error {
    case connectionFail
    case methodCallError(String)
}


