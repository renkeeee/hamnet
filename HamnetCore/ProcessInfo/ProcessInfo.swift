//
//  ProcessInfo.swift
//  hamnet
//
//  Created by deepread on 2020/12/1.
//

import Cocoa
import SwifterSwift

struct ProcessInfo {
    static var processMap: [String: ProcessInfo] = [:]
    
    let appName: String?
    let bundleID: String?
    let appIcon: NSImage?
    let appPath: String?
}


extension ProcessInfo {
    static func process(byPort port: Int) -> ProcessInfo? {
        let pid = get_pid_with_port(Int32(port))
        guard pid > 0 else {
            return nil
        }
        
        var processInfo: ProcessInfo? = nil
        var bundleID: String? = nil
        var appPath: String? = nil
        var appName: String? = nil
        let bufferStr = get_path_with_pid(pid)
        if let bufferStr = bufferStr {
            appPath = String(cString: bufferStr)
            bundleID = appPath
            let strArray = appPath?.components(separatedBy: "/")
            appName = strArray?.last
            free(bufferStr)
        } else {
            return nil
        }
        
        if let runningApp = NSRunningApplication(processIdentifier: pid) {
            bundleID = runningApp.bundleIdentifier
            if bundleID == nil {
                return nil
            }
            
            if let processInfo = ProcessInfo.processMap[bundleID!] {
                return processInfo
            }
            
            appName = runningApp.localizedName
            let icon = runningApp.icon?.scaled(toMaxSize: .init(width: 180, height: 180))
            processInfo = ProcessInfo(
                appName: appName, bundleID: bundleID, appIcon: icon, appPath: appPath
            )
            return processInfo
        } else {
            if bundleID == nil {
                return nil
            }
            if let processInfo = ProcessInfo.processMap[bundleID!] {
                return processInfo
            }
            processInfo = ProcessInfo(
                appName: appName, bundleID: bundleID, appIcon: nil, appPath: appPath
            )
            return processInfo
        }
    }
}


