//
//  WSExchangeHandler.swift
//  hamnet
//
//  Created by deepread on 2020/11/22.
//

import Foundation
import NIOTLS
import NIOHTTP1
import NIO
import NIOWebSocket
import NIOSSL

class WSExchangeHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame
    
    var proxyContext: HTTPProxyContext
    
    init(proxyContext: HTTPProxyContext) {
        self.proxyContext = proxyContext
    }
    
    public func handlerAdded(context: ChannelHandlerContext) {
        self.proxyContext.webSocketClientConnectedPromise?.succeed(())
    }
    
    
    func handlerRemoved(context: ChannelHandlerContext) {
    }


    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame: WebSocketFrame = self.unwrapInboundIn(data)
        
        let wsItem = WebSocketItem(isOut: false, frame: frame, createTime: Date())
        self.proxyContext.record?.addSocketItem(wsItem)
        
        _ = proxyContext.serverChannel?.writeAndFlush(self.wrapOutboundOut(frame))
        context.fireChannelRead(data)
    }
    
    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    
    private func receivedClose(context: ChannelHandlerContext) {
        YLog.debug("WSExchangeHandler receivedClose close")
        self.proxyContext.clientChannel?.close(mode: .all, promise: nil)
        self.proxyContext.serverChannel?.close(mode: .all, promise: nil)
        self.proxyContext.updateStatus(.success)
    }


    private func closeOnError(context: ChannelHandlerContext) {
        YLog.debug("WSExchangeHandler closeOnError close")
        self.proxyContext.clientChannel?.close(mode: .all, promise: nil)
        self.proxyContext.serverChannel?.close(mode: .all, promise: nil)
        self.proxyContext.updateStatus(.error)
    }
}
