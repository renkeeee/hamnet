//
//  HMBottomVC.swift
//  hamnet
//
//  Created by hxj on 2021/1/1.
//

import Cocoa
import RxSwift
import RxCocoa

class HMBottomVC: NSViewController {

    @IBOutlet weak var systemProxyBtn: NSButton!
    @IBOutlet weak var listenProxyBtn: NSButton!
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        HMAction.shared.toggleEnableProxy.subscribe(onNext: { value in
            if value {
                self.systemProxyBtn.title = "System Proxy On"
                self.systemProxyBtn.state = .on
            } else {
                self.systemProxyBtn.title = "System Proxy Off"
                self.systemProxyBtn.state = .off
            }
        }).disposed(by: self.bag)
        
        self.systemProxyBtn.toolTip = "Auto enable system proxy"
        
        
        Observable.combineLatest(HMAction.shared.toggleStartRecord, HMAction.shared.toggleProxyPort).subscribe(onNext: { value, port in
            if value {
                self.listenProxyBtn.title = "[Recording] Listening Port: \(port)"
                self.listenProxyBtn.state = .on
            } else {
                self.listenProxyBtn.title = "[Not Recording] Listening Port: \(port)"
                self.listenProxyBtn.state = .off
            }
        }).disposed(by: self.bag)
        
        self.listenProxyBtn.toolTip = "Listening Port"
        
        
    }
    
}
