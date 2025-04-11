import Gio

actor DBus {
    let connection: SendableOpaquePointer
    let busName: String

    init(_ name: String) async throws {
        let (connection, busName) = await DBus.ownName("moe.candy123.ArchUpdateNotifier")
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
                    print(String(cString: error!.message))
                    continuation.resume(throwing: DBusError.methodCallError)
                    g_main_loop_quit(mainLoop)
                    return
                }
                continuation.resume(returning: value)
                g_main_loop_quit(mainLoop)

            }
            g_main_loop_run(mainLoop)
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
    case methodCallError
}


