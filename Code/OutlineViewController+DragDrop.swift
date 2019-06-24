/*
Drag and Drop support for OutlineViewController.
*/

import Cocoa

// Drag and Drop support, our custom pasteboard type.
extension NSPasteboard.PasteboardType {
	// This is a UTI string should be a unique identifier.
    static let nodeRowPasteBoardType =
        NSPasteboard.PasteboardType("YAMLEditor.LocaLoca.internalNodeDragType")
}

// MARK: -

extension OutlineViewController: NSFilePromiseProviderDelegate {
    // MARK: NSFilePromiseProviderDelegate

    // Return the name of the file being promised.

    // This is called before the drag has completed. Return the base filename.
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        // Default to using "Untitled" for the file.
        var title = NSLocalizedString("untitled string", comment: "")

        if let dragURL = NodePasteboardWriter.urlFromFilePromiseProvider(filePromiseProvider) {
            title = dragURL.lastPathComponent // Use the URL for the title.
        } else {
            if let dragName = nameFromFilePromiseProvider(filePromiseProvider) {
                title = dragName + ".png" // Use the name for the title.
            }
        }
        return title
    }

    /** This is called as the drag finishes. The URL is the full path to write (including the filename).
		Write the file being promised, we only write out image documents.
		Be sure to call the completion handler.
 	*/
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        if let dragURL = NodePasteboardWriter.urlFromFilePromiseProvider(filePromiseProvider) {
            // We have a URL for this node.
            if dragURL.isImage {
                // The url is an image file, make the copy.
                do {
                    try FileManager.default.copyItem(at: dragURL, to: url)
                } catch let error {
                    handleError(error)
                    completionHandler(error)
                    return
                }
            }
        } else {
            // Dragged node has no URL, copy the image data to the destination url.

            // It is a non-url image node (built in from the app), so load its image.
            if let dragName = nameFromFilePromiseProvider(filePromiseProvider) {
                if let loadedImage = NSImage(named: dragName) {
                    // Convert the NSImage to Data for writing.
                    if let pngData = loadedImage.pngData() {
                        do {
                            try pngData.write(to: url)
                        } catch let error {
                            handleError(error)
                            completionHandler(error)
                            return
                        }
                    }
                }
            }
        }
		completionHandler(nil)
    }

    // OperationQueue function for handlng file promise dragging.
    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        return workQueue
    }

    // MARK: Utilities

    // Obtain the file name to promise from the provider.
    func nameFromFilePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider) -> String? {
        var dragName: String?
        // Find the name.
        if let userInfo = filePromiseProvider.userInfo as? [String: Any] {
            dragName = userInfo[NodePasteboardWriter.UserInfoKeys.name] as? String
        }
        return dragName
    }
}

// MARK: -

extension OutlineViewController: NSOutlineViewDataSource {
    // MARK: Drag and Drop

    /**	An internal drag has started, here we decide what kind of pasteboard writer we want:
 		either NodePasteboardWriter or a non-file promiser writer.
  		This will be called for each item in the selection that will be dragged.
	*/
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        // guard let dragNode = OutlineViewController.node(from: item) else { return nil }

        let rowIdx = outlineView.row(forItem: item)
        let pasteboardItem = NSPasteboardItem()

