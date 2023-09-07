//
//  HMTopViewController.swift
//  hamnet
//
//  Created by deepread on 2020/12/29.
//

import Cocoa
import SwifterSwift
import RxCocoa
import RxSwift

class HMTopViewController: NSViewController {
    @IBOutlet weak var toggleLeftBtn: NSButton!
    @IBOutlet weak var toggleClearBtn: NSButton!
    @IBOutlet weak var toggleStopBtn: NSButton!
    @IBOutlet weak var toggleProxyBrtn: NSButton!
    
    var disposeBag = DisposeBag()
    
    func myTrakingArea(control: NSControl) -> NSTrackingArea {
        return NSTrackingArea.init(rect: control.bounds,
        options: [.mouseEnteredAndExited, .activeAlways],
        owner: control,
        userInfo: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let toggleLeftTrackingAera = myTrakingArea(control: self.toggleLeftBtn)
        self.toggleLeftBtn.addTrackingArea(toggleLeftTrackingAera)
        self.toggleLeftBtn.backgroundColor = Color.systemGray.withAlphaComponent(0.08)
        self.toggleLeftBtn.rx.tap.subscribe(onNext: {
            HMAction.shared.toggleLeftPannel.onNext(!(try! HMAction.shared.toggleLeftPannel.value()))
        }).disposed(by: self.disposeBag)
        self.toggleLeftBtn.toolTip = "Show or hide left filter tree view"
        
        let toggleClearTrackingAera = myTrakingArea(control: self.toggleClearBtn)
        self.toggleClearBtn.addTrackingArea(toggleClearTrackingAera)
        self.toggleClearBtn.backgroundColor = Color.systemGray.withAlphaComponent(0.08)
        self.toggleClearBtn.rx.tap.subscribe(onNext: {
            HMAction.shared.toggleEmptyRecords.onNext(())
        }).disposed(by: self.disposeBag)
        self.toggleClearBtn.toolTip = "Clear all records"
        
        let toggleStartTrackingAera = myTrakingArea(control: self.toggleStopBtn)
        self.toggleStopBtn.addTrackingArea(toggleStartTrackingAera)
        self.toggleStopBtn.backgroundColor = Color.systemGray.withAlphaComponent(0.08)
        self.toggleStopBtn.rx.tap.subscribe(onNext: {
            HMAction.shared.toggleStartRecord.onNext(!(try! HMAction.shared.toggleStartRecord.value()))
        }).disposed(by: self.disposeBag)
        self.toggleStopBtn.toolTip = "Enable or disable recording"
        
        HMAction.shared.toggleStartRecord.subscribe(onNext: {[weak self] start in
            if start {
                self?.toggleStopBtn.image = NSImage.init(named: NSImage.Name("top-stop-toggle"))!
                self?.toggleStopBtn.contentTintColor = .systemRed
            } else {
                self?.toggleStopBtn.image = NSImage.init(named: NSImage.Name("top-start-toggle"))!
                self?.toggleStopBtn.contentTintColor = .systemGray
            }
        }).disposed(by: self.disposeBag)
        
        
        let toggleProxyAera = myTrakingArea(control: self.toggleProxyBrtn)
        self.toggleProxyBrtn.addTrackingArea(toggleProxyAera)
        self.toggleProxyBrtn.backgroundColor = Color.systemGray.withAlphaComponent(0.08)
        self.toggleProxyBrtn.rx.tap.subscribe(onNext: {
            HMAction.shared.toggleEnableProxy.onNext(!(try! HMAction.shared.toggleEnableProxy.value()))
        }).disposed(by: self.disposeBag)
        self.toggleProxyBrtn.toolTip = "Enable or disable system proxy overriding"
        
        HMAction.shared.toggleEnableProxy.subscribe(onNext: {[weak self] enable in
            if enable {
                self?.toggleProxyBrtn.contentTintColor = .systemGreen
            } else {
                self?.toggleProxyBrtn.contentTintColor = .systemGray
            }
        }).disposed(by: self.disposeBag)
        
        
    }
    
    override func mouseEntered(with event: NSEvent) {
        if let owner = event.trackingArea?.owner as? NSControl {
            owner.backgroundColor = Color.systemGray.withAlphaComponent(0.2)
        }
    }

    override func mouseExited(with event: NSEvent) {
        if let owner = event.trackingArea?.owner as? NSControl {
            owner.backgroundColor = Color.systemGray.withAlphaComponent(0.08)
        }
    }
    
}
