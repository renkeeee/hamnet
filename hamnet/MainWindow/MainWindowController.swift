//
//  MainWindowController.swift
//  hamnet
//
//  Created by deepread on 2020/12/6.
//

import Cocoa

class MainWindowController: NSWindowController {
    
    let recordContext = RecordContext()
    
    var buttons: [NSView] = []
    
    override func windowDidLoad() {
        super.windowDidLoad()
        recordContext.bindSession(SessionInfo.active)
    }
    
    override func windowWillLoad() {
        super.windowWillLoad()
    }

}
