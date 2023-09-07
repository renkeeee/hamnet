//
//  PrivilegedConstants.swift
//  hamnet
//
//  Created by deepread on 2020/11/18.
//

import Foundation

let kAuthorizationRightKeyClass     = "class"
let kAuthorizationRightKeyGroup     = "group"
let kAuthorizationRightKeyRule      = "rule"
let kAuthorizationRightKeyTimeout   = "timeout"
let kAuthorizationRightKeyVersion   = "version"

let kAuthorizationFailedExitCode    = NSNumber(value: 503340)

struct HelperConstants {
    static let machServiceName = "com.deepread.app.hamnet.privilegedHelper"
}


struct HelperAuthRight {
    let name: String
    let ruleCustom: [String: Any]?
    let ruleConstant: String?

    init(ruleCustom: [String: Any]? = nil, ruleConstant: String? = nil) {
        self.name = HelperConstants.machServiceName + " install cert and set proxy"
        self.ruleCustom = ruleCustom
        self.ruleConstant = ruleConstant
    }

    func rule() -> CFTypeRef {
        let rule: CFTypeRef
        if let ruleCustom = self.ruleCustom as CFDictionary? {
            rule = ruleCustom
        } else if let ruleConstant = self.ruleConstant as CFString? {
            rule = ruleConstant
        } else {
            rule = kAuthorizationRuleAuthenticateAsAdmin as CFString
        }

        return rule
    }
}
