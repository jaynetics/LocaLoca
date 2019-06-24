import Foundation

// Singleton

class Search {
    static var current: DispatchWorkItem?

    private typealias Result = [(Node, Double)]

    private var nodes: [Node]
    private var query: String
    private var result: Result = []

    class func launch(_ query: String, in nodes: [Node], callback: (([Node])->Void)?) {
        current?.cancel()
        current = DispatchWorkItem(block: {
            let search = Search(query, in: nodes)
            let result = search.execute().top(20)
            callback?(result)
        })
        DispatchQueue.main.async(execute: current!)
    }
    
    private init(_ query: String, in nodes: [Node]) {
        self.nodes = nodes
        self.query = query
    }
    
    private func execute() -> Search {
        result = []
        guard !query.isEmpty else { return self }
        nodes.forEach({ traverse($0) })
        return self
    }
    
    private func top(_ n: Int) -> [Node] {
        let sorted = result.sorted(by: { $0.1 > $1.1 })
        let nodes = sorted.map({ $0.0 })
        return Array(nodes.prefix(n))
    }
    
    private func traverse(_ node: Node) {
        if node.type == .document {
            let score = node.searchScore(query)
            if score > 0.1 {
                result.append((node, score))
            }
        } else {
            for child in node.children {
                traverse(child)
            }
        }
    }
}
