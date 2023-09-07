//
//  PrivilegedAuth.swift
//  hamnet
//
//  Created by deepread on 2020/11/18.
//

import Cocoa

enum HelperAuthError: Error {
    case message(String)
}

class PrivilegedAuth {
    
    static let authorizationRight =
        HelperAuthRight(ruleCustom: [kAuthorizationRightKeyClass: "user", kAuthorizationRightKeyGroup: "admin", kAuthorizationRightKeyVersion: 1])
    
    static func authorizationRef(_ rights: UnsafePointer<AuthorizationRights>?,
                                 _ environment: UnsafePointer<AuthorizationEnvironment>?,
                                 _ flags: AuthorizationFlags) throws -> AuthorizationRef? {
        var authRef: AuthorizationRef?
        try executeAuthorizationFunction { AuthorizationCreate(rights, environment, flags, &authRef) }
        return authRef
    }
    
    
    static func authorizationRightsUpdateDatabase() throws {
        guard let authRef = try self.emptyAuthorizationRef() else {
            throw HelperAuthError.message("Failed to get empty authorization ref")
        }

        var osStatus = errAuthorizationSuccess
        var currentRule: CFDictionary?

        osStatus = AuthorizationRightGet(authorizationRight.name, &currentRule)
        if osStatus == errAuthorizationDenied || self.authorizationRuleUpdateRequired(currentRule, authorizationRight: authorizationRight) {
            osStatus = AuthorizationRightSet(authRef,
                                             authorizationRight.name,
                                             authorizationRight.rule(),
                                             authorizationRight.name as CFString,
                                             nil,
                                             nil)
        }

        guard osStatus == errAuthorizationSuccess else {
            YLog.error("AuthorizationRightSet or Get failed with error: \(String(describing: SecCopyErrorMessageString(osStatus, nil)))")
            return
        }
    }
    
    static func authorizationRuleUpdateRequired(_ currentRuleCFDict: CFDictionary?, authorizationRight: HelperAuthRight) -> Bool {
        guard let currentRuleDict = currentRuleCFDict as? [String: Any] else {
            return true
        }
        let newRule = authorizationRight.rule()
        if CFGetTypeID(newRule) == CFStringGetTypeID() {
            if
                let currentRule = currentRuleDict[kAuthorizationRightKeyRule] as? [String],
                let newRule = authorizationRight.ruleConstant {
                return currentRule != [newRule]

            }
        } else if CFGetTypeID(newRule) == CFDictionaryGetTypeID() {
            if let currentVersion = currentRuleDict[kAuthorizationRightKeyVersion] as? Int,
                let newVersion = authorizationRight.ruleCustom?[kAuthorizationRightKeyVersion] as? Int {
                return currentVersion != newVersion
            }
        }
        return true
    }
    
    static func emptyAuthorizationRef() throws -> AuthorizationRef? {
        var authRef: AuthorizationRef?

        // Create an empty AuthorizationRef
        try executeAuthorizationFunction { AuthorizationCreate(nil, nil, [], &authRef) }
        return authRef
    }
}

// MARK: -
// MARK: Private Function
extension PrivilegedAuth {
    
    // MARK: -
    // MARK: Authorization Wrapper
    private static func executeAuthorizationFunction(_ authorizationFunction: () -> (OSStatus) ) throws {
        let osStatus = authorizationFunction()
        guard osStatus == errAuthorizationSuccess else {
            throw HelperAuthError.message(String(describing: SecCopyErrorMessageString(osStatus, nil)))
        }
    }
}
