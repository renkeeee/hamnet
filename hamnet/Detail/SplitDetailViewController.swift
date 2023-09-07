//
//  SplitDetailViewController.swift
//  hamnet
//
//  Created by deepread on 2020/11/29.
//

import Cocoa
import SnapKit

class SplitDetailViewController: NSViewController {
    
    var session: SessionInfo?
    
    let spiltView = NSSplitView()

    let requestVC = DetailContentViewController()
    let responseVC = DetailContentViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestVC.type = .request
        responseVC.type = .response
        self.addChild(requestVC)
        self.addChild(responseVC)
        self.view.addSubview(spiltView)
        self.spiltView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        self.spiltView.subviews = [requestVC.view, responseVC.view]
        self.spiltView.dividerStyle = .thin
    }
    
    override func viewDidAppear() {
        if spiltView.isVertical {
            self.spiltView.setPosition(self.view.frame.width / 2 , ofDividerAt: 0)
        } else {
            self.spiltView.setPosition(self.view.frame.height / 2 , ofDividerAt: 0)
        }
    }
    
}
