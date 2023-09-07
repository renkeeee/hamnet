//
//  CONNECTHandler.swift
//  hamnet
//
//  Created by deepread on 2020/11/14.
//

import Cocoa
import NIOHTTP1
import NIO
import NIOWebSocket
import NIOSSL

class CONNECTHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutbountOut = HTTPServerResponsePart
    
    enum ResponseStatus {
        case ready
        case parsing(HTTPRequestHead, ByteBuffer?)
    }
    
    var proxyContext: HTTPProxyContext
    
    var responseStatus: ResponseStatus = .ready
    
    
    init(proxyContext: HTTPProxyContext) {
        self.proxyContext = proxyContext
    }
    
    func handlerAdded(context: ChannelHandlerContext) {

    }
    
    func handlerRemoved(context: ChannelHandlerContext) {

    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        prepareProxyContext(context: context, data: data)

        let res = self.unwrapInboundIn(data)
        switch res {
        case .head(let head):
            self.parsingHead(head)
            break
        case .body(let body):
            self.parsingBody(body)
            break
        case .end(let end):
            self.parsingEnd(end, context)
            break
        }
    }
}

extension CONNECTHandler {
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
    
    func parsingHead(_ head: HTTPRequestHead) {
        switch self.responseStatus {
        case .ready:
            self.responseStatus = .parsing(head, nil)
            break
        default:
            YLog.error("Unexpected HTTPServerRequestPart.head when body was being parsed.")
            self.close()
        }
    }
    
    func parsingBody(_ body: ByteBuffer) {
        var bodyBuffer = body
        switch self.responseStatus {
        case .parsing(let head, let parsingBuffer):
            if var buf = parsingBuffer {
                buf.writeBuffer(&bodyBuffer)
                bodyBuffer = buf
            }
            self.responseStatus = .parsing(head, bodyBuffer)
        default:
            YLog.error("Unexpected body buffer when head was being parsed.")
            self.close()
        }
    }
    
    func parsingEnd(_ end: HTTPHeaders?,  _ context: ChannelHandlerContext) {
        if end != nil {
            YLog.error("Unexpected tail headers")
            self.close()
            return
        }
        switch self.responseStatus {
        case .parsing(let head, _):
            self.configureSSLProxy(head, context)
        default:
            YLog.error("Unexpected data when end was being parsed.")
            self.close()
        }
    }
    
    func close() {
        proxyContext.serverChannel?.close(mode: .all, promise: nil)
        if let clientChannel = proxyContext.clientChannel, clientChannel.isActive {
            clientChannel.close(mode: .all, promise: nil)
        }
        self.proxyContext.updateStatus(.error)
    }
    
    func configureSSLProxy(_ head: HTTPRequestHead, _ context: ChannelHandlerContext) {
        let rspHead = HTTPResponseHead(version: head.version, status: .custom(code: 200, reasonPhrase: "Connection Established"), headers: ["content-length":"0"])
        
        let cancelTask = context.channel.eventLoop.scheduleTask(in:  TimeAmount.seconds(10)) {
            YLog.error( "[CONNECTHANDLER]error:can not get client hello from \(self.proxyContext.requestHost ?? "")")
            context.channel.close(mode: .all,promise: nil)
            self.proxyContext.updateStatus(.error)
        }
        
        let _ = context.channel.writeAndFlush(HTTPServerResponsePart.head(rspHead)).flatMap({
            context.channel.writeAndFlush(HTTPServerResponsePart.end(nil)).flatMap({
                context.pipeline.removeHandler(name: "HTTPResponseEncoder").flatMap({
                    context.pipeline.removeHandler(name: "ByteToMessageHandler").flatMap({
                        context.pipeline.removeHandler(name: "HTTPServerPipelineHandler").flatMap({
                            context.pipeline.removeHandler(self).flatMap({
                                context.pipeline.addHandler(SSLHandler(proxyContext: self.proxyContext, scheduled: cancelTask), name: "SSLHandler")
                            })
                        })
                    })
                })
            })
        })
    }
}
