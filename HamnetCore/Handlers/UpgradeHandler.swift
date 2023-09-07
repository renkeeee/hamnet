//
//  UpgradeHandler.swift
//  hamnet
//
//  Created by deepread on 2020/11/15.
//

import Cocoa
import NIOTLS
import NIO
import NIOSSL
import NIOHTTP1
import NIOWebSocket

class UpgradeHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer
    
    var proxyContext:HTTPProxyContext
    var scheduled:Scheduled<Void>?
    
    var bytesBuf: ByteBuffer?
    
    var complete: Bool = false
    
    init(proxyContext: HTTPProxyContext, scheduled: Scheduled<Void>) {
        self.proxyContext = proxyContext
        self.scheduled = scheduled
    }
    
    
    func handlerRemoved(context: ChannelHandlerContext) {
    }
    
    func handlerAdded(context: ChannelHandlerContext) {
        let upgrader = NIOWebSocketServerUpgrader(
                        shouldUpgrade: { (channel: Channel, head: HTTPRequestHead) in
                            self.proxyContext.readRequestHead(head)
                            return channel.eventLoop.makeSucceededFuture(HTTPHeaders())
                        },
                        upgradePipelineHandler: { (channel: Channel, head: HTTPRequestHead) in
                            return channel.pipeline.addHandler(WSServerHandler(proxyContext: self.proxyContext)).flatMap { _ in
                                    channel.pipeline.removeHandler(self)
                                }
                            }
                        )
        let config: NIOHTTPServerUpgradeConfiguration = (
                        upgraders: [ upgrader ],
                        completionHandler: { _ in
                        }
                    )
        
        context.pipeline.configureHTTPServerPipeline(position: .last, withServerUpgrade: config).whenComplete { [self] _ in
            self.complete = true
            
            if let buf = self.bytesBuf {
                let data = wrapInboundOut(buf)
                context.fireChannelRead(data)
                self.bytesBuf = nil
            }
        }
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        self.scheduled?.cancel()
        var buffer = unwrapInboundIn(data)
        if self.bytesBuf == nil {
            self.bytesBuf = buffer
        } else {
            self.bytesBuf?.writeBuffer(&buffer)
            self.bytesBuf = buffer
        }
        if complete {
            if let buf = self.bytesBuf {
                let data = wrapInboundOut(buf)
                context.fireChannelRead(data)
                self.bytesBuf = nil
            }
        }
    }
}
