//
//  WSStatusCell.swift
//  hamnet
//
//  Created by deepread on 2020/12/20.
//

import Cocoa
import SnapKit

class WSStatusCell: NSTableCellView {
    
    lazy var statusImageView: NSImageView = {
        let imgView = NSImageView(frame: .zero)
        self.addSubview(imgView)
        imgView.snp.makeConstraints { make in
            make.center.equalTo(self)
            make.height.width.equalTo(18)
        }
        return imgView
    }()
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    func updateStatus(_ isOut: Bool) {
        self.textField?.stringValue = ""
        if isOut {
            self.statusImageView.image = NSImage(named: "arrow-up")
            self.statusImageView.contentTintColor = .systemGreen
        } else {
            self.statusImageView.image = NSImage(named: "arrow-down")
            self.statusImageView.contentTintColor = .systemOrange
        }
    }
    
}
