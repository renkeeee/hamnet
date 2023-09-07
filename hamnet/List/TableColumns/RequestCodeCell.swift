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
import NIOHTTP1

class RequestCodeCell: NSTableCellView, RecordListCellProtocol {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    public func bindData(_ record: Record) {
        self.textField?.font = .systemFont(ofSize: 12)
        self.textField?.wantsLayer = true
        self.textField?.textColor = .white

        self.textField?.layer?.cornerRadius = 3
        
        let code = record.httpCode
        if let code = code {
            self.textField?.stringValue = " \(code) "
            if code >= 500 {
                self.textField?.layer?.backgroundColor = Color.systemRed.withAlphaComponent(0.7).cgColor
            } else if code >= 400 {
                self.textField?.layer?.backgroundColor = Color.systemYellow.withAlphaComponent(0.7).cgColor
            } else if code >= 300 {
                self.textField?.layer?.backgroundColor = Color.systemOrange.withAlphaComponent(0.7).cgColor
            } else if code >=  200 {
                self.textField?.layer?.backgroundColor = Color.systemGreen.withAlphaComponent(0.7).cgColor
            } else {
                self.textField?.layer?.backgroundColor = Color.systemGray.withAlphaComponent(0.7).cgColor
            }
        } else {
            self.textField?.stringValue = " -- "
            self.textField?.layer?.backgroundColor = Color.systemGray.withAlphaComponent(0.3).cgColor
        }
        
    }
    
}
