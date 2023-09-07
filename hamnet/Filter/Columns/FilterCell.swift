//
//  FilterAppHeaderCell.swift
//  hamnet
//
//  Created by deepread on 2020/12/6.
//

import Cocoa
import RxSwift
import RxCocoa
import SwifterSwift

class FilterCell: NSTableCellView {
    
    var item: FilterItem?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func bindItem(_ item: FilterItem, isSelect: Bool) {
        self.item = item
        
        if let item = item as? AppFilterItem {
            if item.type == .head {
                let iconImage = NSImage.init(named: NSImage.Name("filter-app-icon"))!
                self.imageView?.image = iconImage
            } else {
                let iconImage = NSImage.init(named: NSImage.Name("filter-app-item-icon"))!
                self.imageView?.image = iconImage
            }
        }
        
        if let item = item as? DomainFilterItem {
            if item.type == .head {
                let iconImage = NSImage.init(named: NSImage.Name("filter-link-icon"))!
                self.imageView?.image = iconImage
            } else if item.type == .host {
                let iconImage = NSImage.init(named: NSImage.Name("filter-link-host-icon"))!
                self.imageView?.image = iconImage
            } else {
                let iconImage = NSImage.init(named: NSImage.Name("filter-link-path-icon"))!
                self.imageView?.image = iconImage
            }
            
        }
        
        
        self.textField?.stringValue = item.text
        self.wantsLayer = true
        self.layer?.cornerRadius = 8
        self.layer?.masksToBounds = true
        if isSelect {
            self.backgroundColor = Color.systemOrange.withAlphaComponent(0.8)
            self.textField?.textColor = .white
            self.imageView?.contentTintColor = .white
        } else {
            self.backgroundColor = .clear
            self.textField?.textColor = .textColor
            self.imageView?.contentTintColor = .systemGray
        }
    }
    
}
