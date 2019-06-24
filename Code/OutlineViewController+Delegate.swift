/*
NSOutlineViewDelegate support OutlineViewController.
*/

import Cocoa

extension OutlineViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?

        guard let node = OutlineViewController.node(from: item) else { return view }

        //  return NSTableCellView with an image and title
        view = outlineView.makeView(
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MainCell"), owner: self) as? NSTableCellView

        view?.textField?.stringValue = node.ownKey
        view?.textField?.isEditable = true
        view?.imageView?.image = node.icon

        return view
    }

    // An outline row view was just inserted.
    func outlineView(_ outlineView: NSOutlineView, didAdd rowView: NSTableRowView, forRow row: Int) {
        // Are we adding a newly inserted row that needs a new name?
        if rowToAdd != -1 {
            // Force-edit the newly added row's name.
            if let view = outlineView.view(atColumn: 0, row: rowToAdd, makeIfNecessary: false) {
                if let cellView = view as? NSTableCellView {
                    view.window?.makeFirstResponder(cellView.textField)
                }
                rowToAdd = -1
            }
        }
    }
}
