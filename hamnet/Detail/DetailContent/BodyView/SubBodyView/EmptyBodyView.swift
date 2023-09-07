//
//  EmptyBodyView.swift
//  hamnet
//
//  Created by deepread on 2020/12/13.
//

import Cocoa
import SnapKit

class EmptyBodyView: NSView {
    
    lazy var imageView: NSImageView = {
        let imgView = NSImageView(frame: .zero)
        imgView.image = NSImage(named: NSImage.Name("emptyview-detail"))
        imgView.contentTintColor = .systemGray
        return imgView
    }()

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        setupConstraint()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.addSubview(imageView)
        self.backgroundColor = NSColor.textBackgroundColor
    }
    
    func setupConstraint() {
        self.imageView.snp.makeConstraints { make in
            make.left.top.equalTo(self).offset(50)
            make.right.bottom.equalTo(self).offset(-50)
        }
    }
    
}
