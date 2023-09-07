//
//  HTTPProxyContext.swift
//  hamnet
//
//  Created by deepread on 2020/11/8.
//

import Cocoa
import NIO
import NIOHTTP1
import SwifterSwift

class HTTPProxyContext {

    var serverChannel: Channel?
    

    var clientChannel: Channel?
    
    var webSocketClientConnectedPromise: EventLoopPromise<Void>?
    
    var requestHost: String?
    var requestPort: Int?
    
    var record: RecordInfo?
    
    private func parseRequestHead(_ head: HTTPRequestHead) -> Void {
        if self.record == nil {
            self.record = SessionInfo.active.makeRecord(head)
        }
        
        if let port = self.serverChannel?.remoteAddress?.port {
            self.record?.process = ProcessInfo.process(byPort: port)
        }
        
        if head.uri.hasPrefix("https://") || head.uri.hasPrefix("wss://") {
            self.record?.isSSL = true
        }
        
        let headerHost = head.headers["Host"].first
        let hostArray: [String] = headerHost?.split(separator: ":").compactMap { ("\($0)") } ?? []
        if hostArray.count > 1 {
            let p = hostArray[1]
            if p.isNumeric {
                self.requestPort = Int(p)
            }
            self.requestHost = hostArray[0]
        }
        if self.requestHost == nil || self.requestHost?.count == 0 {
            if head.uri.contains("://"), let url = URL(string: head.uri) {
                self.requestHost = url.host
            } else {
                let arrayStrings: [String] = head.uri.split(separator: ":").compactMap { "\($0)" }
                if arrayStrings.count == 2 || arrayStrings.count == 3 {
                    self.requestHost = arrayStrings[arrayStrings.count - 2]
                } else if arrayStrings.count == 1 {
                    self.requestHost = arrayStrings[0]
                } else {
                    self.requestHost = nil
                }
            }
        }
        if self.requestPort == nil || self.requestPort! <= 0 {
            if head.uri.contains("://"),let url = URL(string: head.uri) {
                self.requestPort = url.port
            }else{
                let arrayStrings: [String] = head.uri.split(separator: ":").compactMap { "\($0)" }
                if arrayStrings.count >= 2 {
                    self.requestPort = Int(arrayStrings.last!)
                }
            }
        }
        if self.requestPort == nil || self.requestPort! <= 0 {
            self.requestPort = (self.record?.isSSL ?? false) ? 443 : 80
        }
    }
    
    public func needMITM() -> Bool {
        if let record = self.record {
            return self.record!.session.innerNeedMitM(record)
        }
        return false
    }
    
    public func updateServerChannel(_ serverChannel: Channel) {
        self.serverChannel = serverChannel
        
    }
    
    public func updateClientChannel(_ clientChannel: Channel) {
        self.clientChannel = clientChannel
    }
    
    public func updateStatus(_ status: RecordInfo.Status) {
        if let status = try? self.record?.status.value() {
            if status == .error || status == .success {
                return
            }
        }
        self.record?.status.onNext(status)
    }
    
    
    // request
    public func readRequestHead(_ head: HTTPRequestHead) -> Void {
        self.parseRequestHead(head)
        self.record?.requestHead.onNext(head)
        self.updateStatus(.pending)
    }
    
    public func readRequestBody(_ body: ByteBuffer) -> Void {
        self.record?.requestBody.onNext(body)
    }
    
    public func readRequestEnd(_ end: HTTPHeaders?) -> Void {
        self.record?.requestEnd.onNext(end)
    }
    
    public func sendRequestHead(_ head: HTTPRequestHead) -> EventLoopFuture<Void> {
        return self.clientChannel!.writeAndFlush(HTTPClientRequestPart.head(head))
    }
    
    public func sendRequestBody(_ body: ByteBuffer) -> EventLoopFuture<Void> {
        return self.clientChannel!.writeAndFlush(HTTPClientRequestPart.body(.byteBuffer(body)))
    }
    
    public func sendRequestEnd(_ end: HTTPHeaders?) -> EventLoopFuture<Void> {
        return self.clientChannel!.writeAndFlush(HTTPClientRequestPart.end(end))
    }
    
    
    
    
    // response
    public func readResponseHead(_ head: HTTPResponseHead) -> Void {
        self.record?.responseHead.onNext(head)
        if let lengthStr = head.headers["Content-Length"].first {
            if let nums = lengthStr.int, nums > 0 {
                return
            }
        }
        self.updateStatus(.success)
    }
    
    public func readResponseBody(_ body: ByteBuffer) -> Void {
        if let data = try? self.record?.responseBody.value() {
            var allBuffer = data
            var nowBuffer = body
            allBuffer.writeBuffer(&nowBuffer)
            self.record?.responseBody.onNext(allBuffer)
        } else {
            self.record?.responseBody.onNext(body)
        }
    }
    
    public func readResponseEnd(_ end: HTTPHeaders?) -> Void {
        self.record?.responseEnd.onNext(end)
        self.updateStatus(.success)
    }
    
    public func sendResponseHead(_ head: HTTPResponseHead) -> EventLoopFuture<Void> {
        return self.serverChannel!.writeAndFlush(HTTPServerResponsePart.head(head))
    }
    
    public func sendResponseBody(_ body: ByteBuffer) -> EventLoopFuture<Void> {
        return  self.serverChannel!.writeAndFlush(HTTPServerResponsePart.body(.byteBuffer(body)))
    }
    
    public func sendResponseEnd(_ end: HTTPHeaders?) -> EventLoopFuture<Void> {
        return  self.serverChannel!.writeAndFlush(HTTPServerResponsePart.end(end))
    }
    
}
