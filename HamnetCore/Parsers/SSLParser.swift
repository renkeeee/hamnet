//
//  CONNECTParser.swift
//  hamnet
//
//  Created by deepread on 2020/11/14.
//

import Cocoa
import NIO
import NIOHTTP1
import NIOSSL
import NIOTLS

class SSLParser: ParserProtocol {

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

    func parseBytes(_ bufffer: ByteBuffer) -> ParserMatchStatus {
        if bufffer.readableBytes < 3 {
            return .pending
        }

        if isSSLHandShake(bufffer) {
            return .match
        } else {
            return .mismatch
        }
    }

    func handlePipeline(_ context: ChannelHandlerContext) -> EventLoopFuture<Void> {
        let pipleline = context.pipeline
        let localAddress = context.channel.localAddress?.ipAddress ?? "127.0.0.1"
        let promise = pipleline.eventLoop.makePromise(of: Void.self)
        let cert = CertService.shared.fetchIPCertificate(localAddress)!
        let tlsServerConfig = TLSConfiguration.forServer(certificateChain: [.certificate(cert)], privateKey: .privateKey(CertService.shared.rsaKey))
        let sslServerContext = try! NIOSSLContext(configuration: tlsServerConfig)
        let sslServerHandler = NIOSSLServerHandler(context: sslServerContext)

        pipleline.addHandler(sslServerHandler, name: "NIOSSLServerChannelHandler").flatMap({
            pipleline.addHandler(StreamParseMaker(parsers: [HTTPParser(), CONNECTParser()]), name: "StreamParseMaker")
        }).whenComplete {promise.completeWith($0)}
        return promise.futureResult
    }
}
