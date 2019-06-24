import Cocoa

class Warning {
    static var alertClass = NSAlert.self

    class func show(_ text: String, suppressIdentifier: String? = nil) {
        let alert = alertClass.init()
        alert.messageText = text
        alert.addButton(withTitle: NSLocalizedString("ok button title", comment: ""))
        if suppressIdentifier != nil {
            if Suppressed.contains(suppressIdentifier!) { return }
            alert.addButton(withTitle: "Don't show again")
        }
        let result = alert.runModal()
        if result == .alertSecondButtonReturn {
            Suppressed.add(suppressIdentifier!)
        }
    }
    
    class Suppressed {
        private static let key = "SuppressedWarnings"
        
        class func contains(_ warningIdentifier: String) -> Bool {
            return items.contains(warningIdentifier)
        }
        
        class func add(_ identifier: String) {
            UserDefaults.standard.set(items + [identifier], forKey: key)
        }
        
        private class var items: [String] {
            return UserDefaults.standard.stringArray(forKey: key) ?? []
        }
    }
}
