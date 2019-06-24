/*
The master view controller containing the NSOutlineView and NSTreeController.
*/

import Cocoa

class OutlineViewController: NSViewController,
    NSTextFieldDelegate,
NSUserInterfaceValidations { // To enable/disable menu items for the outline view.
    
    struct Notifications {
        static let working          = "WorkingNotification"
        static let workDone         = "WorkDoneNotification"
        static let searchCompleted  = "SearchCompletedNotification"
        static let selectionChanged = "SelectionChangedNotification"
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var treeController: NSTreeController!
    @IBOutlet weak var outlineView: OutlineView!
    
    // MARK: Instance Variables
    
    private var treeControllerObserver: NSKeyValueObservation?
    @objc dynamic var contents: [AnyObject] = []
    private var locales: Set<String> = Set()
    private var openedDir: URL? = nil

    var rowToAdd = -1 // A flagged row being added (for later renaming after it was added).
    
    private var iconViewController: IconViewController!
    private var valueViewController: ValueViewController!
    private var multipleItemsViewController: NSViewController!
    
    var savedSelection: [IndexPath] = []
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayoutsAndDelegates()
        setupObservers()
    }
    
    private func setupLayoutsAndDelegates() {
        // We want to determine the contextual menu for the outline view.
        outlineView.customMenuDelegate = self
        
        // Dragging items out: Set the default operation mask so we can drag (copy) items to outside this app, and delete to the Trash can.
        outlineView?.setDraggingSourceOperationMask([.copy, .delete], forLocal: false)
        
        // Register for drag types coming in, we want to receive file promises from Photos, Mail, Safari, etc.
        outlineView.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        
        // We are interested in these drag types: our own type (outline row number), and for fileURLs.
        outlineView.registerForDraggedTypes([
            .nodeRowPasteBoardType, // Our internal drag type, the outline view's row number for internal drags.
            NSPasteboard.PasteboardType.fileURL // To receive file URL drags.
            ])
        
        // Load the icon view controller from storyboard later use as our Detail view.
        iconViewController =
            storyboard!.instantiateController(withIdentifier: "IconViewController") as? IconViewController
        iconViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Load the icon view controller from storyboard later use as our Detail view.
        valueViewController =
            storyboard!.instantiateController(withIdentifier: "ValueViewController") as? ValueViewController
        valueViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Load the multiple items selected view controller from storyboard later use as our Detail view.
        multipleItemsViewController =
            storyboard!.instantiateController(withIdentifier: "MultipleSelection") as? NSViewController
        multipleItemsViewController.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupObservers() {
        listen(AppDelegate.Notifications.save, react: #selector(save(_:)))
        listen(AppDelegate.Notifications.yamlsFound, react: #selector(yamlDirOpened(_:)))
        listen(IconViewController.Notifications.selectedNode, react: #selector(selectItem(_:)))
        listen(Node.Notifications.updated, react: #selector(nodeUpdated(_:)))
        listen(WindowViewController.Notifications.addFolder, react: #selector(addFolder(_:)))
        listen(WindowViewController.Notifications.addLocale, react: #selector(addLocale(_:)))
        listen(WindowViewController.Notifications.addTranslation, react: #selector(addTranslation(_:)))
        listen(WindowViewController.Notifications.removeItem, react: #selector(removeItem(_:)))
        listen(WindowViewController.Notifications.searchChanged, react: #selector(searchChanged(_:)))
        
        // Listen to our treeController's selection changed so we can inform clients to react to selection changes.
        treeControllerObserver =
            treeController.observe(\.selectedObjects, options: [.new]) {(treeController, change) in
                // only notify if autoselect is enabled
                guard self.treeController.selectsInsertedObjects else { return }
                // Post this notification so other view controllers can react to the selection change.
                // (Interested view controllers are: WindowViewController and SplitViewController)
                self.post(Notifications.selectionChanged,
                    object: treeController)
                // Remember the saved selection for restoring selection state later.
                self.savedSelection = treeController.selectionIndexPaths
                self.invalidateRestorableState()
        }
    }
    
    deinit {
        unlisten(AppDelegate.Notifications.save)
        unlisten(AppDelegate.Notifications.yamlsFound)
        unlisten(IconViewController.Notifications.selectedNode)
        unlisten(Node.Notifications.updated)
        unlisten(WindowViewController.Notifications.addFolder)
        unlisten(WindowViewController.Notifications.addLocale)
        unlisten(WindowViewController.Notifications.addTranslation)
        unlisten(WindowViewController.Notifications.removeItem)
        unlisten(WindowViewController.Notifications.searchChanged)
    }
    
    // MARK: OutlineView Setup
    
    // Take the currently selected node and select its parent.
//    private func selectParentFromSelection() {
//        if !treeController.selectedNodes.isEmpty {
//            let firstSelectedNode = treeController.selectedNodes[0]
//            if let parentNode = firstSelectedNode.parent {
//                // Select the parent.
//                let parentIndex = parentNode.indexPath
//                treeController.setSelectionIndexPath(parentIndex)
//            } else {
//                // No parent exists (we are at the top of tree), so make no selection in our outline.
//                let selectionIndexPaths = treeController.selectionIndexPaths
//                treeController.removeSelectionIndexPaths(selectionIndexPaths)
//            }
//        }
//    }
    
    // MARK: Outline Content
    
    @objc
    private func yamlDirOpened(_ notif: Notification) {
        let result = notif.object as! YamlFinder.Result
        openedDir = result.dir
        self.populateFromYamls(result.files)
    }
    
    private func populateFromYamls(_ yamls: [URL]) {
        // Note that the nodeID and expansion restoration ID are shared.
        // TODO: Asynchronously parse the yamls?
        post(Notifications.working)
        
        clearData()
        let result = YamlLoader.load(yamls)
        for (url, locale) in result.localesByFile {
            if !useLocale(locale) {
                Warning.show("\(url) contains invalid or duplicate locale `\(locale)`")
            }
        }
        self.populateFromDict(result.dict)
    }
    
    private func clearData() {
        contents.removeAll()
        locales.removeAll()
    }
    
    private func populateFromDict(_ dict: [String: Any]) {
        // disable auto-select while populating
        treeController.selectsInsertedObjects = false
        outlineView.isHidden = true

        addNodes(dict, indexPath: IndexPath(index: contents.count))
        treeController.setSelectionIndexPath(nil)

        treeController.selectsInsertedObjects = true
        outlineView.isHidden = false

        post(Notifications.workDone)
        NSLog("adding nodes done")
    }

    private func addNodes(_ dict: [String: Any], indexPath: IndexPath, keyPath: [String] = []) {
        for key in dict.keys.sorted(by: { $0 > $1 }) {
            guard let subdict = dict[key] as? [String: Any] else {
                Warning.show("INVALID STRUCTURE:\n\n\(dict)")
                return
            }
            let nodeKeyPath = keyPath + [key]
            let node = Node(fullKey: nodeKeyPath.joined(separator: "."))
            if subdict.values.first is String {
                addLeafNode(node, translations: subdict as? [String: String], at: indexPath)
            }
            else {
                addBranchNode(node, children: subdict, at: indexPath, keyPath: nodeKeyPath)
            }
        }
    }
    
    private func addLeafNode(_ node: Node, translations: [String: String]?, at indexPath: IndexPath) {
        node.type = .document
        node.translations = translations
        treeController.insert(node, atArrangedObjectIndexPath: indexPath)
    }
    
    private func addBranchNode(_ node: Node, children: [String: Any], at indexPath: IndexPath, keyPath: [String]) {
        node.type = .container
        node.isSequenceContainer = children.keys.contains("[0000]")
        treeController.insert(node, atArrangedObjectIndexPath: indexPath)
        let pathIntoNewNode = indexPath.appending(0)
        addNodes(children, indexPath: pathIntoNewNode, keyPath: keyPath)
    }
    
    // MARK: Removal and Addition
    
    private func removalConfirmAlert(_ itemsToRemove: [Node]) -> NSAlert {
        let alert = NSAlert()
        
        if itemsToRemove.count > 1 {
            // Remove multiple items.
            alert.messageText = NSLocalizedString("remove multiple string", comment: "")
        } else {
            // Remove the single item.
            let messageStr = NSLocalizedString("remove confirm string", comment: "")
            alert.messageText = String(format: messageStr, itemsToRemove[0].ownKey)
        }
        
        alert.addButton(withTitle: NSLocalizedString("ok button title", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("cancel button title", comment: ""))
        
        return alert
    }
    
    // Called from handleContextualMenu() or the remove button.
    func removeItems(_ itemsToRemove: [Node]) {
        // Confirm the removal operation.
        let alert = removalConfirmAlert(itemsToRemove)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        
        // Remove the given set of node objects from the tree controller.
        var indexPathsToRemove = [IndexPath]()
        for item in itemsToRemove {
            if let indexPath = treeController.indexPathOfObject(anObject: item) {
                indexPathsToRemove.append(indexPath)
            }
        }
        treeController.removeObjects(atArrangedObjectIndexPaths: indexPathsToRemove)
        
        // Remove the current selection after the removal.
        treeController.setSelectionIndexPaths([])
    }
    
    // Remove the currently selected items.
    private func removeItems() {
        var nodesToRemove = [Node]()
        
        for item in treeController.selectedNodes {
            if let node = OutlineViewController.node(from: item) {
                nodesToRemove.append(node)
            }
        }
        removeItems(nodesToRemove)
    }
    
    /// - Tag: Delete
    // User chose the Delete menu item or pressed the delete key.
    @IBAction func delete(_ sender: AnyObject) {
        removeItems()
    }
    
    // Called from handleContextualMenu(), or add folder button.
    func addFolderAtItem(_ item: NSTreeNode) {
        // Obtain the base node at the given outline view's row number, and the indexPath of that base node.
        guard let target = OutlineViewController.node(from: item),
              let path = treeController.indexPathOfObject(anObject: target) else { return }
        
        // We are inserting a new group folder at the node index path, add it to the end.
        let newPath = path.appending(target.children.count)
        
        let nodeToAdd = Node(fullKey: target.fullKey + ".untitled")
        nodeToAdd.type = .container
        treeController.insert(nodeToAdd, atArrangedObjectIndexPath: newPath)
        
        // Flag the row we are adding (for later renaming after the row was added).
        rowToAdd = outlineView.row(forItem: item) + target.children.count
    }
    
    // Called from handleContextualMenu() or add translation button.
    func addTranslationAtItem(_ item: Node) {
        // Present an open panel to choose a translation to display in the outline view.
        let openPanel = NSOpenPanel()
        
        // Find a translation to add.
        let locationTitle = item.fullKey
        let messageStr = NSLocalizedString("enter key message", comment: "")
        openPanel.message = String(format: messageStr, locationTitle)
        openPanel.prompt = NSLocalizedString("open panel prompt", comment: "") // Set the Choose button title.
        openPanel.canCreateDirectories = false
        
        // We should allow choosing all kinds of image files that CoreGraphics can handle.
        if let imageTypes = CGImageSourceCopyTypeIdentifiers() as? [String] {
            openPanel.allowedFileTypes = imageTypes
        }
        
        guard openPanel.runModal() == .OK,
              let target = OutlineViewController.node(from: item),
              let path = treeController.indexPathOfObject(anObject: item) else { return }
        
        let newPath = path.appending(target.children.count)

        // Create a leaf node.
        let node = Node(fullKey: target.fullKey + ".untitled")
        node.type = .document
        treeController.insert(node, atArrangedObjectIndexPath: newPath)
    }
    
    // MARK: Notifications
    
    // Notification sent from WindowViewController class, to add a generic folder to the current selection.
    @objc
    private func addFolder(_ notif: Notification) {
        // Add the folder with "untitled" title.
        let selectedRow = outlineView.selectedRow
        if let folderToAddNode = outlineView.item(atRow: selectedRow) as? NSTreeNode {
            addFolderAtItem(folderToAddNode)
        }
        // Flag the row we are adding (for later renaming after the row was added).
        rowToAdd = outlineView.selectedRow
    }
    
    // Notification sent from WindowViewController class, to add a translation to the selected folder node.
    @objc
    private func addTranslation(_ notif: Notification) {
        let selectedRow = outlineView.selectedRow
        
        if let item = outlineView.item(atRow: selectedRow) as? NSTreeNode,
            let addToNode = OutlineViewController.node(from: item) {
            addTranslationAtItem(addToNode)
        }
    }
    
    @objc
    private func addLocale(_ notif: Notification) {
        guard let locale = Dialog.ask(
            "Please enter a locale (only a-z, _, - are allowed)",
            withTextInput: true,
            buttonTitle: "Save"
        ).answer else { return }

        if useLocale(locale) {
            markAsDirty()
        } else {
            Warning.show("invalid or duplicate locale `\(locale)`")
        }
    }
    
    private func markAsDirty() {
        let delegate = NSApplication.shared.delegate as? AppDelegate?
        delegate??.hasChangesToSave = true
        outlineView.reloadData()
    }
    
    private func useLocale(_ locale: String) -> Bool {
        guard let sanitized = YamlKey(name: locale).sanitized,
                  locales.insert(sanitized).inserted else { return false }
        valueViewController.locales = locales.sorted()
        return true
    }
    
    @objc
    private func save(_ notif: Notification) {
        let saveDir = notif.object as? URL ?? openedDir!
        YamlSaver.save(contents, locales: locales, to: saveDir)
    }
    
    // Notification sent from WindowViewController remove button, to remove a selected item from the outline view.
    @objc
    private func removeItem(_ notif: Notification) {
        removeItems()
    }

    @objc
    private func searchChanged(_ notif: Notification) {
        let query = notif.object! as! String
        if query.isEmpty {
            Search.current?.cancel()
            // restore appropriate state for outline view selection
            post(Notifications.selectionChanged,
                 object: treeController)
        } else {
            Search.launch(query, in: contents as! [Node], callback: { nodes in
                self.valueViewController.nodes = nodes
                self.post(Notifications.searchCompleted, object: query)
            })
        }
    }
    
    @objc
    private func selectItem(_ notif: Notification) {
        guard let node = notif.object as? Node,
              let path = treeController.indexPathOfObject(anObject: node) else { return }

        treeController.setSelectionIndexPath(path)
    }
    
    @objc
    private func nodeUpdated(_ notif: Notification) {
        markAsDirty()
    }
    
    // MARK: NSTextFieldDelegate
    
    // For a text field in each outline view item, the user commits the edit operation.
    func controlTextDidEndEditing(_ notif: Notification) {
        // Commit the edit by applying the text field's text to the current node.
        guard let item = outlineView.item(atRow: outlineView.selectedRow),
              let node = OutlineViewController.node(from: item),
              let textField = notif.object as? NSTextField else { return }
        
        node.updateFullKey(newSuffix: textField.stringValue)
    }
    
    // MARK: NSValidatedUserInterfaceItem
    
    /// - Tag: DeleteValidation
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(delete(_:)) {
            return !treeController.selectedObjects.isEmpty
        }
        return true
    }
    
    // MARK: Detail View Management
    
    // Used to decide which view controller to use as the detail.
    func viewControllerForSelection(_ selection: [NSTreeNode]?) -> NSViewController? {
        guard let outlineViewSelection = selection else { return nil }
        
        var viewController: NSViewController?
        
        switch outlineViewSelection.count {
        case 0:
            // No selection.
            viewController = nil
        case 1:
            // Single selection.
            if let node = OutlineViewController.node(from: selection?[0] as Any) {
                if node.isLeaf {
                    valueViewController.nodes = [node]
                    viewController = valueViewController
                } else {
                    iconViewController.node = node
                    viewController = iconViewController
                }
            }
        default:
            // Selection is multiple or more than one.
            viewController = multipleItemsViewController
        }
        
        return viewController
    }
    
    var viewControllerForSearch: NSViewController {
        return valueViewController
    }
    
    // MARK: File Promise Drag Handling
    
    /// Queue used for reading and writing file promises.
    lazy var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()
}
