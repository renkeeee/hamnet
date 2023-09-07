//
//  KeyValueBodyViewController.swift
//  hamnet
//
//  Created by deepread on 2020/12/13.
//

import Cocoa

class KeyValueBodyViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var tableView: NSTableView!
    private var values: [(String, String)] = []
    
    lazy var tableViewMenu: NSMenu = {
        let menu = NSMenu()
        menu.addItem(withTitle: "Copy", action: #selector(tableViewMenuClickCopy), keyEquivalent: "c")
        menu.addItem(withTitle: "Copy Row", action: #selector(tableViewMenuClickCopyRow), keyEquivalent: "")
        menu.addItem(withTitle: "Copy All As JSON", action: #selector(tableViewMenuClickCopyAll), keyEquivalent: "")
        return menu
    }()
    
    func updateValues(_ values:  [(String, String)]) {
        self.values = values
        self.tableView.reloadData()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.menu = self.tableViewMenu
    }
    
    
    
    @objc func tableViewMenuClickCopy() {
        let row = self.tableView.clickedRow
        let column = self.tableView.clickedColumn
        if row < self.values.count && column < 2 {
            let item = self.values[row]
            let str = column == 0 ? item.0 : item.1
            let pasteBoard = NSPasteboard.general
            pasteBoard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            pasteBoard.setString(str, forType: .string)
        }
    }
    
    @objc func tableViewMenuClickCopyRow() {
        let row = self.tableView.clickedRow
        if row < self.values.count {
            let item = self.values[row]
            let str = "\(item.0): \(item.1)"
            let pasteBoard = NSPasteboard.general
            pasteBoard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            pasteBoard.setString(str, forType: .string)
        }
    }
    
    @objc func tableViewMenuClickCopyAll() {
        var dict :[String: String] = [:]
        for item in self.values {
            dict[item.0] = item.1
        }
        let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted])
        if let jsonData = jsonData {
            let str = String(data: jsonData, encoding: .utf8)
            if let str = str {
                let pasteBoard = NSPasteboard.general
                pasteBoard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                pasteBoard.setString(str, forType: .string)
            }
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.values.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if self.values.count <= row {
            return nil
        }
        
        let item = values[row]
        
        if tableColumn?.identifier.rawValue == "key" {
            if let cell = tableView.makeView(withIdentifier: .init("KeyCell"), owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = item.0
                return cell
            }
        } else if tableColumn?.identifier.rawValue == "value" {
            if let cell = tableView.makeView(withIdentifier: .init("ValueCell"), owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = item.1
                return cell
            }
        }
        return nil
    }
}
