/*
View controller object to host the icon collection view to display contents of a folder.
*/

import Cocoa

class IconViewController: NSViewController {
    struct Notifications {
        static let receivedContent = "ReceivedContentNotification"
        static let selectedNode    = "SelectedNodeNotification"
    }

    // Key values for the icon view dictionary.
    struct IconViewKeys {
        static let keyName = "name"
        static let keyIcon = "icon"
    }

    @objc private dynamic var icons: [[String: Any]] = []

    var node: Node? {
        didSet {
            // Asynchronously fetch the icons.
            DispatchQueue.global(qos: .default).async {
                self.gatherContents(self.node!)
            }
        }
    }
    
    @objc
    private dynamic var selectedIndexPaths = NSMutableIndexSet() {
        didSet {
            // ignore non-selection/multi-selection
            guard self.selectedIndexPaths.count == 1 else { return }
            // if one item is selected, notify to also select it in the outline.
            // poor workaround to avoid recursive selecting:
            guard self.selectingEnabled else {
                self.selectingEnabled = true
                self.selectedIndexPaths = NSMutableIndexSet()
                return
            }
            self.selectingEnabled = false
            let selectedNode = node!.children[self.selectedIndexPaths.firstIndex]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.post(Notifications.selectedNode, object: selectedNode)
            })
        }
    }
    
    @objc private dynamic var selectingEnabled = true

    private func gatherContents(_ inObject: Any) {
        autoreleasepool {
            let contentArray = node!.children.map { [
                IconViewKeys.keyIcon: $0.icon,
                IconViewKeys.keyName: $0.ownKey,
            ] }
            // Call back on the main thread to update the icons in our view.
            DispatchQueue.main.async {
                self.updateIcons(contentArray)
            }
        }
    }
    
    private func updateIcons(_ iconArray: [[String: Any]]) {
        icons = iconArray
        post(Notifications.receivedContent)
    }
}
