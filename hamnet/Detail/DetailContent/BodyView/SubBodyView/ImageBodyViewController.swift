//
//  ImageBodyViewController.swift
//  hamnet
//
//  Created by deepread on 2020/12/19.
//

import Cocoa

class ImageBodyViewController: NSViewController {

    @IBOutlet weak var contentView: NSView!
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }
    
    func updateData(_ data: NSImage?) {
        self.contentView.layer?.contentsGravity = .resizeAspect
        self.contentView.layer?.contents = data
        self.contentView.wantsLayer = true
    }
    
}
