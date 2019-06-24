import Cocoa

extension Warning {
    static var count = 0

    class func stub(_ response: NSApplication.ModalResponse = .OK) {
        Warning.alertClass = DummyAlert.self
        Warning.count = 0
        DummyAlert.nextResponse = response
    }
}

class DummyAlert: NSAlert {
    static var nextResponse: NSApplication.ModalResponse?

    override init() {
        Warning.count += 1
    }
    
    override func runModal() -> NSApplication.ModalResponse {
        return DummyAlert.nextResponse!
    }
}
