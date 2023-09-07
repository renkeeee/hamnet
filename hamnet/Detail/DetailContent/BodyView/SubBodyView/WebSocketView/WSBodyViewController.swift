//
//  WSBodyViewController.swift
//  hamnet
//
//  Created by deepread on 2020/12/19.
//

import Cocoa
import SwifterSwift

class WSBodyViewController: NSViewController, HFTextViewDelegate {

    @IBOutlet weak var splitView: NSSplitView!
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var rightContentView: NSView!
    
    
    @IBOutlet var textView: NSTextView!
    
    var items: [WebSocketItem] = []
    
    var hexView: HFTextView? = nil
    
    func updateData(_ items: [WebSocketItem]) {
        self.items = items
        self.updateSelect(nil)
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.hexView = HFTextView(frame: self.view.bounds)
        self.hexView!.delegate = self
        self.rightContentView.addSubview(hexView!)
        self.hexView!.snp.makeConstraints { make in
            make.edges.equalTo(self.rightContentView)
        }
    }
    
    func updateSelect(_ item: WebSocketItem?) {
        let width = self.splitView.frame.width
        if let item = item, (item.frame.opcode == .text || item.frame.opcode == .binary) {
            self.splitView.setPosition(width/2, ofDividerAt: 0)
            if item.frame.opcode == .text {
                let text = item.frame.data.getString(at: 0, length: item.frame.data.readableBytes)
                self.updateSelectText(text)
            } else if item.frame.opcode == .binary {
                let data = item.frame.data.getData(at: 0, length: item.frame.data.readableBytes)
                self.updateSelectData(data)
            }
        } else {
            self.splitView.setPosition(width, ofDividerAt: 0)
        }
    }
    
    func updateSelectText(_ text: String?) {
        let attributeStr = NSAttributedString.init(string: text ?? "", swiftyAttributes: [.textColor(Color.systemGray)])
        self.textView.textStorage?.setAttributedString(attributeStr)
        self.textView.isHidden = false
        self.hexView?.isHidden = true
    }
    
    func updateSelectData(_ data: Data?) {
        self.hexView?.data = data
        self.textView.isHidden = true
        self.hexView?.isHidden = false
    }
    
    func hexTextView(_ view: HFTextView, didChangeProperties properties: HFControllerPropertyBits) {
        // do nothing
    }
    
}


extension WSBodyViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        let records = self.items
        let selectRows = tableView.selectedRow
        if selectRows >= 0 && selectRows < records.count {
            let record = records[selectRows]
            self.updateSelect(record)
        } else {
            self.updateSelect(nil)
        }
    }
}


// --
// MARK: TableView Datasource
// --
extension WSBodyViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item: WebSocketItem = self.items[row]
        if let cell = tableView.makeView(withIdentifier: tableColumn?.identifier ?? NSUserInterfaceItemIdentifier(rawValue: ""), owner: nil) as? NSTableCellView {
            
            if tableColumn?.identifier.rawValue == "WSStatusCell" {
                let statusCell = cell as! WSStatusCell
                statusCell.updateStatus(item.isOut)
            } else if tableColumn?.identifier.rawValue == "WSTypeCell" {
                if item.frame.opcode == .binary {
                    cell.textField?.stringValue = "Binary"
                } else if item.frame.opcode == .connectionClose {
                    cell.textField?.stringValue = "Close"
                } else if item.frame.opcode == .continuation {
                    cell.textField?.stringValue = "Continue"
                } else if item.frame.opcode == .ping {
                    cell.textField?.stringValue = "Ping"
                } else if item.frame.opcode == .pong {
                    cell.textField?.stringValue = "Pong"
                } else if item.frame.opcode == .text {
                    cell.textField?.stringValue = "Text"
                }
            }  else if tableColumn?.identifier.rawValue == "WSTimeCell" {
                let date = item.createTime.timeString()
                cell.textField?.stringValue = date
            }
            return cell
        } else {
            return nil
        }
    }
}
