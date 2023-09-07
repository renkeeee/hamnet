//
//  MitmService.swift
//  hamnet
//
//  Created by deepread on 2020/11/8.
//

import Foundation
import Cocoa
import NIO
import NIOHTTP1
import RxSwift
import RxRelay

/*
 *
 * MITM Service: 负责开启关闭代理
 *
 */

struct MITMServiceConfig {
    let port: Int
    let host: String
}


class MITMService: NSObject {
    
    let config: MITMServiceConfig
    
    enum ServiceStatus {
        case undefined
        case running
        case closed
        case fail      
    }
    
    let disposeBag = DisposeBag()
    let status = BehaviorRelay<ServiceStatus>(value: .undefined)
    
    var channel: Channel?
    let bootStrap: ServerBootstrap?
    let master = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let worker = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount/2)
    
    
    
    public init(configuration: MITMServiceConfig) {
        
        let parsersHandler = StreamParseMaker.init(parsers: [HTTPParser(), CONNECTParser(), SSLParser()])
        
        self.config = configuration
        self.bootStrap = ServerBootstrap(group: master, childGroup: worker)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.addHandler(parsersHandler, name: "parsersHandler", position: .first)
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
            .childChannelOption(ChannelOptions.connectTimeout, value: TimeAmount.seconds(10))
    }
    
    public func start() {
        DispatchQueue.global().async {
            YLog.info("mitmservice start")
            if let _ = self.channel {
                YLog.info("mitmservice start failed: channel is not nil")
                return
            }
            self.channel = try? self.bootStrap!.bind(host: self.config.host, port: self.config.port).wait()
            guard let _ = self.channel else {
                YLog.error("mitmservice start failed: bootstrap bind to error")
                self.status.accept(.fail)
                return
            }
            self.status.accept(.running)
            YLog.info("mitmservice has listen on \(self.config.host):\(self.config.port)")
            try? self.channel?.closeFuture.wait()
            YLog.info("mitmservice closed")
            self.status.accept(.closed)
        }
    }
    
    public func stop() {
        YLog.info("mitmservice stop")
        guard let _ = self.channel else {
            YLog.info("mitmservice stop failed: channel is nil")
            return
        }
        self.channel?.close(mode: .input).whenComplete({ (result) in
            switch result {
            case .success:
                self.channel = nil
                break
            case .failure(_):
                YLog.error("mitmservice stop failed: channel close faild")
                break
            }
        })
    }
}
