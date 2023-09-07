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

class RequestCreateTimeCell: NSTableCellView, RecordListCellProtocol {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    public func bindData(_ record: Record) {
        let createTimeStr = record.startTime.timeString()
        self.textField?.stringValue = createTimeStr
        self.textField?.font = .systemFont(ofSize: 12)
    }
    
}
