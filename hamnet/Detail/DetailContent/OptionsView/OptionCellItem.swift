//
//  OptionCellItem.swift
//  hamnet
//
//  Created by deepread on 2020/12/12.
//

import Cocoa
import RxSwift
import RxCocoa

class OptionCellItem: NSCollectionViewItem {
    @IBOutlet weak var iconView: NSImageView!
    @IBOutlet weak var titleView: NSTextField!
    
    static let identifer = NSUserInterfaceItemIdentifier.init("OptionCellItem")

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var isSelected: Bool {
        didSet {
//            self.view.layer?.backgroundColor = isSelected ? NSColor.systemGray.withAlphaComponent(0.1).cgColor : NSColor.clear.cgColor
            self.titleView.textColor = isSelected ? NSColor.textColor : NSColor.systemGray
        }
      }
    
    func updateCell(_ title: String?, _ icon: NSImage?) {
        if let title = title {
            self.titleView.stringValue = title
        }
        
        self.iconView.image = nil
        self.iconView.isHidden = true
        
//        if let icon = icon {
//            self.iconView.image = icon
//        }
    }
}
