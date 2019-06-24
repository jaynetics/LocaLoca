import Cocoa

extension YamlFinder {
    class func stubNestedExists(_ bool: Bool) {
        YamlFinder.fileManager = DummyFileManager()
        DummyFileManager.nextFileExists = bool
    }
    
    class func stubDirContents(_ paths: [String]) {
        YamlFinder.fileManager = DummyFileManager()
        DummyFileManager.nextContentsOfDirectory = paths
    }
}

class DummyFileManager: FileManager {
    static var nextFileExists: Bool?
    static var nextContentsOfDirectory: [String]?
    
    override func fileExists(atPath path: String) -> Bool {
        if DummyFileManager.nextFileExists == nil {
            return super.fileExists(atPath: path)
        }
        return DummyFileManager.nextFileExists!
    }
    
    override func contentsOfDirectory(atPath path: String) throws -> [String] {
        if DummyFileManager.nextContentsOfDirectory == nil {
            return try super.contentsOfDirectory(atPath: path)
        }
        return DummyFileManager.nextContentsOfDirectory!
    }
}
