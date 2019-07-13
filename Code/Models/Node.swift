/*
Generic multi-use node object used with NSOutlineView and NSTreeController.
*/

import Cocoa

enum NodeType: Int, Codable {
    case container
    case document
    case sequence
    case unknown
}

class Node: NSObject, Codable, SaneNotifications {
    var type: NodeType = .unknown
    var fullKey: String = "" {
        didSet {
            self.ownKey = "\(fullKey.split(separator: ".").last!)"
            // if the Node has children, changing the fullKey triggers
            // recursive updates.
            for child in children {
                child.updateFullKey(replacePrefix: oldValue, with: fullKey)
            }
        }
    }
    var ownKey: String = ""
    var translations: [String: String]? = nil
    @objc dynamic var children = [Node]()
    
    init(fullKey: String) {
        super.init()
        defer { self.fullKey = fullKey } // defer to make it call didSet
    }
    
    func updateFullKey(newSuffix: String) {
        var parts = fullKey.split(separator: ".").map { String($0) }
        parts.removeLast()
        fullKey = (parts + [newSuffix]).joined(separator: ".")
        postUpdateNotification()
    }
    
    func updateFullKey(replacePrefix oldPrefix: String, with newPrefix: String) {
        let firstOccurenceRange = fullKey.range(of: oldPrefix)!
        fullKey = fullKey.replacingCharacters(in: firstOccurenceRange, with: newPrefix)
        postUpdateNotification()
    }
    
    func updateTranslation(locale: String, value: String) {
        guard translations?[locale] != value else { return }
        translations?[locale] = value
        postUpdateNotification()
    }
    
    struct Notifications {
        static let updated = "NodeUpdated"
    }
        
    private func postUpdateNotification() {
        post(Notifications.updated, object: self)
    }
}

extension Node {
    @objc dynamic var isLeaf: Bool {
        return type == .document
    }

    override class func description() -> String {
        return "Node"
    }

    var icon: NSImage {
        var osType: Int
        if      isLeaf            { osType = kGenericDocumentIcon }
        else if type == .sequence { osType = kGenericStationeryIcon }
        else                      { osType = kGenericFolderIcon }

        let iconType = NSFileTypeForHFSTypeCode(OSType(osType))
        return NSWorkspace.shared.icon(forFileType: iconType!)
    }
    
    func searchScore(_ query: String) -> Double {
        if fullKey == query            { return 1.0 }
        if fullKey.contains(query)     { return 0.5 }
        if translations != nil {
            for val in translations!.values {
                if val == query        { return 0.7 }
                if val.contains(query) { return 0.3 }
            }
        }
        return 0.0
    }
}
