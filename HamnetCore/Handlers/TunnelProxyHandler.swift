//
//  TunnelProxyHandler.swift
//  hamnet
//
//  Created by deepread on 2020/11/14.
//

import Foundation
import NIOTLS
import NIO

class TunnelProxyHandler: ChannelInboundHandler,RemovableChannelHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer
    
    var proxyContext:HTTPProxyContext
    
    var isOut:Bool
    var connected:Bool
    
    var requestDatas = [ByteBuffer]()
    var scheduled:Scheduled<Void>?
    
    var connectStatus: ConnectStatus = .disconnect
    
    init(proxyContext:HTTPProxyContext, isOut: Bool,scheduled:Scheduled<Void>?){
        self.proxyContext = proxyContext
        self.connected = false
        self.isOut = isOut
        self.scheduled = scheduled
    }
    
    func handlerAdded(context: ChannelHandlerContext) {
        YLog.debug("TunnelProxyHandler Add")
    }
    
    func handlerRemoved(context: ChannelHandlerContext) {
        YLog.debug("TunnelProxyHandler Remove")
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        YLog.debug("TunnelProxyHandler Read")
        scheduled?.cancel()
        let buf = unwrapInboundIn(data)
        if isOut {
            _ = proxyContext.serverChannel?.writeAndFlush(wrapInboundOut(buf))
        }else{
            if self.connectStatus == .disconnect {
                connectToServer()
            }
            handleData(buf)
        }
        context.fireChannelRead(wrapInboundOut(buf))
        return
    }
    
    func channelReadComplete(context: ChannelHandlerContext) {
        self.proxyContext.updateStatus(.success)
    }
    
    func connectToServer() -> Void {
        self.connectStatus = .pending
        var channelInitializer: ((Channel) -> EventLoopFuture<Void>)?
        channelInitializer = { (outChannel) -> EventLoopFuture<Void> in
            self.proxyContext.updateClientChannel(outChannel)
            return outChannel.pipeline.addHandler(TunnelProxyHandler(proxyContext: self.proxyContext, isOut: true, scheduled: nil), name: "TunnelProxyHandler")
        }
        
        let clientBootstrap = ClientBootstrap(group: proxyContext.serverChannel!.eventLoop.next())
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer(channelInitializer!)
        let _ = clientBootstrap.connect(host: proxyContext.requestHost!, port: proxyContext.requestPort!).whenComplete { result in
            switch result {
            case .success( _):
                self.connectStatus = .connected
                self.handleData(nil)
                break
            case .failure(let error):
                YLog.error("\(self.proxyContext.requestHost!) connect error:\(error)")
                self.connectStatus = .disconnect
                self.proxyContext.serverChannel?.close(mode: .all, promise: nil)
                self.proxyContext.clientChannel?.close(mode: .all, promise: nil)
                self.proxyContext.updateStatus(.error)
                break
            }
        }
    }
    
    func handleData(_ data:ByteBuffer?) -> Void {
        if self.connectStatus == .connected {
            for rd in requestDatas {
                _ = proxyContext.clientChannel!.writeAndFlush(rd)
            }
            if data != nil {
                _ = proxyContext.clientChannel!.writeAndFlush(data)
            }
            requestDatas.removeAll()
        } else {
            guard let msg = data else {return}
            requestDatas.append(msg)
        }
    }
    
    func channelUnregistered(context: ChannelHandlerContext) {
        YLog.debug("TunnelProxy channelUnregistered close")
        context.close(mode: .all, promise: nil)
    }
    
}
