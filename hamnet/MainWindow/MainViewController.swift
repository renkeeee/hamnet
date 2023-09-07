//
//  MainViewController.swift
//  hamnet
//
//  Created by deepread on 2020/12/29.
//

import Cocoa
import RxCocoa
import RxSwift

class MainViewController: NSViewController {
    
    var disposeBag = DisposeBag()

    @IBOutlet weak var splitView: NSSplitView!
    override func viewDidLoad() {
        super.viewDidLoad()
        bindData()
    }
    
    func animatePanelChange(
        toPosition position: CGFloat,
        ofDividerAt dividerIndex: Int
    ) {
        NSAnimationContext.runAnimationGroup { context in
            context.allowsImplicitAnimation = true
            context.duration = 0.3

            splitView.setPosition(position, ofDividerAt: dividerIndex)
            splitView.layoutSubtreeIfNeeded()
        }
    }
    
    func bindData() {
        HMAction.shared.toggleLeftPannel.skip(1).subscribe(onNext: {[weak self] needShow in
            let newPosition: CGFloat = needShow ? 200.0 : 0
            self?.animatePanelChange(toPosition: newPosition, ofDividerAt: 0)
        }).disposed(by: self.disposeBag)
    }
    
}
