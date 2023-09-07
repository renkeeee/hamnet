//
//  HTTPHandler.swift
//  hamnet
//
//  Created by deepread on 2020/11/8.
//

import Cocoa
import NIO
import NIOTLS
import NIOSSL
import NIOHTTP1
import NIOWebSocket
import NIOConcurrencyHelpers

public extension String {
    func isIP() -> Bool {
        // We need some scratch space to let inet_pton write into.
        var ipv4Addr = in_addr()
        var ipv6Addr = in6_addr()

        return self.withCString { ptr in
            return inet_pton(AF_INET, ptr, &ipv4Addr) == 1 ||
                   inet_pton(AF_INET6, ptr, &ipv6Addr) == 1
        }
    }
}


class HTTPHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTPServerRequestPart
    
    var proxyContext: HTTPProxyContext
    
    var connectClient: ConnectStatus = .disconnect
    
    var requestDatas = [Any?]()
    
    init(proxyContext: HTTPProxyContext) {
        self.proxyContext = proxyContext
    }
    
    func handlerAdded(context: ChannelHandlerContext) {
    }
    
    func handlerRemoved(context: ChannelHandlerContext) {
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        prepareProxyContext(context: context, data: data)
        setupClientChannel()
        let res = self.unwrapInboundIn(data)
        switch res {
        case .head(let head):
            self.handleData(head)
            break
        case .body(let body):
            self.proxyContext.readRequestBody(body)
            self.handleData(body)
            break
        case .end(let end):
            self.proxyContext.readRequestEnd(end)
            self.handleData(end)
            break
        }
        context.fireChannelRead(data)
    }
}

extension HTTPHandler {
    func prepareProxyContext(context: ChannelHandlerContext, data: NIOAny) -> Void {
        if self.proxyContext.serverChannel == nil {
            self.proxyContext.updateServerChannel(context.channel)
        }
        let res = self.unwrapInboundIn(data)
        switch res {
        case .head(let head):
            self.proxyContext.readRequestHead(head)
        default:
            break
        }
    }
    
    func setupClientChannel() -> Void {
        guard let _ = self.proxyContext.record else {
            return
        }
        
        guard self.connectClient == .disconnect else {
            return
        }
        
        self.connectClient = .pending
        
        var channelInitializer: ((Channel) -> EventLoopFuture<Void>)?
        
        // http/https
        if self.proxyContext.record!.isSSL {
            channelInitializer = { (outChannel) -> EventLoopFuture<Void> in
                let tlsClientConfiguration = TLSConfiguration.forClient(
                    certificateVerification: .none, applicationProtocols: ["http/1.1"]
                )
                
                let sslClientContext = try! NIOSSLContext(configuration: tlsClientConfiguration)
                let sniName = self.proxyContext.requestHost!.isIP() ? nil : self.proxyContext.requestHost
                let sslClientHandler = try! NIOSSLClientHandler(context: sslClientContext, serverHostname: sniName)
                
                return outChannel.pipeline.addHandler(sslClientHandler, name: "NIOSSLClientHandler").flatMap({
                    outChannel.pipeline.addHandler(HTTPRequestEncoder(), name: "HTTPRequestEncoder").flatMap({
                        outChannel.pipeline.addHandler(ByteToMessageHandler(HTTPResponseDecoder()), name: "ByteToMessageHandler").flatMap({
                            outChannel.pipeline.addHandler(HTTPExchangeHandler( self.proxyContext), name: "HTTPExchangeHandler")
                        })
                    })
                })
            }
        } else {
            channelInitializer = { (channel) -> EventLoopFuture<Void> in
                return channel.pipeline.addHTTPClientHandlers().flatMap({
                    channel.pipeline.addHandler(HTTPExchangeHandler(self.proxyContext), name: "HTTPExchangeHandler")
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
                    self.connectClient = .connected
                    self.prepareSend()
                    break
                case .failure(let error):
                    YLog.error("outChannel connect failure:\(error)");
                    self.connectClient = .disconnect
                    self.proxyContext.updateStatus(.error)
                    self.proxyContext.serverChannel?.close(mode: .all, promise: nil)
                    self.proxyContext.clientChannel?.close(mode: .all, promise: nil)
                    break
                }
            }
        
    }
    
    func handleData(_ data: Any?) -> Void {
        requestDatas.append(data)
        prepareSend()
    }
    
    func prepareSend() {
        if self.connectClient == .connected, let outChannel = self.proxyContext.clientChannel, outChannel.isActive {
            for rd in requestDatas {
                sendData(data: rd)
            }
            requestDatas.removeAll()
        }
    }
    
    func sendData(data: Any?){
        if let head = data as? HTTPRequestHead{
            var uri = head.uri
            if let host = head.headers["HOST"].first, host.count > 0, uri.contains(host) {
                let uris = uri.components(separatedBy: host)
                uri = uris.last ?? uri
            }
            
            let clientHead = HTTPRequestHead(version: head.version, method: head.method, uri: uri, headers: head.headers)
            _ = proxyContext.sendRequestHead(clientHead)
        } else if let body = data as? ByteBuffer{
            _ = proxyContext.sendRequestBody(body)
        } else if let end = data as? HTTPHeaders? {
            _ = proxyContext.sendRequestEnd(end)
        }
    }
    
    func close() {
        YLog.debug("HTTPHanlder Close")
        proxyContext.serverChannel?.close(mode: .all, promise: nil)
        if let clientChannel = proxyContext.clientChannel, clientChannel.isActive {
            clientChannel.close(mode: .all, promise: nil)
        }
    }
    
}
