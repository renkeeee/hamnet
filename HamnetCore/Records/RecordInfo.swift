//
//  RecordInfo.swift
//  hamnet
//
//  Created by deepread on 2020/11/24.
//

import Cocoa
import RxSwift
import NIO
import NIOHTTP1
import SwifterSwift
import NIOWebSocket

public struct WebSocketItem {
    let isOut: Bool
    let frame: WebSocketFrame
    let createTime: Date
}

class RecordInfo {
    
    private var _decompressRespData: Data? = nil
    
    public enum Status: Int {
        case initial = 0
        case pending = 1
        case success = 2
        case error  = -1
    }
    
    public init(session: SessionInfo) {
        self.session = session
    }
    
    func bindUpdate() {
        Observable.combineLatest(
            status,
            requestHead,
            requestBody,
            responseHead,
            responseBody
        )
        .skip(1)
        .subscribe(onNext: { [weak self] _ in
            if self!.isIgnore == false, let update = self?.session.updateRecord {
                update(self!)
            }
        }).disposed(by: disposeBag)
    }
    
    public unowned let session: SessionInfo
    
    let disposeBag = DisposeBag()
    
    public var index: Int = 0
    
    public let uuid = UUID()
    
    public var changeKey = UUID()
    
    public var process: ProcessInfo?
    
    private var readableRspBodySize: Int = 0
    

    public let status = BehaviorSubject<Status>(value: .initial)
    
    public var isSSL = false
    public var isMitm = false
    public var isWebSocket = false
    
    public var isIgnore = false
    
    let requestHead = BehaviorSubject<HTTPRequestHead?>(value: nil)
    let requestBody = BehaviorSubject<ByteBuffer?>(value: nil)
    let requestEnd = BehaviorSubject<HTTPHeaders?>(value: nil)
    
    var requestBodyData: Data? {
        get {
            if let buffer = try? requestBody.value() {
                return buffer.getData(at: 0, length: buffer.readableBytes)
            } else {
                return nil
            }
        }
    }
    
    let responseHead = BehaviorSubject<HTTPResponseHead?>(value: nil)
    let responseBody = BehaviorSubject<ByteBuffer?>(value: nil)
    let responseEnd = BehaviorSubject<HTTPHeaders?>(value: nil)
    
    var responseBodyData: Data? {
        get {
            if let buffer = try? responseBody.value() {
                return buffer.getData(at: 0, length: buffer.readableBytes)
            } else {
                return nil
            }
        }
    }
    
    var actualBodyData: Data? {
        get {
            guard let headers = (try? self.responseHead.value())?.headers else {
                return nil
            }
            guard let responseBody = try? self.responseBody.value() else {
                return nil
            }
            
            let nowSize = responseBody.readableBytes
            
            if self._decompressRespData != nil && nowSize == self.readableRspBodySize {
                return self._decompressRespData
            }
            
            self.readableRspBodySize = nowSize
            
            guard let data = responseBody.getData(at: 0, length: responseBody.readableBytes) else {
                return nil
            }
            
            for head in headers {
                if head.name.lowercased() == "content-encoding" {
                    let value = head.value
                    if value.lowercased().contains("gzip") {
                        self._decompressRespData = data.gunzip()
                        break
                    } else if value.lowercased().contains("deflate") {
                        self._decompressRespData = data.inflate()
                        break
                    } else if value.lowercased().contains("br") {
                        self._decompressRespData = (data as NSData).br_decompressed()
                        break
                    }
                }
            }
            if self._decompressRespData == nil {
                self._decompressRespData = data
            }
            return self._decompressRespData
        }
    }
    
    
    let updateWebSocketItem = BehaviorSubject<WebSocketItem?>(value: nil)
    
    var startTime = Date()
    var endTime = Date()
    
    
        
    private var webSocketItems: [WebSocketItem] = []
    
    
    
    public func addSocketItem(_ item: WebSocketItem) {
        self.webSocketItems.append(item)
        self.updateWebSocketItem.onNext(item)
    }
    
    public func readSocketItems() -> [WebSocketItem] {
        return self.webSocketItems
    }
    
    
    public var urlString: String {
        let reqHead = try? self.requestHead.value()
        var scheme = self.isSSL ? "https://" : "http://"
        if self.webSocketItems.count > 0 {
            scheme = self.isSSL ? "wss://" : "ws://"
        }
        
        let uri = reqHead?.uri ?? ""
        let host = reqHead?.headers["HOST"].first ?? ""
        
        var res = uri
        
        if res.hasPrefix(host) == false {
            res = host + uri
        }
        
        if res.hasPrefix(scheme) == false {
            res = scheme + res
        }
        return res
    }
    
}
