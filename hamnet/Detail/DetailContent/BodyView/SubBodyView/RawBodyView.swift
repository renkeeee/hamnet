//
//  RawBodyView.swift
//  hamnet
//
//  Created by deepread on 2020/12/13.
//

import Cocoa

class RawBodyView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    private var overViewTextView: NSTextView?
    private var overViewScrollView: NSScrollView?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupOverViewTextView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupOverViewTextView() {
        overViewScrollView = NSTextView.scrollableTextView()
        overViewTextView = overViewScrollView!.documentView as? NSTextView
        overViewTextView?.isEditable = false
        self.addSubview(overViewScrollView!)
        
        self.overViewScrollView!.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
    
    public func updateAttributeValue(_ attriStr: NSAttributedString) {
        self.overViewTextView?.textStorage?.setAttributedString(attriStr)
    }
    
}
