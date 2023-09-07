//
//  PrivilegedHelperManager.swift
//  hamnet
//
//  Created by deepread on 2020/11/18.
//

import Cocoa
import ServiceManagement
import Security



class PrivilegedHelperManager: NSObject {
    
    // MARK: - Public
    
    public static var shared: PrivilegedHelperManager {
        let shared = PrivilegedHelperManager()
        return shared
    }
    
    public func useBeforeCheck(completion: @escaping (_ success: Bool) -> Void) {
        prepareAuthRightSets()
        self.helperStatus { success in
            if success {
                YLog.info("helper already installed")
                completion(true)
            } else {
                do {
                    if try self.helperInstall() {
                        YLog.info("Helper installed successfully.")
                        completion(true)
                    } else {
                        YLog.error("Failed install helper with unknown error.")
                        completion(false)
                    }
                } catch {
                    YLog.error("Failed to install helper with error: \(error)")
                    completion(false)
                }
            }
        }
    }
    
    public func toggleProxy(enable: Bool, host: String, port: Int, completion: @escaping (_ success: Bool) -> Void) -> Void {
        guard let helperTool = self.helper(nil) else {
            completion(false)
            return
        }
        helperTool.toggleProxy(enable: enable, host: host, port: port, completion: completion)
    }
    
    

    
    // MARK: - Private
    
    private override init() {
        super.init()
    }
    
    private var currentHelperConnection: NSXPCConnection?
    
    private func prepareAuthRightSets() {
        do {
            try PrivilegedAuth.authorizationRightsUpdateDatabase()
        } catch {
            YLog.error("Failed to update the authorization database rights with error: \(error)")
        }
    }
    
    private func helper(_ completion: ((Bool) -> Void)?) -> HelperProtocol? {

        // Get the current helper connection and return the remote object (Helper.swift) as a proxy object to call functions on.

        guard let helper = self.helperConnection()?.remoteObjectProxyWithErrorHandler({ error in
            YLog.error("Helper connection was closed with error: \(error)")
            if let onCompletion = completion { onCompletion(false) }
        }) as? HelperProtocol else { return nil }
        return helper
    }
    
    private func helperStatus(completion: @escaping (_ installed: Bool) -> Void) {

        // Comppare the CFBundleShortVersionString from the Info.plist in the helper inside our application bundle with the one on disk.

        let helperURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LaunchServices/" + HelperConstants.machServiceName)
        guard
            let helperBundleInfo = CFBundleCopyInfoDictionaryForURL(helperURL as CFURL) as? [String: Any],
            let helperVersion = helperBundleInfo["CFBundleShortVersionString"] as? String,
            let helper = self.helper(completion) else {
                completion(false)
                return
        }

        helper.getVersion { installedHelperVersion in
            completion(installedHelperVersion == helperVersion)
        }
    }
    
    private func helperInstall() throws -> Bool {

        // Install and activate the helper inside our application bundle to disk.

        var cfError: Unmanaged<CFError>?
        return try kSMRightBlessPrivilegedHelper.withCString
        {
            var authItem = AuthorizationItem(name: $0, valueLength: 0, value:UnsafeMutableRawPointer(bitPattern: 0), flags: 0)
            return try withUnsafeMutablePointer(to: &authItem)
            {
                var authRights = AuthorizationRights(count: 1, items: $0)

                guard
                    let authRef = try PrivilegedAuth.authorizationRef(&authRights, nil, [.interactionAllowed, .extendRights, .preAuthorize]),
                    SMJobBless(kSMDomainSystemLaunchd, HelperConstants.machServiceName as CFString, authRef, &cfError) else {
                        if let error = cfError?.takeRetainedValue() { throw error }
                        return false
                }

                self.currentHelperConnection?.invalidate()
                self.currentHelperConnection = nil

                return true
            }
        }
    }
    
    private func helperConnection() -> NSXPCConnection? {
        guard self.currentHelperConnection == nil else {
            return self.currentHelperConnection
        }

        let connection = NSXPCConnection(machServiceName: HelperConstants.machServiceName, options: .privileged)
        connection.exportedInterface = NSXPCInterface(with: PrivilegedHelperManagerProtocol.self)
        connection.exportedObject = self
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.invalidationHandler = {
            self.currentHelperConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self.currentHelperConnection = nil
            }
        }
        self.currentHelperConnection = connection
        self.currentHelperConnection?.resume()

        return self.currentHelperConnection
    }
    
}

extension PrivilegedHelperManager: PrivilegedHelperManagerProtocol {
    func log(stdOut: String) {
        guard !stdOut.isEmpty else { return }
        YLog.info("Helper-Info: \(stdOut)")
    }

    func log(stdErr: String) {
        guard !stdErr.isEmpty else { return }
        YLog.error("Helper-Error: \(stdErr)")
    }
}

