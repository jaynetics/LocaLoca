import Cocoa

class RecentlyOpened {
    private static let key = "LocaLocaRecentlyOpenedDirs"

    class var items: [URL] {
        let arr = UserDefaults.standard.stringArray(forKey: key) ?? []
        return arr.map { URL(fileURLWithPath: $0) }
    }
    
    class func add(_ url: URL) {
        let newRecent = [url] + items.filter({ $0.path != url.path })
        set(newRecent)
    }
    
    class func remove(_ url: URL) {
        set(items.filter({ $0.path == url.path }))
    }
    
    class func removeAll() {
        set([])
    }
    
    private class func set(_ urls: [URL]) {
        let first10paths = urls.prefix(10).map { $0.path }
        UserDefaults.standard.set(first10paths, forKey: key)
        let delegate = NSApplication.shared.delegate as? AppDelegate?
        delegate??.recentMenu.setup()
    }
}
