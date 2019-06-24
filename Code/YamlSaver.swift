import Foundation
import Yams

class YamlSaver: SaneNotifications {
    struct Notifications {
        static let saving     = "YamlSaverSaving"
        static let savingDone = "YamlSaverSavingDone"
    }

    // this traverses the tree once for each locale, which is sub-optimal,
    // but allows for adding locales on the fly without having to dup the tree.
    class func save(_ contents: [AnyObject], locales: Set<String>, to dir: URL) {
        post(Notifications.saving)

        for locale in locales {
            if let yamlString = stringFromTree(contents, locale: locale) {
                writeToDisk(yamlString, locale: locale, dir: dir)
            } else {
                Warning.show("Could not build yaml content for locale \(locale)")
            }
        }

        post(Notifications.savingDone)
    }
    
    class func stringFromTree(_ objects: [AnyObject], locale: String) -> String? {
        var localeContent: [String: Any] = [:]
        for node in objects {
            insert(node as! Node, into: &localeContent, locale: locale)
        }
        return stringFromDict([locale: localeContent])
    }

    private class func insert(_ node: Node, into dict: inout [String: Any], locale: String) {
        if node.isLeaf {
            dict[node.ownKey] = node.translations?[locale] ?? ""
        } else if node.isSequenceContainer {
            // turn into array
            dict[node.ownKey] = node.children.map({ $0.translations?[locale] ?? "" })
        } else {
            // branch node, dump recursively
            var subdict: [String: Any] = [:]
            for child in node.children {
                insert(child, into: &subdict, locale: locale)
            }
            dict[node.ownKey] = subdict
        }
    }
    
    private class func stringFromDict(_ dict: [String: Any]) -> String? {
        return try? Yams.dump(
            object:        dict,
            width:         -1,
            allowUnicode:  true,
            explicitStart: true,
            sortKeys:      true
        )
    }
    
    private class func writeToDisk(_ yamlString: String, locale: String, dir: URL) {
        let path = dir.appendingPathComponent("\(locale).yml", isDirectory: false)
        do {
            try yamlString.write(to: path, atomically: true, encoding: .utf8)
        } catch {
            Warning.show("Could not write to path \(path)")
        }
    }
}
