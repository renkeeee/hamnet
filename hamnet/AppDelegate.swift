//
//  AppDelegate.swift
//  hamnet
//
//  Created by deepread on 2020/11/7.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let _ = YLog
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        YLog.debug("terminate")
    
    }
}

