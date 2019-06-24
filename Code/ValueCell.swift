import Cocoa

class ValueCell: NSTableCellView {
    @IBOutlet weak var localeField: NSTextField!
    @IBOutlet weak var contentField: NSTextField!
    weak var node: Node?
    var locale: String?
    
    func with(_ node: Node, locale: String) -> ValueCell {
        self.node = node
        self.locale = locale
        contentField.delegate = self
        contentField.stringValue = node.translations?[locale] ?? ""
        localeField.stringValue = Locale(code: locale).nameWithFlag
        return self
    }

    func edit() {
        contentField.isEditable = true
        contentField.becomeFirstResponder()
        contentField.currentEditor()?.selectedRange = NSRange(location: 0, length: 0)
        contentField.currentEditor()?.moveToEndOfDocument(nil)
    }
}

// MARK: - Delegate

extension ValueCell: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ notif: Notification) {
        let field = notif.object as! NSTextField
        node?.updateTranslation(locale: locale!, value: field.stringValue)
    }
}
