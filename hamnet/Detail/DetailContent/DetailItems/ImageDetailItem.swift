//
//  ImageDetailItem.swift
//  hamnet
//
//  Created by deepread on 2020/12/19.
//

import Cocoa

class ImageDetailItem: DetailItem {
    var image: NSImage?
    
    override class func makeItem(record: Record) -> DetailItem? {
        fatalError("Must use ReqeustImageDetailItem OR ResponseImageDetailItem")
    }
    
    override func title() -> String {
        return "Image"
    }
    
    override func icon() -> NSImage {
        return NSImage.init(named: NSImage.Name("overview-detail-icon"))!
    }
    
    override func type() -> DetailShowType {
        return .AttributeText
    }
}

class ReqeustImageDetailItem: ImageDetailItem {
    override class func makeItem(record: Record) -> DetailItem? {
        guard let headers = record.requestHead?.headers else {
            return nil
        }
        
        guard let reqeustBody = record.requestBody else {
            return nil
        }
        
        guard let bodyData = reqeustBody.getData(at: 0, length: reqeustBody.readableBytes) else {
            return nil
        }
        
        let item = ReqeustImageDetailItem()

        for head in headers {
            if head.name.lowercased() == "content-type" {
                let contentType = head.value.lowercased()
                if contentType.contains("image") {
                    let image = NSImage.init(data: bodyData)
                    if let _ = image {
                        item.image = image!
                        return item
                    }
                }
            }
        }
        return nil
    }
}

class ResponseImageDetailItem: ImageDetailItem {
    override class func makeItem(record: Record) -> DetailItem? {
        guard let headers = record.responseHead?.headers else {
            return nil
        }
        
        guard let uncompressData = record.actualRspBodyData else {
            return nil
        }
        
       
        let item = ResponseImageDetailItem()
        
        
        for head in headers {
            if head.name.lowercased() == "content-type" {
                let contentType = head.value.lowercased()
                if contentType.contains("image") {
                    let image = NSImage.init(data: uncompressData)
                    if let _ = image {
                        item.image = image!
                        return item
                    }
                }
            }
        }
        return nil
    }
}
