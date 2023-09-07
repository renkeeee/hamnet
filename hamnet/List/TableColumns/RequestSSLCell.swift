//
//  RequestBaseCell.swift
//  hamnet
//
//  Created by deepread on 2020/11/28.
//

import Cocoa
import SwifterSwift
import SnapKit
import RxSwift

class RequestSSLCell: NSTableCellView, RecordListCellProtocol {
    
    @IBOutlet weak var iconView: NSImageView!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    public func bindData(_ record: Record) {
        let isSSL = record.isSSL
        let isMitm = record.isMitM
        
        if isSSL && isMitm {
            self.iconView.image = NSImage.init(named: NSImage.Name("lockopen"))
            self.iconView.contentTintColor = .systemGreen
        } else if isSSL && !isMitm {
            self.iconView.image = NSImage.init(named: NSImage.Name("lockclosed"))
            self.iconView.contentTintColor = .systemRed
        } else {
            self.iconView.image = nil
        }
    }
    
}
