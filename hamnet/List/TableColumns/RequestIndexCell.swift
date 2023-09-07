//
//  RequestIndexCell.swift
//  hamnet
//
//  Created by deepread on 2020/11/28.
//

import Cocoa
import SwifterSwift
import SnapKit
import RxSwift

class RequestIndexCell: NSTableCellView, RecordListCellProtocol {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    public func bindData(_ record: Record) {
        self.textField?.stringValue = "\(record.index)"
        self.textField?.font = .systemFont(ofSize: 12)
        self.textField?.textColor = .systemGray
    }
}
