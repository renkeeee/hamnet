//
//  WebSocketDetailItem.swift
//  hamnet
//
//  Created by deepread on 2020/12/20.
//

import Cocoa

class WebSocketDetailItem: DetailItem {
    
    var webSocketItems: [WebSocketItem] = []
    
    override class func makeItem(record: Record) -> DetailItem? {
        let wsItems = record.webSocketItems
        if wsItems.count > 0 {
            let item = WebSocketDetailItem()
            item.webSocketItems = wsItems
            return item
        }
        return nil
    }
    
    override func title() -> String {
        return "WebSocket"
    }
    
    override func icon() -> NSImage {
        return NSImage.init(named: NSImage.Name("overview-detail-icon"))!
    }
    
    override func type() -> DetailShowType {
        return .AttributeText
    }
}
