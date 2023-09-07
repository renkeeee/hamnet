//
//  RequestStatusCell.swift
//  hamnet
//
//  Created by deepread on 2020/11/28.
//

import Cocoa
import SwifterSwift
import SnapKit
import RxSwift

class RequestStatusCell: NSTableCellView, RecordListCellProtocol {
    @IBOutlet weak var circleView: NSView!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    public func bindData(_ record: Record) {
        let status = record.status
        switch status {
        case .initial:
            self.circleView?.backgroundColor = .systemGray
        case .pending:
            self.circleView?.backgroundColor = .systemOrange
        case .success:
            self.circleView?.backgroundColor = .systemGreen
        case .error:
            self.circleView?.backgroundColor = .systemRed
        }
    }
    
}