        // Remember the dragged node by its row number for later.
        let propertyList = [NodePasteboardWriter.UserInfoKeys.row: rowIdx]
        pasteboardItem.setPropertyList(propertyList, forType: .nodeRowPasteBoardType)
        return pasteboardItem
    }

    // Utility function to detect if the user is dragging an item into its descendants.
    private func okToDrop(draggingInfo: NSDraggingInfo, locationItem: NSTreeNode?) -> Bool {
        var droppedOntoItself = false
        draggingInfo.enumerateDraggingItems(options: [],
                                            for: outlineView,
                                            classes: [NSPasteboardItem.self],
                                            searchOptions: [:]) { dragItem, _, _ in
      		if let droppedPasteboardItem = dragItem.item as? NSPasteboardItem {
                if let checkItem = self.itemFromPasteboardItem(droppedPasteboardItem) {
                    // Start at the the root and recursively search.
                    let treeRoot = self.treeController.arrangedObjects
                    let node = treeRoot.descendant(at: checkItem.indexPath)
                    var parent = locationItem
                    while parent != nil {
                        if parent == node {
                            droppedOntoItself = true
                            break
                        }
                        parent = parent?.parent
                    }
                }
			}
        }
        return !droppedOntoItself
    }

    /** This is called during a drag over the outline view, before the drop occurs.
        It is used by the outline view to determine a visual drop target.
        Use this function to specify how to respond to a proposed drop operation.
    */
    func outlineView(_ outlineView: NSOutlineView,
                     validateDrop info: NSDraggingInfo,
                     proposedItem item: Any?, // The place the drop is hovering over.
                     proposedChildIndex index: Int) -> NSDragOperation { // The child index the drop is hovering over.
        var result = NSDragOperation()

        guard index != -1, 	// Don't allow dropping on a child.
            	item != nil	// Make sure we have a valid outline view item to drop on.
        else { return result }

        // Find the node we are dropping onto.
        if let dropNode = OutlineViewController.node(from: item as Any) {
            // Current drop location is inside container.
            if info.draggingPasteboard.availableType(from: [.nodeRowPasteBoardType]) != nil {
                // Drag source is from within our outline view.
                if dropNode.isLeaf {
                    result = .move
                } else {
                    // Check if we are dropping onto ourselves.
                    if okToDrop(draggingInfo: info, locationItem: item as? NSTreeNode) {
                        result = .move
                    }
                }
            } else if info.draggingPasteboard.availableType(from: [.fileURL]) != nil {
                // Drag source is from outside app as a file URL, so a drop means adding a link/reference.
                result = .link
            } else {
                // Drag source is from outside this app, likely a file prompse, to it's going to be a copy.
                result = .copy
            }
        }

        return result
    }

    // User is doing a drop or intra-app drop within the outline view.
    private func handleInternalDrops(_ outlineView: NSOutlineView, draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
        // Accumulate all drag items and move them to the proper indexPath.
        var itemsToMove = [NSTreeNode]()

        draggingInfo.enumerateDraggingItems(options: [],
                                    		for: outlineView,
                                    		classes: [NSPasteboardItem.self],
                                    		searchOptions: [:]) { dragItem, _, _ in
            if let droppedPasteboardItem = dragItem.item as? NSPasteboardItem {
                if let itemToMove = self.itemFromPasteboardItem(droppedPasteboardItem) {
                    itemsToMove.append(itemToMove)
                }
			}
        }

   	 	treeController.move(itemsToMove, to: indexPath)
    }

    /** Accept the drop.
     	The following function is called when the user finishes dragging one or more objects.
     	This is called when the mouse is released over an outline view that previously decided to
     	allow a drop via the validateDrop method. Here you will handle the data from the dragging
     	pasteboard being dropped on the outline view.

     	The param 'index' is the location to insert the data as a child of 'item', and are the
     	values previously set in the validateDrop: method.

     	Note that "targetItem" is a NSTreeNode proxy node.
     */
    func outlineView(_ outlineView: NSOutlineView,
                     acceptDrop info: NSDraggingInfo,
                     item targetItem: Any?,
                     childIndex index: Int) -> Bool {
        // Find the index path to insert our dropped object(s).
        if let dropIndexPath = droppedIndexPath(item: targetItem, childIndex: index) {
            // Check the dragging type.
            if info.draggingPasteboard.availableType(from: [.nodeRowPasteBoardType]) != nil {
                // The user dropped one of our own items.
                handleInternalDrops(outlineView, draggingInfo: info, indexPath: dropIndexPath)
            } else {
                // The user is dropped items from the Finder or so
                // TODO: handle?
            }
        }
        return true
    }

    /** Called when the dragging session has ended. Use this to know when the dragging source
    	operation ended at a specific location, such as the trash (by checking for an
 		operation of NSDragOperationDelete).
 	*/
    func outlineView(_ outlineView: NSOutlineView,
                     draggingSession session: NSDraggingSession,
                     endedAt screenPoint: NSPoint,
                     operation: NSDragOperation) {
        if operation == .delete,
            let items = session.draggingPasteboard.pasteboardItems {
            var itemsToRemove = [Node]()

            // Find the items being dragged to the trash (as a dictionary containing their row numbers).
            for draggedItem in items {
                if let item = itemFromPasteboardItem(draggedItem) {
                    if let itemToRemove = OutlineViewController.node(from: item) {
                        itemsToRemove.append(itemToRemove)
                    }
                }
            }
            removeItems(itemsToRemove)
        }
    }

    // MARK: Utilities

    func handleError(_ error: Error) {
        OperationQueue.main.addOperation {
            if let window = self.view.window {
                self.presentError(error, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
            } else {
                self.presentError(error)
            }
        }
    }

    // Utility functon to return convert a NSPasteboardItem to a NSTreeNode.
    private func itemFromPasteboardItem(_ item: NSPasteboardItem) -> NSTreeNode? {
        // Obtain the property list and find the row number of the node being dragged.
        guard let itemPlist = item.propertyList(forType: .nodeRowPasteBoardType) as? [String: Any],
            let rowIndex = itemPlist[NodePasteboardWriter.UserInfoKeys.row] as? Int else { return nil }

        // Ask the outline view for the tree node.
        return outlineView.item(atRow: rowIndex) as? NSTreeNode
    }

    // Find the index path to insert our dropped object(s).
    private func droppedIndexPath(item targetItem: Any?, childIndex index: Int) -> IndexPath? {
        let dropIndexPath: IndexPath?

        if targetItem != nil {
            // Drop down inside the tree node: fetch the index path to insert our dropped node.
            dropIndexPath = (targetItem! as AnyObject).indexPath!.appending(index)
        } else {
            // Drop at the top root level.
            if index == -1 { // Drop area might be ambiguous (not at a particular location).
                dropIndexPath = IndexPath(index: contents.count) // Drop at the end of the top level.
            } else {
                dropIndexPath = IndexPath(index: index) // Drop at a particular place at the top level.
            }
        }
        return dropIndexPath
    }
}
