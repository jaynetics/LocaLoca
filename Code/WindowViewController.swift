/*
View controller containing the lower UI controls and the embedded child view controller (split view controller).
*/

import Cocoa

class WindowViewController: NSViewController {

    // MARK: Outlets

    @IBOutlet private weak var addButton: NSPopUpButton!
    @IBOutlet private weak var removeButton: NSButton!
    @IBOutlet private weak var progIndicator: NSProgressIndicator!

    @IBOutlet weak var addLocaleItem: NSMenuItem!
    @IBOutlet weak var addFolderItem: NSMenuItem!
    @IBOutlet weak var addTranslationItem: NSMenuItem!
    
    @IBOutlet weak var searchField: NSTextField!

    // MARK: View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make full size on startup
        view.frame = NSScreen.main?.visibleFrame ?? CGRect.zero
        view.layout()

        // Insert an empty menu item at the beginning of the drown down button's menu and add its image.
        let addImage = NSImage(named: NSImage.addTemplateName)!
        addImage.size = NSSize(width: 10, height: 10)
        let addMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        addMenuItem.image = addImage
        addButton.menu?.insertItem(addMenuItem, at: 0)
        addButton.menu?.autoenablesItems = false
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        
        listen(IconViewController.Notifications.receivedContent, react: #selector(hideLoadingAnimation))
        listen(OutlineViewController.Notifications.working, react: #selector(showLoadingAnimation))
        listen(OutlineViewController.Notifications.workDone, react: #selector(hideLoadingAnimation))
        listen(OutlineViewController.Notifications.selectionChanged, react: #selector(selectionDidChange(_:)))
        listen(YamlSaver.Notifications.saving, react: #selector(showLoadingAnimation))
        listen(YamlSaver.Notifications.savingDone, react: #selector(hideLoadingAnimation))
    }

    deinit {
        unlisten(IconViewController.Notifications.receivedContent)
        unlisten(OutlineViewController.Notifications.working)
        unlisten(OutlineViewController.Notifications.workDone)
        unlisten(OutlineViewController.Notifications.selectionChanged)
        unlisten(YamlSaver.Notifications.saving)
        unlisten(YamlSaver.Notifications.savingDone)
    }

    // MARK: NSNotifications

    // Listens for selection changes to the NSTreeController so to update the UI elements (add/remove buttons).
    @objc private func selectionDidChange(_ notification: Notification) {
        // Examine the current selection and adjust the UI elements.

        // Notification's object must be the tree controller.
        guard let treeController = notification.object as? NSTreeController else { return }

        // Both add and remove buttons are enabled only if there is a current outline selection.
        removeButton.isEnabled = !treeController.selectedNodes.isEmpty
        addFolderItem.isEnabled = true
        addTranslationItem.isEnabled = true

        if !treeController.selectedNodes.isEmpty {
            if treeController.selectedNodes.count == 1 {
                let selectedNode = treeController.selectedNodes[0]
                if let item = OutlineViewController.node(from: selectedNode as Any) {
                    if item.isLeaf {
                        addFolderItem.isEnabled = false
                        addTranslationItem.isEnabled = false
                    } else {
                        showLoadingAnimation()
                    }
                }
            }
        }
    }
    
    @objc private func showLoadingAnimation() {
        progIndicator.isHidden = false
        progIndicator.startAnimation(self)
    }
    
    @objc private func hideLoadingAnimation() {
        progIndicator.isHidden = true
        progIndicator.stopAnimation(self)
    }

    // MARK: Actions

    struct Notifications {
        static let addFolder      = "AddFolderNotification"
        static let addTranslation = "AddTranslationNotification"
        static let addLocale      = "AddLocaleNotification"
        static let removeItem     = "RemoveItemNotification"
        static let searchChanged  = "SearchChangedNotification"
    }

    @IBAction func addFolderAction(_: AnyObject) {
        post(Notifications.addFolder)
    }

    @IBAction func addTranslationAction(_: AnyObject) {
        post(Notifications.addTranslation)
    }
    
    @IBAction func addLocaleAction(_: AnyObject) {
        post(Notifications.addLocale)
    }

    @IBAction func removeAction(_: AnyObject) {
        post(Notifications.removeItem)
    }

    @IBAction func focusSearchAction(_ sender: Any) {
        searchField?.becomeFirstResponder()
    }
}

// for search field
extension WindowViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ notif: Notification) {
        submitSearch()
    }
    
    private func submitSearch() {
        post(Notifications.searchChanged, object: searchField.stringValue)
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertNewline(_:)) {
            // re-run search if the user presses enter
            submitSearch()
            return true
        } else if commandSelector == #selector(cancelOperation(_:)) {
            // reset search on ESC press
            searchField.stringValue = ""
            submitSearch()
            return true
        }
        return false
    }
}
