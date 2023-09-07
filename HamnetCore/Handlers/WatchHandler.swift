//
//  WatchHandler.swift
//  hamnet
//
//  Created by deepread on 2020/12/2.
//

import Foundation
import NIO


class WatchHandler: ChannelDuplexHandler, RemovableChannelHandler {
    
    typealias InboundIn = ByteBuffer
    typealias OutboundIn = ByteBuffer
    
    var proxyContext: HTTPProxyContext
    
    init(proxyContext: HTTPProxyContext) {
        self.proxyContext = proxyContext
    }
    
    func channelActive(context: ChannelHandlerContext) {
    }
    
    func channelInactive(context: ChannelHandlerContext) {
    }
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        context.writeAndFlush(data, promise: promise)
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        context.fireChannelRead(data)
    }
    
    func close(context: ChannelHandlerContext, mode: CloseMode, promise: EventLoopPromise<Void>?) {
        
    }
    
}
