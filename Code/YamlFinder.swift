import Cocoa

class YamlFinder {
    static var fileManager = FileManager.default

    struct Result {
        let dir: URL
        let files: [URL]
        var success: Bool
    }
    
    class func openUrl(_ dirUrl: URL) -> Result {
        let result = localeYamlsInDir(dirUrl)
        if !result.success {
            Warning.show("no yamls found in \(dirUrl)")
        }
        return result
    }

    private class func localeYamlsInDir(_ dirUrl: URL) -> Result {
        let searchUrl = determineSearchUrl(dirUrl)
        NSLog("looking for yamls in \(searchUrl)")

        let yamlUrls = yamlsInDir(searchUrl)
        NSLog("found yamls: \(yamlUrls)")

        return Result(dir: searchUrl, files: yamlUrls, success: !yamlUrls.isEmpty)
    }
    
    private class func determineSearchUrl(_ baseUrl: URL) -> URL {
        // also check `./config/locales` so opening the base app dir works, too
        let nestedUrl = baseUrl
            .appendingPathComponent("config", isDirectory: true)
            .appendingPathComponent("locales", isDirectory: true)
        
        if fileManager.fileExists(atPath: nestedUrl.path) {
            return nestedUrl
        }
        else {
            return baseUrl
        }
    }
    
    private class func yamlsInDir(_ dirUrl: URL) -> [URL] {
        do {
            let searchPath = dirUrl.path
            let fileList = try fileManager.contentsOfDirectory(atPath: searchPath)
            // get all ymls without extra dots in the filename
            return fileList
                .filter( { $0.hasSuffix(".yml") && $0.components(separatedBy: ".").count == 2 })
                .map( { URL(fileURLWithPath: searchPath + "/" + $0) })
        } catch {
            return []
        }
    }
}
