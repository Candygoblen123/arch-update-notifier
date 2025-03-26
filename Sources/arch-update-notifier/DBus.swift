import Foundation
import cdbus

class DBus {
    var err = DBusError()
    let conn: OpaquePointer!

    public init(name: String) throws {
        dbus_error_init(&err)

        // Connect to the dbus
        conn = dbus_bus_get(DBUS_BUS_SESSION, &err)
        if dbus_error_is_set(&err) != 0 {
            let message = String(cString: err.message)
            dbus_error_free(&err)
            throw DBusErr.ConnectionError(message: message)
        }
        guard conn != nil else { throw DBusErr.ConnectionError() }

        // request a name on the bus
        let nameReply = dbus_bus_request_name(conn, name, UInt32(DBUS_NAME_FLAG_REPLACE_EXISTING), &err)
        if dbus_error_is_set(&err) != 0 {
            let message = String(cString: err.message)
            dbus_error_free(&err)
            throw DBusErr.NameError(message: message)
        }
        guard DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER == nameReply else { throw DBusErr.NameError() }
    }

    public func callMethod(busName: String, objectPath: String, interface: String, methodName: String, args: [DBusArgs] = []) throws -> [DBusArgs] {
        var msg = dbus_message_new_method_call(busName, objectPath, interface, methodName)

        var requestArgIter = DBusMessageIter()
        dbus_message_iter_init_append(msg, &requestArgIter)
        for arg in args {
            let ID = arg.getID()

            switch arg {
                case .string(let val):
                    var val = [val!.utf8String]
                    dbus_message_iter_append_basic(&requestArgIter, ID, &val)
                case .bool(let val):
                    var val = val! ? 1 : 0
                    dbus_message_iter_append_basic(&requestArgIter, ID, &val)
                case .i32(let val):
                    var val = val
                    dbus_message_iter_append_basic(&requestArgIter, ID, &val)
                case .u32(let val):
                    var val = val
                    dbus_message_iter_append_basic(&requestArgIter, ID, &val)
            }
        }

        var pending: OpaquePointer?
        guard dbus_connection_send_with_reply(conn, msg, &pending, -1) != 0 else {
            throw DBusErr.SendError()
        }
        guard pending != nil else {
            throw DBusErr.SendError()
        }
        dbus_connection_flush(conn)
        dbus_message_unref(msg)

        dbus_pending_call_block(pending)

        msg = dbus_pending_call_steal_reply(pending)
        guard let msg = msg else {
            throw DBusErr.EmptyReply()
        }
        dbus_pending_call_unref(pending)
        var responseArgsIter = DBusMessageIter()

        guard dbus_message_iter_init(msg, &responseArgsIter) != 0 else {
            // Message has no arguments
            return []
        }
        var responseArgArray: [DBusArgs] = []

        repeat {
            guard let arg = try? DBusArgs.fromID(id: dbus_message_iter_get_arg_type(&responseArgsIter)) else { continue }

            switch (arg) {
                case .string:
                    var val: UnsafeMutablePointer<CChar>? = nil
                    dbus_message_iter_get_basic(&responseArgsIter, &val)
                    responseArgArray.append(.string(String(cString: val!)))
                case .bool:
                    var val: UnsafeMutablePointer<Bool>? = nil
                    dbus_message_iter_get_basic(&responseArgsIter, &val)
                    responseArgArray.append(.bool(val!.pointee))
                case .i32:
                    var val: UnsafeMutablePointer<Int32>? = nil
                    dbus_message_iter_get_basic(&responseArgsIter, &val)
                    responseArgArray.append(.i32(val!.pointee))
                case .u32:
                    var val: UnsafeMutablePointer<UInt32>? = nil
                    dbus_message_iter_get_basic(&responseArgsIter, &val)
                    responseArgArray.append(.u32(val!.pointee))
            }

        } while dbus_message_iter_next(&responseArgsIter) != 0

        return responseArgArray
    }
}

enum DBusErr: Error {
    case ConnectionError(message: String? = nil)
    case NameError(message: String? = nil)
    case ArgumentError(message: String? = nil)
    case SendError(message: String? = nil)
    case EmptyReply(message: String? = nil)
}

enum DBusArgs {
    case string(_ val: String?)
    case i32(_ val: Int32?)
    case u32(_ val: UInt32?)
    case bool(_ val: Bool?)
    //case arr(_ val: [DBusArgs])

    func getID() -> Int32 {
        switch (self) {
            case .string:
                115
            case .i32:
                105
            case .u32:
                117
            case .bool:
                98
        }
    }

    static func fromID(id: Int32) throws -> DBusArgs {
        switch (id) {
            case 115:
                .string(nil)
            case 105:
                .i32(nil)
            case 117:
                .u32(nil)
            case 98:
                .bool(nil)
            default:
                print("Invalid arg ID: \(id)")
                throw DBusErr.ArgumentError(message: "Argument ID \(id) is invlaid")
        }
    }
}
