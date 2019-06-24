import Cocoa

extension Dialog {
    class func stubAsk(_ answer: String) {
        Dialog.askClass = DummyAsk.self
        DummyAsk.nextAnswer = answer
    }
    
    class func stubSelectDir(_ dir: URL) {
        Dialog.selectDirClass = DummySelectDir.self
        DummySelectDir.nextSelectedDir = dir
    }
}

class DummyAsk: NSAlert {
    static var nextAnswer: String?
    
    override func runModal() -> NSApplication.ModalResponse {
        let input = accessoryView as! NSTextField
        input.stringValue = DummyAsk.nextAnswer!
        return .alertFirstButtonReturn
    }
}

class DummySelectDir: NSOpenPanel {
    static var nextSelectedDir: URL?
    
    override func runModal() -> NSApplication.ModalResponse {
        return .OK
    }
    
    override var url: URL? {
        return DummySelectDir.nextSelectedDir
    }
}
