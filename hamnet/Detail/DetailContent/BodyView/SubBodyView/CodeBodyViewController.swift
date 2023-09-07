//
//  CodeBodyViewController.swift
//  hamnet
//
//  Created by deepread on 2020/12/15.
//

import Cocoa
import SnapKit

class CodeBodyViewController: NSViewController {

    var codeView: CodeMirrorWebView? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        self.codeView = CodeMirrorWebView(frame: self.view.bounds)
        self.view.addSubview(self.codeView!)
        self.codeView?.snp.makeConstraints({ make in
            make.edges.equalTo(self.view)
        })
    }
    
    func updateData(_ data: String, _ mimeType: String) {
        codeView?.setMimeType(mimeType)
        codeView?.setContent(data)
    }
    
}
