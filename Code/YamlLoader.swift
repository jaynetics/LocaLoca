import Foundation
import Yams

class YamlLoader {
    class Result {
        var dict: [String: Any]
        var localesByFile: [URL: String]

        init(dict: [String: Any], localesByFile: [URL: String]) {
            self.dict = dict
            self.localesByFile = localesByFile
        }
    }

    class func load(_ yamls: [URL]) -> Result {
        do {
            let result = try readLocaleYamls(yamls)
            //NSLog("%@", result)
            return result
        } catch {
            Warning.show("Failed to load and parse yml files")
            return Result(dict: [:], localesByFile: [:])
        }
    }
    
    private class func readLocaleYamls(_ urls: [URL]) throws -> Result {
        NSLog("parsing yaml ...")
        var dict: [String: Any] = [:]
        var localesByFile: [URL: String] = [:]
        var skippedFiles: [URL] = []
        for url in urls {
            let content = try String(contentsOf: url).trimmingCharacters(in: .whitespacesAndNewlines)
            let data = try Yams.compose(yaml: content)!
            let root = data.mapping?.first
            if supportedLocaleYaml(root: root, url: url) {
                let locale = root!.key.scalar!.string
                localesByFile[url] = locale
                for (key, value) in root!.value.mapping ?? [:] {
                    parseYamsNode(value, into: &dict, at: key.scalar!.string, locale: locale)
                }
            } else {
                skippedFiles.append(url)
            }
        }
        warnIfSkippedFiles(skippedFiles)
        NSLog("parsing yaml done")
        return Result(dict: dict, localesByFile: localesByFile)
    }
    
    private class func supportedLocaleYaml(root: Yams.Node.Mapping.Element?, url: URL) -> Bool {
        guard let rootKey = root?.key.scalar?.string else { return false }
        let fileBaseName = url.deletingPathExtension().lastPathComponent
        return rootKey == fileBaseName
    }
    
    private class func parseYamsNode(_ node: Yams.Node, into dict: inout [String: Any], at: String, locale: String) {
        var subdict = fetchSubdict(dict, at: at)
        
        if let mapping = node.mapping {
            // branch node, parse recursively
            for (index, el) in mapping.enumerated() {
                if index > 0 { subdict = fetchSubdict(dict, at: at) }
                parseYamsNode(el.value, into: &subdict, at: el.key.scalar!.string, locale: locale)
                dict[at] = subdict
            }
        } else if let sequence = node.sequence {
            // array node, convert to dict with index numbers as keys
            // TODO: this is super dirty, but not all that important, I guess.
            // Check .isSequenceContainer assignment and sorting when cleaning this up.
            for (index, el) in sequence.enumerated() {
                var idx = String(index)
                while idx.count < 4 { idx = "0\(idx)" }
                parseYamsNode(el, into: &subdict, at: "[\(idx)]", locale: locale)
            }
        } else {
            // leaf node, build dict of translations
            subdict[locale] = node.scalar?.string ?? ""
        }
        
        dict[at] = subdict
    }
    
    private class func fetchSubdict(_ dict: [String: Any], at: String) -> [String: Any] {
        if let existingSubdict = dict[at] as? [String: Any] {
            return existingSubdict
        } else {
            return [:]
        }
    }
    
    private class func warnIfSkippedFiles(_ skippedFiles: [URL]) {
        if skippedFiles.isEmpty { return }

        Warning.show("""
        The following files are not valid locale files and will be ignored.
            
        Only files with one top-level key that matches the filename are supported.
            
        \(skippedFiles.map({ $0.lastPathComponent }).joined(separator: ", "))
        """, suppressIdentifier: skippedFiles.first!.deletingLastPathComponent().path)
    }
}
