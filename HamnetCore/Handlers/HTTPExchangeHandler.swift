//
//  ExchangeHandler.swift
//  hamnet
//
//  Created by deepread on 2020/11/8.
//

import Cocoa
import NIO
import NIOHTTP1
import NIOFoundationCompat

class HTTPExchangeHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTPClientResponsePart
    typealias OutboundOut = HTTPServerResponsePart
    
    
    var proxyContext:HTTPProxyContext
    
    
    init(_ proxyContext:HTTPProxyContext) {
        self.proxyContext = proxyContext
    }
    
    func handlerAdded(context: ChannelHandlerContext) {
    }
    
    func handlerRemoved(context: ChannelHandlerContext) {
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let res = self.unwrapInboundIn(data)
        switch res {
        case .head(let head):
            self.proxyContext.readResponseHead(head)
            _ = self.proxyContext.sendResponseHead(head)
        case .body(let body):
            self.proxyContext.readResponseBody(body)
            _ = self.proxyContext.sendResponseBody(body)
        case .end(let end):
            self.proxyContext.readResponseEnd(end)
            let endFuture = self.proxyContext.sendResponseEnd(end)
            endFuture.whenComplete({ (_) in
                //YLog.debug("HTTPExchangeHanlder Close Server")
                if self.proxyContext.serverChannel!.isActive {
                    self.proxyContext.serverChannel!.close(mode: .all, promise: nil)
                }
            })
            let outPromise = context.eventLoop.makePromise(of: Void.self)
            context.channel.close(mode: .all, promise: outPromise)
            outPromise.futureResult.whenComplete { (_) in
                //YLog.debug("HTTPExchangeHanlder Close Out")
            }
            return
        }
        context.fireChannelRead(data)
        
    }
    
    func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
        self.proxyContext.updateStatus(.success)
    }
    
    func channelUnregistered(context: ChannelHandlerContext) {
        YLog.debug("HTTPExchangeHanlder channelUnregistered close")
        context.close(mode: .all, promise: nil)
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {

        context.channel.close(mode: .all,promise: nil)

        if proxyContext.serverChannel!.isActive {
           self.proxyContext.serverChannel!.close(mode: .all, promise: nil)
        }
        
        YLog.info("HTTPExchangeHandler errorCaught: \(error)")
    }
    
    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {

    }
}
