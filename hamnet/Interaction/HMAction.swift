//
//  HMAction.swift
//  hamnet
//
//  Created by deepread on 2020/12/29.
//

import Foundation
import RxSwift
import SwiftyUserDefaults

extension DefaultsKeys {
    var enableProxy: DefaultsKey<Bool> { return .init("enableProxy", defaultValue: true) }
    var proxyPort: DefaultsKey<Int> { return .init("proxyPort", defaultValue: 8787) }
}

class HMAction {
    static let shared = HMAction()
    
    init() {
        bindData()
        bindNotification()
    }
    
    var disposeBag = DisposeBag()

    let toggleLeftPannel = BehaviorSubject<Bool>(value: true)

    let toggleEmptyRecords = PublishSubject<Void>()

    let toggleStartRecord = BehaviorSubject<Bool>(value: true)

    let toggleEnableProxy = BehaviorSubject<Bool>(value: Defaults[\.enableProxy])
    

    let toggleProxyPort = BehaviorSubject<Int>(value: Defaults[\.proxyPort])
    
    func bindData() {
        toggleEnableProxy.skip(1).subscribe(onNext: {[weak self] enable in
            Defaults[\.enableProxy] = enable
            self?.enableProxy(enable)
        }).disposed(by: self.disposeBag)
        
        toggleProxyPort.skip(1).subscribe(onNext: {[weak self] port in
            Defaults[\.proxyPort] = port
            if (Defaults[\.enableProxy]) {
                self?.enableProxy(true)
            }
        }).disposed(by: self.disposeBag)
    }
    
    
    func bindNotification() {
        NotificationCenter.default.rx.notification(NSApplication.didFinishLaunchingNotification).subscribe(onNext: {[weak self] _ in
            let enable = try? self?.toggleEnableProxy.value()
            if let enable = enable {
                if enable {
                    PrivilegedHelperManager.shared.useBeforeCheck { (res) in
                        if res {
                            PrivilegedHelperManager.shared.toggleProxy(enable: true, host: "127.0.0.1", port: Defaults[\.proxyPort], completion: { res in
                                YLog.debug("\(res)")
                            })
                        }
                    }
                }
            }
        }).disposed(by: self.disposeBag)
    }
    
    func enableProxy(_ enable: Bool) {
        PrivilegedHelperManager.shared.useBeforeCheck { (res) in
            if res {
                PrivilegedHelperManager.shared.toggleProxy(enable: enable, host: "127.0.0.1", port: Defaults[\.proxyPort], completion: { res in
                    YLog.debug("\(res)")
                })
            }
        }
    }
}
