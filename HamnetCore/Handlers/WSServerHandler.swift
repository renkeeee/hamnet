//
//  WSServerHandler.swift
//  hamnet
//
//  Created by deepread on 2020/11/21.
//

import Foundation
import NIOTLS
import NIOHTTP1
import NIO
import NIOWebSocket
import NIOSSL

class WSServerHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame
    
    var proxyContext: HTTPProxyContext
    
    var connectClient: ConnectStatus = .disconnect
    
    var requestFrams: [WebSocketFrame] = []
    
    init(proxyContext: HTTPProxyContext) {
        self.proxyContext = proxyContext
    }
    
    func handlerRemoved(context: ChannelHandlerContext) {

    }

    
    public func handlerAdded(context: ChannelHandlerContext) {
        setupClient(context: context)
        self.proxyContext.webSocketClientConnectedPromise = context.eventLoop.makePromise(of: Void.self)
        self.proxyContext.webSocketClientConnectedPromise?.futureResult.hop(to: context.eventLoop).whenSuccess({ _ in
            self.connectClient = .connected
            self.handleFrame(nil, context: context)
        })
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = self.unwrapInboundIn(data)
        
        let newFrame = WebSocketFrame(fin: frame.fin, rsv1: frame.rsv1, rsv2: frame.rsv2, rsv3: frame.rsv3, opcode: frame.opcode, maskKey: nil, data: frame.unmaskedData, extensionData: frame.unmaskedExtensionData)
        
        handleFrame(newFrame, context: context)
        context.fireChannelRead(data)
    }
    
    
    
    func setupClient(context: ChannelHandlerContext) {
        if connectClient != .disconnect || self.connectClient == .pending {
            return
        }
        
        if self.proxyContext.record == nil {
            return
        }
        
        var reqKey: String? = nil
        var reqHead: HTTPRequestHead? = nil
        
        if let requestHead = self.proxyContext.record?.requestHead, let head = try? requestHead.value() {
            reqHead = head
            reqKey = head.headers["Sec-WebSocket-Key"].first
        }
        
        if reqKey == nil {
            return
        }
        
        self.connectClient = .pending
        
        let httpHandler = HTTPInitialRequestHandler(requestHead: reqHead!)
        
        var channelInitializer: ((Channel) -> EventLoopFuture<Void>)?
        
        let websocketUpgrader = NIOWebSocketClientUpgrader(requestKey: reqKey!,
                                                           upgradePipelineHandler: { (channel: Channel, _: HTTPResponseHead) in
                                                            channel.pipeline.addHandler(WSExchangeHandler(proxyContext: self.proxyContext))
        })
        
        let config: NIOHTTPClientUpgradeConfiguration = (
            upgraders: [ websocketUpgrader ],
            completionHandler: { context in
                YLog.info("WSExchangeHandler client success")
                _ = context.pipeline.removeHandler(httpHandler)
        })

        
        if self.proxyContext.record!.isSSL {
            // wss
            channelInitializer = { (outChannel) -> EventLoopFuture<Void> in
                let tlsClientConfiguration = TLSConfiguration.forClient(applicationProtocols: ["http/1.1"])
                let sslClientContext = try! NIOSSLContext(configuration: tlsClientConfiguration)
                let sniName = self.proxyContext.requestHost!.isIP() ? nil : self.proxyContext.requestHost
                let sslClientHandler = try! NIOSSLClientHandler(context: sslClientContext, serverHostname: sniName)
                
                return outChannel.pipeline.addHandler(sslClientHandler, name: "NIOSSLClientHandler").flatMap({
                    outChannel.pipeline.addHTTPClientHandlers(withClientUpgrade: config).flatMap({
                        outChannel.pipeline.addHandler(httpHandler)
                    })
                })
            }
        } else {
            // ws
            channelInitializer = { (outChannel) -> EventLoopFuture<Void> in
                return outChannel.pipeline.addHTTPClientHandlers(withClientUpgrade: config).flatMap({
                    outChannel.pipeline.addHandler(httpHandler)
                })
            }
        }
        
        let _ = ClientBootstrap(group: self.proxyContext.serverChannel!.eventLoop.next())
            .channelInitializer(channelInitializer!)
            .connect(host: self.proxyContext.requestHost!, port: self.proxyContext.requestPort!)
            .whenComplete { result in
                switch result {
                case .success(let clientChannel):
                    self.proxyContext.updateClientChannel(clientChannel)
                    break
                case .failure(let error):
                    YLog.error("outChannel connect failure:\(error)");
                    self.connectClient = .disconnect
                    self.proxyContext.serverChannel?.close(mode: .all, promise: nil)
                    self.proxyContext.clientChannel?.close(mode: .all, promise: nil)
                    break
                }
            }
        
    }
    
    func handleFrame(_ frame: WebSocketFrame?, context: ChannelHandlerContext) {
        
        if let _ = frame {
            let wsItem = WebSocketItem(isOut: true, frame: frame!, createTime: Date())
            self.proxyContext.record?.addSocketItem(wsItem)
        }
        
        if self.connectClient == .disconnect {
            self.closeOnError(context: context)
        } else if self.connectClient == .connected, let outChannel = self.proxyContext.clientChannel, outChannel.isActive {
            for fd in requestFrams {
                proxyContext.clientChannel?.writeAndFlush(self.wrapOutboundOut(fd), promise: nil)
            }
            requestFrams.removeAll()
            if frame != nil {
                proxyContext.clientChannel?.writeAndFlush(self.wrapOutboundOut(frame!), promise: nil)
            }
        } else {
            if frame != nil {
                self.requestFrams.append(frame!)
            }
            
        }
    }


    private func receivedClose(context: ChannelHandlerContext) {
        YLog.debug("WSServerHandler receivedClose close")
        self.proxyContext.clientChannel?.close(mode: .all, promise: nil)
        self.proxyContext.serverChannel?.close(mode: .all, promise: nil)
        self.proxyContext.updateStatus(.success)
    }


    private func closeOnError(context: ChannelHandlerContext) {
        YLog.debug("WSServerHandler closeOnError close")
        self.proxyContext.clientChannel?.close(mode: .all, promise: nil)
        self.proxyContext.serverChannel?.close(mode: .all, promise: nil)
        self.proxyContext.updateStatus(.error)
    }
}


extension WSServerHandler {
    private final class HTTPInitialRequestHandler: ChannelInboundHandler, RemovableChannelHandler {
        public typealias InboundIn = HTTPClientResponsePart
        public typealias OutboundOut = HTTPClientRequestPart
        
        let requestHead: HTTPRequestHead
        
        init(requestHead: HTTPRequestHead) {
            self.requestHead = requestHead
        }
        
        public func channelActive(context: ChannelHandlerContext) {
            
            let requestHead = self.requestHead
            
            context.write(self.wrapOutboundOut(.head(requestHead)), promise: nil)
            
            let body = HTTPClientRequestPart.body(.byteBuffer(ByteBuffer()))
            context.write(self.wrapOutboundOut(body), promise: nil)
            
            context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        }
        
        public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let clientResponse = self.unwrapInboundIn(data)
            
            switch clientResponse {
            case .head(let responseHead):
                YLog.debug(responseHead)
            case .body(let byteBuffer):
                YLog.debug(byteBuffer.readableBytes)
            case .end:
                YLog.debug("WSServerHandler end close")
                context.close(promise: nil)
            }
        }
        
        public func handlerRemoved(context: ChannelHandlerContext) {
           
        }
        
        public func errorCaught(context: ChannelHandlerContext, error: Error) {
            YLog.debug("WSServerHandler errorCaught close")
            context.close(promise: nil)
        }
    }
}
