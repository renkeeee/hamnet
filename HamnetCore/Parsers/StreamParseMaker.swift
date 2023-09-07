//
//  StreamParseMaker.swift
//  hamnet
//
//  Created by deepread on 2020/11/8.
//

import Cocoa
import NIO
import NIOHTTP1

/*
 *
 * StreamParseMaker: 负责管理网络数据解析器
 *
 */

class StreamParseMaker: ChannelInboundHandler, RemovableChannelHandler {
    public typealias InboundIn = ByteBuffer
    public typealias InbountOut = ByteBuffer
    
    private var buffer: ByteBuffer?
    private var parserIndex: Int = 0
    private let parserList: [ParserProtocol]
    
    init(parsers: [ParserProtocol]) {
        self.parserList = parsers
    }
    
    func handlerAdded(context: ChannelHandlerContext) {
    }
    
    func handlerRemoved(context: ChannelHandlerContext) {
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = unwrapInboundIn(data)
        for index in parserIndex..<parserList.count {
            let parser = parserList[index]
            let parseStatus = parser.parseBytes(buffer)
            if parseStatus == .match {
                parser.handlePipeline(context).whenComplete { res in
                    switch res {
                    case .success(_):
                        context.fireChannelRead(data)
                    case .failure(let error):
                        YLog.error("handlePipeline error: \(error)")
                    }
                    context.pipeline.removeHandler(self, promise: nil)
                }
                return
            } else if parseStatus == .pending {
                parserIndex = index
                return
            }
        }
        context.flush()
        context.close(promise: nil)
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        YLog.error("Catch error:\(error)")
        context.pipeline.close(promise: nil)
    }
    
    
}
