//
//  RequestBaseCell.swift
//  hamnet
//
//  Created by deepread on 2020/11/28.
//

import Cocoa
import SnapKit
import RxSwift
import SwifterSwift

class RequestMethodCell: NSTableCellView, RecordListCellProtocol {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    public func bindData(_ record: Record) {
        let reqHead = record.requestHead
        var method = reqHead?.method.rawValue
        if record.webSocketItems.count > 0 {
            method = "WS"
        }
        
        if method == "WS" {
            self.textField?.attributedStringValue = .init(string: method!, swiftyAttributes: [.textColor(.systemOrange), .font(.boldSystemFont(ofSize: 11))])
        } else if method == "GET" {
            self.textField?.attributedStringValue = .init(string: method!, swiftyAttributes: [.textColor(.systemGreen), .font(.boldSystemFont(ofSize: 11))])
        } else if method == "POST" {
            self.textField?.attributedStringValue = .init(string: method!, swiftyAttributes: [.textColor(.systemBlue), .font(.boldSystemFont(ofSize: 11))])
        } else if method == "PUT" {
            self.textField?.attributedStringValue = .init(string: method!, swiftyAttributes: [.textColor(.systemTeal), .font(.boldSystemFont(ofSize: 11))])
        } else if method == "OPTION" {
            self.textField?.attributedStringValue = .init(string: method!, swiftyAttributes: [.textColor(.systemPink), .font(.boldSystemFont(ofSize: 11))])
        } else if method == "DELETE" {
            self.textField?.attributedStringValue = .init(string: method!, swiftyAttributes: [.textColor(.systemBrown), .font(.boldSystemFont(ofSize: 11))])
        } else if method == "CONNECT" {
            self.textField?.attributedStringValue = .init(string: method!, swiftyAttributes: [.textColor(.systemGray), .font(.boldSystemFont(ofSize: 11))])
        } else {
            self.textField?.attributedStringValue = .init(string: method!, swiftyAttributes: [.textColor(.systemPurple), .font(.boldSystemFont(ofSize: 11))])
        }
    }
    
}
