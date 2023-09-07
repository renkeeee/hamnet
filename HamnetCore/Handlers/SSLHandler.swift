//
//  SSLHandler.swift
//  hamnet
//
//  Created by deepread on 2020/11/15.
//

import Cocoa
import NIOTLS
import NIO
import NIOSSL
import NIOHTTP1

class SSLHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer
    
    var proxyContext:HTTPProxyContext
    var scheduled:Scheduled<Void>?
    
    init(proxyContext: HTTPProxyContext, scheduled: Scheduled<Void>) {
        self.proxyContext = proxyContext
        self.scheduled = scheduled
    }
    
    func handlerAdded(context: ChannelHandlerContext) {

    }
    
    func handlerRemoved(context: ChannelHandlerContext) {

    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        scheduled?.cancel()
        // ssl hand shake
        let buf = unwrapInboundIn(data)
        
        if isSSLHandShake(buf) {
            if proxyContext.needMITM() {
                proxyContext.record?.isMitm = true
                handleSSL(context: context, buf: buf)
            } else {
                proxyContext.record?.isMitm = false
                handleBypass(context: context, buf: buf)
            }
        } else if isUpgrade(buf) {
            handleUpgrade(context: context, buf: buf)
        }
        else {
            handleHTTP(context: context, buf: buf)
        }
    }
    
    func prepareProxyContext(context: ChannelHandlerContext, data: NIOAny) -> Void {
        if self.proxyContext.serverChannel == nil {
            self.proxyContext.updateServerChannel(context.channel)
        }
    }
    
    func isUpgrade(_ buf: ByteBuffer) -> Bool {
        let bufferStr = buf.getString(at: 0, length: buf.readableBytes) ?? ""
        if bufferStr.contains("Connection: Upgrade") {
            return true
        }
        return false
    }
    
    func isSSLHandShake(_ buf: ByteBuffer) -> Bool {
        if (buf.readableBytes < 3) {
            return false
        }
        let first = buf.getBytes(at: buf.readerIndex, length: 1)
        let second = buf.getBytes(at: buf.readerIndex + 1, length: 1)
        let third = buf.getBytes(at: buf.readerIndex + 2, length: 1)
        let firstData = NSString(format: "%d", first?.first ?? 0).integerValue
        let secondData = NSString(format: "%d", second?.first ?? 0).integerValue
        let thirdData = NSString(format: "%d", third?.first ?? 0).integerValue
        if (firstData >= 20 && firstData <= 23 && secondData <= 3 && thirdData <= 3) {
            return true
        }
        return false
    }
    
    func handleSSL(context: ChannelHandlerContext, buf: ByteBuffer) {
        proxyContext.record?.isSSL = true
        let host = proxyContext.requestHost
        var cert: NIOSSLCertificate?
        if let isIP = host?.isIP(), isIP == true {
//            let ipStr = proxyContext.requestHost!
//            let ipAddress = IPv4Address(ipStr)
//            if let isPri = ipAddress?.isPrivate, isPri {
//                cert = CertService.shared.fetchSSLCertificateLocalHost()!
//            } else {
//                cert = CertService.shared.fetchIPCertificate(proxyContext.requestHost!)!
//            }
            cert = CertService.shared.fetchIPCertificate(proxyContext.requestHost!)!
        } else {
            cert = CertService.shared.fetchSSLCertificate(proxyContext.requestHost!)!
        }
        
        let tlsServerConfig = TLSConfiguration.forServer(certificateChain: [.certificate(cert!)], privateKey: .privateKey(CertService.shared.rsaKey))
        let sslServerContext = try! NIOSSLContext(configuration: tlsServerConfig)
        let sslServerHandler = NIOSSLServerHandler(context: sslServerContext)
        
        let cancelTask = context.channel.eventLoop.scheduleTask(in:  TimeAmount.seconds(10)) {
            YLog.error( "[HandleSSL]error:can not get client hello from \(self.proxyContext.requestHost ?? "")")
            context.channel.close(mode: .all,promise: nil)
        }

        context.pipeline.addHandler(sslServerHandler, name: "NIOSSLServerHandler").flatMap({
            context.pipeline.addHandler(SSLHandler(proxyContext: self.proxyContext, scheduled: cancelTask), name: "SSLHandler")
        }).whenComplete { _ in
            context.fireChannelRead(self.wrapInboundOut(buf))
            _ = context.pipeline.removeHandler(self)
        }
        return
    }
    
    func handleUpgrade(context: ChannelHandlerContext, buf: ByteBuffer) {
        let cancelTask = context.channel.eventLoop.scheduleTask(in:  TimeAmount.seconds(10)) {
            YLog.error( "[HandleUpgrade]error:can not get client hello from \(self.proxyContext.requestHost ?? "")")
            context.channel.close(mode: .all,promise: nil)
        }
        context.pipeline.addHandler(UpgradeHandler(proxyContext: self.proxyContext, scheduled: cancelTask), name: "UpgradeHandler").whenComplete { _ in
            context.fireChannelRead(self.wrapInboundOut(buf))
            _ = context.pipeline.removeHandler(self)
        }
        return
    }
    
    func handleHTTP(context: ChannelHandlerContext, buf: ByteBuffer) {
        let cancelTask = context.channel.eventLoop.scheduleTask(in:  TimeAmount.seconds(10)) {
            YLog.error( "[HandleHTTP]error:can not get client hello from \(self.proxyContext.requestHost ?? "")")
            context.channel.close(mode: .all,promise: nil)
        }
        
        context.pipeline.addHandler(ByteToMessageHandler(HTTPRequestDecoder(leftOverBytesStrategy: .dropBytes)), name: "ByteToMessageHandler").flatMap({
            context.pipeline.addHandler(HTTPResponseEncoder(), name: "HTTPResponseEncoder").flatMap({
                context.pipeline.addHandler(HTTPServerPipelineHandler(), name: "HTTPServerPipelineHandler").flatMap({
                    context.pipeline.addHandler(HTTPHandler(proxyContext: self.proxyContext), name: "HTTPHandler")
                })
            })
        }).whenComplete { _ in
            cancelTask.cancel()
            context.fireChannelRead(self.wrapInboundOut(buf))
            _ = context.pipeline.removeHandler(self)
        }
    }
    
    func handleBypass(context: ChannelHandlerContext, buf: ByteBuffer) {
        let cancelTask = context.channel.eventLoop.scheduleTask(in:  TimeAmount.seconds(10)) {
            YLog.error( "[HandleBypass]error:can not get client hello from \(self.proxyContext.requestHost ?? "")")
            context.channel.close(mode: .all,promise: nil)
        }
        context.pipeline.addHandler(TunnelProxyHandler(proxyContext: proxyContext, isOut: false,scheduled:cancelTask), name: "TunnelProxyHandler").whenComplete { _ in
            cancelTask.cancel()
            context.fireChannelRead(self.wrapInboundOut(buf))
            _ = context.pipeline.removeHandler(self)
        }
    }
}
