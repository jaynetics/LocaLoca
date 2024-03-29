/*
Custom NSFilePromiseProvider is used for:
	- Our own custom drag type (.nodeRowPasteBoardType)
  	- File URL (.fileURL)
 	- file promise drag
 If a node to drag is a file that can be promised to the destination, and dragged within it's own outline view.
*/

import Cocoa

class NodePasteboardWriter: NSFilePromiseProvider {
    // MARK: UserInfo Keys

    struct UserInfoKeys {
        static let row = "rowKey" // The row number representing the node.
        static let url = "urlKey" // The url of the node.
        static let name = "nameKey" // The node name.
    }

    // MARK: Utilities

 	// Obtain the url to promise from the provider.
    class func urlFromFilePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider) -> URL? {
        guard let userInfo = filePromiseProvider.userInfo as? [String: Any] else { return nil }

        var dragURL: URL?
        // Find the url.
        if let urlString = userInfo[NodePasteboardWriter.UserInfoKeys.url] as? String {
            if !urlString.isEmpty {
                dragURL = URL(string: urlString)
            }
        }
        return dragURL
    }

    // Directory for writing images from out built-in asset library to for non-promise file URL drag and drop.
    lazy var dragDestinationURL: URL = {
        let dragDestinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Drag")
        try? FileManager.default.createDirectory(at: dragDestinationURL, withIntermediateDirectories: true, attributes: nil)
        return dragDestinationURL
    }()

    // MARK: NSPasteboardWriting

    override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        var types = super.writableTypes(for: pasteboard)

        // In addition to promise files, we add our internal pasteboard type, and fileURL.
        types.append(.nodeRowPasteBoardType)
        types.append(.fileURL)
        return types
    }

    // Return the property list for the given pasteboard type.
    override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        guard let userInfoDict = userInfo as? [String: Any] else { return nil }

        switch type {
        case .nodeRowPasteBoardType:
            // The pasteboard type is our internal node drag, use the userInfo as the property list.
            return userInfo
        case .fileURL:
            // The pasteboard type is for file URL.
            if let urlString = userInfoDict[NodePasteboardWriter.UserInfoKeys.url] as? String {
                if urlString.isEmpty {
                    // No URL, copy the internal image asset to disk, and return it's URL.
                    if let imageName = userInfoDict[NodePasteboardWriter.UserInfoKeys.name] as? String {
                        try? FileManager.default.createDirectory(at: dragDestinationURL, withIntermediateDirectories: true, attributes: nil)

                        let imageFileURL = dragDestinationURL.appendingPathComponent(imageName)
                        if let loadedImage = NSImage(named: imageName) {
                            // Convert the NSImage to Data for writing.
                            if let pngData = loadedImage.pngData() {
                                do {
                                    try pngData.write(to: imageFileURL)
                                } catch let error {
                                    debugPrint(error)
                                }
                            }
                            return imageFileURL.absoluteString
                        }
                    }
                } else {
                    // Node has a URL, return it's string equivalent.
                    return urlString
                }
            }
        default:
            // The pasteboard type could be a file promise, the super class can determine the property list.
            return super.pasteboardPropertyList(forType: type)
        }
        return nil
    }
}
