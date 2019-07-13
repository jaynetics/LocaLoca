import Foundation
import Yams

class YamlLoader {
    class Result {
        var nodes: [Node]
        var localesByFile: [URL: String]

        init(nodes: [Node], localesByFile: [URL: String]) {
            self.nodes = nodes
            self.localesByFile = localesByFile
        }
    }

    class func load(_ yamlUrls: [URL]) -> Result {
        return YamlLoader(yamlUrls).load()
    }
    
    private var yamlUrls: [URL]
    private var nodes = [Node]()
    private var seenFullKeys = [String: Node]()
    private var localesByFile = [URL: String]()
    private var skippedFiles = [URL]()
    
    fileprivate init(_ yamlUrls: [URL]) {
        self.yamlUrls = yamlUrls
    }
    
    private func load() -> Result {
        do {
            try parseLocaleYamls()
        } catch {
            Warning.show("Failed to load and parse yml files")
        }
        warnIfSkippedFiles()
        return Result(nodes: nodes, localesByFile: localesByFile)
    }
    
    private func parseLocaleYamls() throws {
        for (url, root) in try getSupportedRootNodesByFile() {
            let base = root.mapping!.first!
            let locale = base.key.scalar!.string
            localesByFile[url] = locale
            for (key, value) in sortedMapping(base.value) ?? [] {
                parseNode(value, into: &nodes, locale: locale, fullKey: key.scalar!.string)
            }
        }
    }
    
    private func getSupportedRootNodesByFile() throws -> [URL: Yams.Node] {
        var dict = [URL: Yams.Node]()
        for url in yamlUrls { dict[url] = try getSupportedRootNode(url) }
        return dict
    }
    
    private func getSupportedRootNode(_ url: URL) throws -> Yams.Node? {
        let content = try String(contentsOf: url).trimmingCharacters(in: .whitespacesAndNewlines)
        let root = try Yams.compose(yaml: content)!
        if isSupportedLocaleYaml(root: root, url: url) {
            return root
        } else {
            skippedFiles.append(url)
            return nil
        }
    }
    
    private func isSupportedLocaleYaml(root: Yams.Node, url: URL) -> Bool {
        guard root.mapping?.count == 1 else { return false }
        guard let baseKey = root.mapping!.first!.key.scalar?.string else { return false }
        let fileBaseName = url.deletingPathExtension().lastPathComponent
        return baseKey == fileBaseName
    }
    
    private func sortedMapping(_ node: Yams.Node) -> [Yams.Node.Mapping.Element]? {
        return node.mapping?.sorted(by: { $0.key.scalar!.string < $1.key.scalar!.string })
    }
    
    private func parseNode(_ node: Yams.Node, into array: inout [Node], locale: String, fullKey: String) {
        var firstSighting = false
        let treeNode = seenOrNewTreeNode(fullKey, firstSighting: &firstSighting)
        var foundType = NodeType.unknown

        if let mapping = sortedMapping(node) {
            foundType = .container
            for el in mapping {
                let key = el.key.scalar!.string
                parseNode(el.value, into: &treeNode.children, locale: locale, fullKey: "\(fullKey).\(key)")
            }
        } else if let sequence = node.sequence {
            foundType = .sequence
            for (index, el) in sequence.enumerated() {
                let key = "[\(String(index))]"
                parseNode(el, into: &treeNode.children, locale: locale, fullKey: "\(fullKey).\(key)")
            }
        } else {
            foundType = .document
            if treeNode.translations == nil { treeNode.translations = [:] }
            treeNode.translations![locale] = node.scalar?.string ?? ""
        }
        
        if firstSighting {
            treeNode.type = foundType
            array.append(treeNode)
        } else if treeNode.type != foundType && !reconcile(treeNode) {
            array.removeAll(where: { $0 == treeNode })
            Warning.show("STRUCTURAL MISMATCH @ \(locale).\(fullKey)")
        }
    }
    
    private func seenOrNewTreeNode(_ fullKey: String, firstSighting: inout Bool) -> Node {
        var treeNode = seenFullKeys[fullKey]
        if treeNode == nil {
            treeNode = Node(fullKey: fullKey)
            seenFullKeys[fullKey] = treeNode!
            firstSighting = true
        } else {
            firstSighting = false
        }
        return treeNode!
    }
    
    private func reconcile(_ treeNode: Node) -> Bool {
        guard treeNode.type != .sequence,
              let translations = treeNode.translations else { return false }
        
        let keys = treeNode.children.map({ $0.ownKey })
        if keys.contains("one") && keys.contains("other") {
            // transplant translations into one/other if they are given
            // directly (non-nested) for some locales, but not all.
            for (locale, value) in translations {
                for child in treeNode.children {
                    child.translations![locale] = value
                }
            }
            treeNode.type = .container
            treeNode.translations = nil
            return true
        }

        return false
    }
    
    private func warnIfSkippedFiles() {
        if skippedFiles.isEmpty { return }

        Warning.show("""
        The following files are not valid locale files and will be ignored.
            
        Only files with one top-level key that matches the filename are supported.
            
        \(skippedFiles.map({ $0.lastPathComponent }).joined(separator: ", "))
        """, suppressIdentifier: skippedFiles.first!.deletingLastPathComponent().path)
    }
}
