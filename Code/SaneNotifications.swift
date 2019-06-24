import Cocoa

protocol SaneNotifications {
    func listen(_ notificationName: String, react: Selector)
    func unlisten(_ notificationName: String)
    func post(_ notificationName: String)
    func post(_ notificationName: String, object: Any?)
    static func post(_ notificationName: String)
    static func post(_ notificationName: String, object: Any?)
}

class SaneNotificationCenter {
    static var center = NotificationCenter.default
}

extension SaneNotifications {
    func listen(_ notificationName: String, react: Selector) {
        SaneNotificationCenter.center.addObserver(
            self,
            selector: react,
            name: Notification.Name(notificationName),
            object: nil
        )
    }
    
    func unlisten(_ notificationName: String) {
        SaneNotificationCenter.center.removeObserver(
            self,
            name: Notification.Name(notificationName),
            object: nil
        )
    }
    
    func post(_ notificationName: String) {
        post(notificationName, object: nil)
    }
    
    func post(_ notificationName: String, object: Any?) {
        SaneNotificationCenter.center.post(
            name: Notification.Name(notificationName),
            object: object
        )
    }
    
    static func post(_ notificationName: String) {
        post(notificationName, object: nil)
    }
    
    static func post(_ notificationName: String, object: Any?) {
        SaneNotificationCenter.center.post(
            name: Notification.Name(notificationName),
            object: object
        )
    }
}

extension NSViewController: SaneNotifications {}
