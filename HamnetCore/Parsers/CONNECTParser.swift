import Cocoa
import NIO
import NIOHTTP1

class CONNECTParser: ParserProtocol {
    
    private let methods: Set<String> = [
        "CONNECT"
    ]
    
    func parseBytes(_ bufffer: ByteBuffer) -> ParserMatchStatus {
        if bufffer.readableBytes < 8 {
            return .pending
        }
        
        guard let front8 = bufffer.getString(at: 0, length: 8) else {
            return .mismatch
        }
        
        let method = front8.components(separatedBy: " ").first
        if method == nil {
            return .mismatch
        } else if methods.contains(method!) {
            return .match
        }
        return .mismatch
    }
    
    func handlePipeline(_ context: ChannelHandlerContext) -> EventLoopFuture<Void> {
        let pipleline = context.pipeline
        let promise = pipleline.eventLoop.makePromise(of: Void.self)
        let proxyContext = HTTPProxyContext()
        pipleline.addHandler(WatchHandler(proxyContext: proxyContext)).flatMap({
            pipleline.addHandler(HTTPResponseEncoder(), name: "HTTPResponseEncoder", position: .last).flatMap({
                pipleline.addHandler(ByteToMessageHandler(HTTPRequestDecoder(leftOverBytesStrategy: .dropBytes)), name: "ByteToMessageHandler", position: .last).flatMap({
                    pipleline.addHandler(HTTPServerPipelineHandler(), name: "HTTPServerPipelineHandler", position: .last).flatMap({
                        pipleline.addHandler(CONNECTHandler(proxyContext: proxyContext), name: "CONNECTHandler", position: .last)
                    })
                })
            })
        }).whenComplete { promise.completeWith($0) }
        return promise.futureResult
    }
}
