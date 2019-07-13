import Foundation

extension Node {
    convenience init(fullKey: String, type: NodeType = .document, children: [Node] = [], translations: [String: String]? = nil, array: Bool = false) {
        self.init(fullKey: fullKey)
        self.type = type
        self.children = children
        self.translations = translations
    }
    
    override var description: String {
        return "@\(fullKey){\(translations ?? [:])}\(children.map { $0.description })"
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let node = object as! Node? else { return false }
        return (
            node.fullKey == fullKey &&
            node.children == children &&
            node.translations == translations
        )
    }
}
