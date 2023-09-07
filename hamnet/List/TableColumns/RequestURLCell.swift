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

class RequestURLCell: NSTableCellView, RecordListCellProtocol {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    public func bindData(_ record: Record) {
        let res = record.urlString
        var urlStrWithoutQuery = res
        var components = URLComponents(string: res)
        if let _ = components {
            components?.query = nil
            urlStrWithoutQuery = components?.url?.absoluteString ?? urlStrWithoutQuery
        } else {
//            YLog.error("Error With Parse URL Query:\(urlStr)")
        }
        self.textField?.stringValue = urlStrWithoutQuery
        self.textField?.font = .systemFont(ofSize: 12)
    }
    
}
