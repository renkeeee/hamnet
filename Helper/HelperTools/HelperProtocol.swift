//
//  HelperProtocol.swift
//  hamnet
//
//  Created by deepread on 2020/11/18.
//

import Cocoa



@objc(HelperProtocol)
protocol HelperProtocol {
    func getVersion(completion: @escaping (String) -> Void)
    func toggleProxy(enable: Bool, host: String, port: Int, completion: @escaping (Bool) -> Void) -> Void
}
