import Gio

var dbus = DBus()
var busName = "cool"
var connection: SendableOpaquePointer? = nil

(connection, busName) = await dbus.ownName("moe.candy123.ArchUpdateNotifier")

print(busName)



