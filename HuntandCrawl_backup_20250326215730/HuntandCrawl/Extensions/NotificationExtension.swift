import Foundation

extension NSNotification.Name {
    static let didReceiveMessage = NSNotification.Name("didReceiveMessage")
    static let didConnectToDevice = NSNotification.Name("didConnectToDevice") 
    static let didDisconnectFromDevice = NSNotification.Name("didDisconnectFromDevice")
    static let bluetoothStateChanged = NSNotification.Name("bluetoothStateChanged")
    static let locationPermissionChanged = NSNotification.Name("locationPermissionChanged")
} 