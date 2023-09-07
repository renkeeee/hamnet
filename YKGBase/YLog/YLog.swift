//
//  YLog.swift
//  hamnet
//
//  Created by deepread on 2020/11/7.
//

import Foundation
import Cocoa
import XCGLogger
import SwifterSwift


func logFilePath() -> URL {
    let tmpDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
    let logDir = URL.init(fileURLWithPath: tmpDir).appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
    let logFilePath = logDir.appendingPathComponent("logs").appendingPathExtension("log")
    try! FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true, attributes: nil)
    return logFilePath;
}

let YLog: XCGLogger = {
   let log = XCGLogger(identifier: Bundle.main.bundleIdentifier!, includeDefaultDestinations: false)
    
    #if DEBUG
    
    let systemDestination = AppleSystemLogDestination(identifier: "UpDownLogger.sysDestination")
    
    systemDestination.outputLevel = .debug
    systemDestination.showLogIdentifier = false
    systemDestination.showFunctionName = true
    systemDestination.showThreadName = true
    systemDestination.showLevel = true
    systemDestination.showFileName = true
    systemDestination.showLineNumber = false
    systemDestination.showDate = false
    
    log.add(destination: systemDestination)
    
    #endif
    
//    let fileDestination = FileDestination(writeToFile: logFilePath(), identifier: "UpDownLogger.fileDestination")
    let fileDestination = AutoRotatingFileDestination(writeToFile: logFilePath(), identifier: "UpDownLogger.fileDestination", shouldAppend: true, appendMarker: "-- Relauched App --")

    fileDestination.outputLevel = .debug
    fileDestination.showLogIdentifier = false
    fileDestination.showFunctionName = true
    fileDestination.showThreadName = true
    fileDestination.showLevel = true
    fileDestination.showFileName = true
    fileDestination.showLineNumber = true
    fileDestination.showDate = true

    fileDestination.logQueue = XCGLogger.logQueue

    log.add(destination: fileDestination)
    log.logAppDetails()
    
    return log
}()

