//
//  Record.swift
//  hamnet
//
//  Created by deepread on 2020/12/6.
//

import Foundation
import DifferenceKit
import NIOHTTP1
import NIO
import NIOWebSocket
import DataCompression
import SwifterSwift

class Record: NSObject, Differentiable {
    
    @objc var indexSort: Int {
        get {
            self.index
        }
    }
    
    @objc var methodSort: String? {
        get {
            let reqHead = self.requestHead
            var method = reqHead?.method.rawValue
            if self.webSocketItems.count > 0 {
                method = "WS"
            }
            return method
        }
    }
    
    @objc var urlSort: String? {
        get {
            let res = self.urlString
            var urlStrWithoutQuery = res
            var components = URLComponents(string: res)
            if let _ = components {
                components?.query = nil
                urlStrWithoutQuery = components?.url?.absoluteString ?? urlStrWithoutQuery
            }
            return urlStrWithoutQuery
        }
    }
    
    
    let id: String
    let index: Int
    let status: Status
    let processInfo: ProcessInfo?
    let isSSL: Bool
    let isMitM: Bool
    let isWebSocket: Bool
    
    let startTime: Date
    let endTime: Date
    
    let requestHead: HTTPRequestHead?
    let requestBody: ByteBuffer?
    
    let responseHead: HTTPResponseHead?
    let responseBody: ByteBuffer?
    
    let webSocketItems: [WebSocketItem]
    
    var actualRspBodyData: Data? = nil
    
    let httpCode: UInt?
    
    public enum Status: Int {
        case initial = 0
        case pending = 1
        case success = 2
        case error = 3 
    }
    
    init(_ recordInfo: RecordInfo) {
        id = recordInfo.uuid.uuidString
        index = recordInfo.index
        status = Status.init(rawValue: try! recordInfo.status.value().rawValue) ?? .initial
        processInfo = recordInfo.process
        isSSL = recordInfo.isSSL
        isMitM = recordInfo.isMitm
        isWebSocket = recordInfo.isWebSocket
        
        requestHead = try? recordInfo.requestHead.value() ?? nil
        requestBody = try? recordInfo.requestBody.value() ?? nil
        
        let rspHead = try? recordInfo.responseHead.value() ?? nil
        
        responseHead = rspHead
        responseBody = try? recordInfo.responseBody.value() ?? nil
        
        
        
        httpCode = rspHead?.status.code
        
        actualRspBodyData = recordInfo.actualBodyData
        
        webSocketItems = recordInfo.readSocketItems()
        
        
        startTime = recordInfo.startTime
        endTime = recordInfo.endTime
        
    }
    
    var differenceIdentifier: String {
        return id
    }
    
    func isContentEqual(to source: Record) -> Bool {
        return id ==  source.id &&
            status.rawValue == source.status.rawValue &&
            processInfo?.bundleID == source.processInfo?.bundleID &&
            isSSL == source.isSSL &&
            isMitM == source.isMitM &&
            httpCode == source.httpCode &&
            isWebSocket == source.isWebSocket &&
            requestHead == source.requestHead &&
            requestBody == source.requestBody &&
            responseHead == source.responseHead &&
            responseBody == source.responseBody &&
            webSocketItems.count == source.webSocketItems.count &&
            startTime == source.startTime &&
            endTime == source.endTime
    }
    
    public var urlString: String {
        let reqHead = self.requestHead
        var scheme = self.isSSL ? "https://" : "http://"
        if self.webSocketItems.count > 0 {
            scheme = self.isSSL ? "wss://" : "ws://"
        }
        
        let uri = reqHead?.uri ?? ""
        let host = reqHead?.headers["HOST"].first ?? ""
        
        var res: String = uri
        
        if res.contains(host) == false {
            res = host + uri
        }
        
        if res.hasPrefix(scheme) == false {
            res = scheme + res
        }
        
        return res
    }
    
    public var urlHost: String? {
        let urlString = self.urlString
        guard let url = URL(string: urlString) else {
            return nil
        }
        return url.host
    }
    
    public var urlPath: String? {
        let urlString = self.urlString
        guard let url = URL(string: urlString) else {
            return nil
        }
        return url.path.count == 0 ? nil : url.path
    }
    
    public var urlScheme: String? {
        let urlString = self.urlString
        guard let url = URL(string: urlString) else {
            return nil
        }
        return url.scheme
    }
}
