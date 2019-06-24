// TODO: all of this should ideally be replaced by NSDocument or
// NSDocumentController.shared.noteNewRecentDocumentURL()
// if that function ever becomes less fragile

import Cocoa

class RecentMenu: NSMenu {
    func setup() {
        let clearRecentItem = items.last!
        let items = RecentlyOpened.items
        removeAllItems()
        for url in items {
            let item = NSMenuItem(title: url.path, action: #selector(openRecent(_:)), keyEquivalent: "")
            item.representedObject = url
            item.target = self
            addItem(item)
        }
        clearRecentItem.isEnabled = !items.isEmpty
        addItem(clearRecentItem)
        update()
    }
    
    @objc
    private func openRecent(_ sender: NSMenuItem) {
        let dirUrl = sender.representedObject as! URL
        let delegate = NSApplication.shared.delegate as? AppDelegate?
        delegate??.openDirUrl(dirUrl)
    }
}
