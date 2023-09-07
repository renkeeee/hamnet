//
//  HTTPParser.swift
//  hamnet
//
//  Created by deepread on 2020/11/8.
//

import Cocoa
import NIO
import NIOHTTP1
import NIOWebSocket

class HTTPParser: ParserProtocol {
    
    private let methods: Set<String> = [
        "GET",
        "POST",
        "PUT",
        "HEAD",
        "OPTIONS",
        "PATCH",
        "DELETE",
        "TRACE"
    ]
    
    func parseBytes(_ bufffer: ByteBuffer) -> ParserMatchStatus {
        if bufffer.readableBytes < 8 {
            return .pending
        }
        
        guard let front8 = bufffer.getString(at: 0, length: 8) else {
            return .mismatch
        }
        
        let method = front8.components(separatedBy: " ").first
        if method == nil {
            return .mismatch
        } else if methods.contains(method!) {
            return .match
        }
        return .mismatch
    }
    
    func handlePipeline(_ context: ChannelHandlerContext) -> EventLoopFuture<Void> {
        let pipleline = context.pipeline
        let promise = pipleline.eventLoop.makePromise(of: Void.self)
        let proxyContext = HTTPProxyContext()
        pipleline.addHandler(WatchHandler(proxyContext: proxyContext)).flatMap({
            pipleline.configureHTTPServerPipeline().flatMap {
                pipleline.addHandler(HTTPHandler(proxyContext: proxyContext), name: "HTTPHandler", position: .last)
            }
        }).whenComplete { promise.completeWith($0) }
        return promise.futureResult
    }
    
    
    
    
}
