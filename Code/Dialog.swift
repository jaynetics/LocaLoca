import Cocoa

class Dialog {
    static var askClass = NSAlert.self

    struct AskResult {
        var answer: String?
        var confirmed: Bool
    }

    class func ask(_ question: String, withTextInput: Bool, buttonTitle: String) -> AskResult {
        let alert = askClass.init()
        var input: NSTextField?
        if withTextInput {
            input = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
            alert.accessoryView = input
            alert.window.initialFirstResponder = input
        }
        alert.messageText = question
        alert.addButton(withTitle: buttonTitle)
        alert.addButton(withTitle: "Cancel")
        let confirmed = alert.runModal() == .alertFirstButtonReturn
        return AskResult(answer: input?.stringValue, confirmed: confirmed)
    }
    
    static var selectDirClass = NSOpenPanel.self

    class func selectDir(canCreate: Bool = false) -> URL? {
        let openPanel = selectDirClass.init()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = canCreate
        openPanel.canChooseFiles = false
        guard openPanel.runModal() == .OK else { return nil }
        return openPanel.url
    }
}
