/*
Contextual menu support for OutlineViewController.
*/

import Cocoa

/** Support for outline view contextual menu.
 This allows the delegate to determine the contextual menu for the outline view.
 */
protocol CustomMenuDelegate: AnyObject {
    // Construct a context menu based the current selected rows.
    func outlineViewMenuForRows(_ outlineView: NSOutlineView, rows: IndexSet) -> NSMenu?
}

extension OutlineViewController: CustomMenuDelegate {
    enum MenuItemTags: Int {
        case removeTag = 1 // Remove item.
        case renameTag // Rename item.
        case addTranslationTag // Add a translation.
        case addFolderTag // Add a folder.
    }

    @objc
    // The sender is the menu item issuing the contextual menu command.
    private func handleContextualMenu(_ sender: AnyObject) {
        // Expect the sender to be an NSMenuItem, and it's representedObject to be an IndexSet (of nodes).
        guard let menuItem = sender as? NSMenuItem,
            let selectionIndexes = menuItem.representedObject as? IndexSet else { return }

        if selectionIndexes.count > 1 {
            var nodesToRemove = [Node]()
            for item in selectionIndexes {
                if let rowItem = outlineView.item(atRow: item),
                	let node = OutlineViewController.node(from: rowItem) {
                        nodesToRemove.append(node)
                    }
            }
            removeItems(nodesToRemove)
        } else {
            // Expect the first item, first item being a tree node, and ultimately a Node class.
            guard let item = selectionIndexes.first,
                let rowItem = outlineView.item(atRow: item),
                let node = OutlineViewController.node(from: rowItem) else { return }

            switch menuItem.tag {
            case MenuItemTags.removeTag.rawValue:
                // Remove the node.
                removeItems([node])

            case MenuItemTags.renameTag.rawValue:
                // Force edit the node's name text field.
                let view = outlineView.view(atColumn: 0, row: item, makeIfNecessary: false)
                if let cellView = view as? NSTableCellView {
                    view?.window?.makeFirstResponder(cellView.textField)
                }

            case MenuItemTags.addTranslationTag.rawValue:
                // Add a translation object to the menu item's representedObject.
                if let item = outlineView.item(atRow: item) as? NSTreeNode,
                    let addToNode = OutlineViewController.node(from: item) {
                        addTranslationAtItem(addToNode)
                }

            case MenuItemTags.addFolderTag.rawValue:
                // Add an empty folder to the menu item's representedObject (the row number of the outline view).
                if let rowItem = outlineView.item(atRow: item) as? NSTreeNode {
                    addFolderAtItem(rowItem)
                }

            default: break
            }
        }
    }

    /** Utility factory function to make a contextual menu item from inputs.
    	Each contextual menu item is constructed with:
    		tag: Used to determine the what the menu item actually does.
    		representedObject: the set of rows to act on.
	*/
    private func contextMenuItem(_ title: String, tag: Int, representedObject: Any) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title,
                                  action: #selector(OutlineViewController.handleContextualMenu),
                                  keyEquivalent: "")
        menuItem.tag = tag
        menuItem.representedObject = representedObject
        return menuItem
    }

    /** Return the contextual menu for the given set of outline view rows.
		Each contextual menu item is constructed with:
 			tag: Used to determine the what the menu item actually does.
 			representedObject: the set of rows to act on.
 	*/
    func outlineViewMenuForRows(_ outlineView: NSOutlineView, rows: IndexSet) -> NSMenu? {
        let contextMenu = NSMenu(title: "")

        // For multiple selected rows, we only offer the "remove" command.
        if rows.count > 1 {
            // Contextual menu for mutiple selection.
            let removeMenuItemTitle = NSLocalizedString("context remove string multiple", comment: "")
            contextMenu.addItem(contextMenuItem(removeMenuItemTitle,
                                                tag: MenuItemTags.removeTag.rawValue,
                                                representedObject: rows))
        } else {
            // Contextual menu for single selection.

            // We must have a selected row.
            guard !rows.isEmpty,
                // We must have an item at that row.
                let item = outlineView.item(atRow: rows.first!),
                	// We must have a node from that item.
                	let node = OutlineViewController.node(from: item) else { return contextMenu }

            // Item is a non-url file object, so we can remove or rename it.
            //
   			let removeItemFormat = NSLocalizedString("context remove string", comment: "")
            let removeMenuItemTitle = String(format: removeItemFormat, node.ownKey)
            contextMenu.addItem(contextMenuItem(removeMenuItemTitle,
                                                tag: MenuItemTags.removeTag.rawValue,
                                                representedObject: rows))

            let renameItemFormat = NSLocalizedString("context rename string", comment: "")
            let renameMenuItemTitle = String(format: renameItemFormat, node.ownKey)
            contextMenu.addItem(contextMenuItem(renameMenuItemTitle,
                                                tag: MenuItemTags.renameTag.rawValue,
                                                representedObject: rows))

            if !node.isLeaf {
                contextMenu.addItem(contextMenuItem(NSLocalizedString("add translation", comment: ""),
                                                    tag: MenuItemTags.addTranslationTag.rawValue,
                                                    representedObject: rows))

                contextMenu.addItem(contextMenuItem(NSLocalizedString("add folder", comment: ""),
                                                    tag: MenuItemTags.addFolderTag.rawValue,
                                                    representedObject: rows))
            }
        }
        return contextMenu
    }
}
