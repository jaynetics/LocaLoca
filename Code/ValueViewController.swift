import Cocoa

class ValueViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    
    var rowsPerNode: Int = 0
    var locales: [String] = [] {
        didSet {
            // for each node we want one group row and one row for every translation
            self.rowsPerNode = 1 + locales.count
            self.tableView.reloadData()
        }
    }
    var nodes: [Node] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.action = #selector(clicked)
    }
    
    @objc
    private func clicked() {
        let row = tableView.clickedRow
        guard row >= 0, !isGroupRow(row) else { return }
        if let cell = tableView.view(atColumn: tableView.clickedColumn, row: tableView.clickedRow, makeIfNecessary: false) as? ValueCell {
            cell.edit()
        }
    }
}

extension ValueViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return nodes.count * rowsPerNode
    }
}

let groupCellId = NSUserInterfaceItemIdentifier("GroupCellID")
let valueCellId = NSUserInterfaceItemIdentifier("ValueCellID")

extension ValueViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let node = nodeForRow(row)
        if isGroupRow(row) {
            let groupCell = tableView.makeView(withIdentifier: groupCellId, owner: nil)! as! NSTableCellView
            groupCell.textField?.stringValue = node.fullKey
            return groupCell
        } else {
            let valueCell = tableView.makeView(withIdentifier: valueCellId, owner: nil)! as! ValueCell
            return valueCell.with(node, locale: localeForRow(row))
        }
    }
    
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        return isGroupRow(row)
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return isGroupRow(row) ? 20 : tableView.rowHeight
    }
    
    func isGroupRow(_ row: Int) -> Bool {
        return row % rowsPerNode == 0
    }
    
    func localeForRow(_ row: Int) -> String {
        return locales[(row % rowsPerNode) - 1] // -1 accounts for group row
    }
    
    func nodeForRow(_ row: Int) -> Node {
        return nodes[row / rowsPerNode]
    }
}
