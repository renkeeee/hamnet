//
//  DetailItem.swift
//  hamnet
//
//  Created by deepread on 2020/12/12.
//

import Cocoa
import NIO
import NIOHTTP1
import SwifterSwift

enum DetailShowType {
    case PlainText
    case AttributeText
    case KeyValueTable
    case HexTable
}

class DetailItem: NSObject {
    class func makeItem(record: Record) -> DetailItem? {
        fatalError("must use subclass")
    }
    
    func title() -> String {
        fatalError("must use subclass")
    }
    
    func icon() -> NSImage {
        fatalError("must use subclass")
    }
    
    func type() -> DetailShowType {
        fatalError("must use subclass")
    }
}

class RawDetailItem: DetailItem {
    var attributeString: NSAttributedString?
    
    override class func makeItem(record: Record) -> DetailItem? {
        fatalError("Must use ReqeustRawDetailItem OR ResponseRawDetailItem")
    }
    
    override func title() -> String {
        return "Overview"
    }
    
    override func icon() -> NSImage {
        return NSImage.init(named: NSImage.Name("overview-detail-icon"))!
    }
    
    override func type() -> DetailShowType {
        return .AttributeText
    }
}

class ReqeustRawDetailItem: RawDetailItem {
    override class func makeItem(record: Record) -> DetailItem? {
        if let _ = record.requestHead {
            let item = RawDetailItem()
            item.attributeString = parseRequestOverviewText(record)
            return item
        } else {
            return nil
        }
    }
}

class ResponseRawDetailItem: RawDetailItem {
    override class func makeItem(record: Record) -> DetailItem? {
        if let _ = record.responseHead {
            let item = RawDetailItem()
            item.attributeString = parseResonseOverviewText(record)
            return item
        } else {
            return nil
        }
    }
}

class HeaderDetailItem: DetailItem {
    var headers: [(String, String)]?
    
    override class func makeItem(record: Record) -> DetailItem? {
        fatalError("Must use ReqeustHeaderDetailItem OR ResponseHeaderDetailItem")
    }
    
    override func title() -> String {
        return "Header"
    }
    
    override func icon() -> NSImage {
        return NSImage.init(named: NSImage.Name("overview-detail-icon"))!
    }
    
    override func type() -> DetailShowType {
        return .KeyValueTable
    }
}


class ReqeustHeaderDetailItem: HeaderDetailItem {
    override class func makeItem(record: Record) -> DetailItem? {
        if let headers: HTTPHeaders = record.requestHead?.headers {
            let item = HeaderDetailItem()
            var results: [(String, String)] = []
            for header in headers {
                results.append((header.name, header.value))
            }
            item.headers = results
            return item
        } else {
            return nil
        }
    }
}

class ResponseHeaderDetailItem: HeaderDetailItem {
    override class func makeItem(record: Record) -> DetailItem? {
        if let headers: HTTPHeaders = record.responseHead?.headers {
            let item = HeaderDetailItem()
            var results: [(String, String)] = []
            for header in headers {
                results.append((header.name, header.value))
            }
            item.headers = results
            return item
        } else {
            return nil
        }
    }
}


class RequestQueryDetailItem: DetailItem {
    var queries: [(String, String)]?
    
    override class func makeItem(record: Record) -> DetailItem? {
        if let urlStr = record.requestHead?.uri {
            let item = RequestQueryDetailItem()
            if let params = URL(string: "http://hamnet.app\(urlStr)")?.queryParameters {
                var results: [(String, String)] = []
                for value in params {
                    results.append((value.key, value.value))
                }
                item.queries = results
                return item
            }
        }
        return nil
    }
    
    override func title() -> String {
        return "Query"
    }
    
    override func icon() -> NSImage {
        return NSImage.init(named: NSImage.Name("overview-detail-icon"))!
    }
    
    override func type() -> DetailShowType {
        return .KeyValueTable
    }
}


class RequestCookiesDetailItem: DetailItem {
    var cookies: [(String, String)]?
    
    override class func makeItem(record: Record) -> DetailItem? {
        guard let headers = record.requestHead?.headers else {
            return nil
        }
        
        var cookieStr = ""
        
        for head in headers {
            if head.name.lowercased() == "cookie" {
                cookieStr = head.value
                break
            }
        }
        
        let cookieArray = cookieStr.components(separatedBy: ";")
        var results: [(String, String)] = []
        for var cookie in cookieArray {
            let newCookie: String = cookie.trim()
            let cookiesArray = newCookie.components(separatedBy: "=")
            if cookiesArray.count == 2 {
                let keyStr = cookiesArray[0]
                let valueStr = cookiesArray[1]
                results.append((keyStr, valueStr))
            }
        }
        
        if results.count > 0 {
            let item = RequestCookiesDetailItem()
            item.cookies = results
            return item
        }
        return nil
    }
    
    override func title() -> String {
        return "Cookies"
    }
    
    override func icon() -> NSImage {
        return NSImage.init(named: NSImage.Name("overview-detail-icon"))!
    }
    
    override func type() -> DetailShowType {
        return .KeyValueTable
    }
}


class RequestFormDetailItem: DetailItem {
    var forms: [(String, String)]?
    
