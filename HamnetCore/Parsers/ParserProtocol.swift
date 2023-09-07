//
//  ParserProtocol.swift
//  hamnet
//
//  Created by deepread on 2020/11/8.
//

import Cocoa
import NIO

enum ParserMatchStatus {
    case match
    case mismatch
    case pending
}

enum ConnectStatus {
    case disconnect
    case pending
    case connected
}

protocol ParserProtocol {
    func parseBytes(_: ByteBuffer) -> ParserMatchStatus
    func handlePipeline(_: ChannelHandlerContext) -> EventLoopFuture<Void>
}
