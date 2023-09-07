//
//  PrivilegedHelperManagerProtocol.swift
//  hamnet
//
//  Created by deepread on 2020/11/18.
//

import Cocoa

@objc(AppProtocol)
protocol PrivilegedHelperManagerProtocol {
    func log(stdOut: String) -> Void
    func log(stdErr: String) -> Void
}
