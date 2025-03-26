// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import cdbus

let pid = getpid()
let dbus = try DBus(name: "org.freedesktop.StatusNotifierItem-\(pid)-\(0)")

var msg = try dbus.callMethod(
    busName: "org.kde.StatusNotifierWatcher",
    objectPath: "/StatusNotifierWatcher",
    interface: "org.freedesktop.DBus.Introspectable",
    methodName: "Introspect")

//if case DBusArgs.string(let val) = msg.first! {
    //print(val!)
//}


var hostReg = try dbus.callMethod(
    busName: "org.kde.StatusNotifierWatcher",
    objectPath: "/StatusNotifierWatcher",
    interface: "org.freedesktop.DBus.Properties",
    methodName: "Get",
    args: [.string("org.kde.StatusNotifierWatcher"), .string("ProtocolVersion")])

print(hostReg)

//if case DBusArgs.string(let val) = hostReg.first! {
//    print(val!)
//}

let notification = try dbus.callMethod(
    busName: "org.kde.StatusNotifierWatcher",
    objectPath: "/org/freedesktop/Notifications",
    interface: "org.freedesktop.Notifications",
    methodName: "Notify",
    args: [.string(""), .u32(0), .string(""), .string("test notification"), .string("Cool test notification you got here")])

print(notification)

//if case DBusArgs.u32(let val) = notification.first! {
//    print(val!)
//}
//let output = Task { try await Runner.runProgram("/usr/bin/checkupdates") }
//print("Checking updates")

//print(try await output.value)

//dbus_connection_close(conn)