    override class func makeItem(record: Record) -> DetailItem? {
        guard let headers = record.requestHead?.headers else {
            return nil
        }
        
        guard let reqeustBody = record.requestBody else {
            return nil
        }
        
        var bodyString: String? = nil

        for head in headers {
            if head.name.lowercased() == "content-type" {
                if head.value.lowercased() == "application/x-www-form-urlencoded" {
                    bodyString = reqeustBody.getString(at: 0, length: reqeustBody.readableBytes, encoding: .utf8)
                    break
                }
            }
        }
        
        guard let bodyStr = bodyString, bodyStr.count > 0 else {
            return nil
        }
        
        let formArray = bodyStr.components(separatedBy: "&")
        var results: [(String, String)] = []
        for var form in formArray {
            let newForm: String = form.trim()
            var forms = newForm.components(separatedBy: "=")
            if forms.count == 2 {
                let keyStr = forms[0].urlDecode()
                let valueStr = forms[1].urlDecode()
                results.append((keyStr, valueStr))
            }
        }
        
        if results.count > 0 {
            let item = RequestFormDetailItem()
            item.forms = results
            return item
        }
        return nil
    }
    
    override func title() -> String {
        return "Forms"
    }
    
    override func icon() -> NSImage {
        return NSImage.init(named: NSImage.Name("overview-detail-icon"))!
    }
    
    override func type() -> DetailShowType {
        return .KeyValueTable
    }
}


class HexDataDetailItem: DetailItem {
    var data: Data?
    var id: String?
    
    override class func makeItem(record: Record) -> DetailItem? {
        fatalError("Must use ReqeustHeaderDetailItem OR ResponseHeaderDetailItem")
    }
    
    override func title() -> String {
        return "Hex"
    }
    
    override func icon() -> NSImage {
        return NSImage.init(named: NSImage.Name("overview-detail-icon"))!
    }
    
    override func type() -> DetailShowType {
        return .HexTable
    }
}

class RequestHexDataDetailItem: HexDataDetailItem {
    override class func makeItem(record: Record) -> DetailItem? {
        guard let _ = record.requestHead?.headers else {
            return nil
        }
        
        guard let reqeustBody = record.requestBody else {
            return nil
        }
        let data = reqeustBody.getData(at: 0, length: reqeustBody.readableBytes)
        if let data = data {
            let item = RequestHexDataDetailItem()
            item.data = data
            item.id = record.id
            return item
        }
        return nil
    }
}

class ResponseHexDataDetailItem: HexDataDetailItem {
    override class func makeItem(record: Record) -> DetailItem? {
        
        guard let _ = record.responseHead?.headers else {
            return nil
        }
        
        guard let uncompressData = record.actualRspBodyData else {
            return nil
        }
        
        let item = ResponseHexDataDetailItem()
        item.data = uncompressData
        item.id = record.id
        return item
    }
}

class CodeDataDetailItem: DetailItem {
    var data: String?
    var mimeType: String?
    
    override class func makeItem(record: Record) -> DetailItem? {
        fatalError("Must use ReqeustCodeDataDetailItem OR ResponseCodeDataDetailItem")
    }
    
    override func title() -> String {
        return "Body"
    }
    
    override func icon() -> NSImage {
        return NSImage.init(named: NSImage.Name("overview-detail-icon"))!
    }
    
    override func type() -> DetailShowType {
        return .AttributeText
    }
}


class RequestCodeDataDetailItem: CodeDataDetailItem {
    override class func makeItem(record: Record) -> DetailItem? {
        guard let headers = record.requestHead?.headers else {
            return nil
        }
        
        guard let reqeustBody = record.requestBody else {
            return nil
        }
        
        guard let bodyStr = reqeustBody.getString(at: 0, length: reqeustBody.readableBytes, encoding: .utf8) else {
            return nil
        }
        
        let item = RequestCodeDataDetailItem()
        item.data = bodyStr
        
        
        for head in headers {
            if head.name.lowercased() == "content-type" {
                var contentType = head.value.lowercased()
                if contentType.contains(";") {
                    let arr = contentType.components(separatedBy: ";")
                    contentType = arr.first ?? contentType
                }
                
                item.mimeType = contentType
                if contentType.contains("json") || contentType.contains("text") {
                    item.mimeType = "application/json"
                    return item
                }
                
                
                if contentType.contains("javascript") ||
                    contentType.contains("ecmascript") {
                    item.mimeType = "javascript"
                    return item
                }
                
                if contentType.contains("xml") {
                    item.mimeType = "xml"
                    return item
                }
                
                if contentType.contains("html") {
                    item.mimeType = "htmlmixed"
                    return item
                }
                
                return item
            }
        }
        return nil
    }
}

class ResponseCodeDataDetailItem: CodeDataDetailItem {
    override class func makeItem(record: Record) -> DetailItem? {
        guard let headers = record.responseHead?.headers else {
            return nil
        }
        
        guard let uncompressData = record.actualRspBodyData else {
            return nil
        }
        
        guard let bodyStr = String(data: uncompressData, encoding: .utf8) else {
            return nil
        }
        
        let item = RequestCodeDataDetailItem()
        item.data = bodyStr
        
        
        for head in headers {
            if head.name.lowercased() == "content-type" {
                var contentType = head.value.lowercased()
                if contentType.contains(";") {
                    let arr = contentType.components(separatedBy: ";")
                    contentType = arr.first ?? contentType
                }
                
                item.mimeType = contentType
                if contentType.contains("json") {
                    item.mimeType = "application/json"
                    return item
                }
                
                
                if contentType.contains("javascript") ||
                    contentType.contains("ecmascript") {
                    item.mimeType = "javascript"
                    return item
                }
                
                if contentType.contains("xml") {
                    item.mimeType = "xml"
                    return item
                }
                
                if contentType.contains("html") {
                    item.mimeType = "htmlmixed"
                    return item
                }
                
                return item
            }
        }
        return nil
    }
}
