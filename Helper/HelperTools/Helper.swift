//
//  Helper.swift
//  privilegedHelper
//
//  Created by deepread on 2020/11/18.
//

import SystemConfiguration
import Cocoa
import Security

class Helper: NSObject, NSXPCListenerDelegate {
    
    private var helperTimer: Timer?
    
    private var startPorxy = false
    private var host = "127.0.0.1"
    private var port = 8090

    // MARK: -
    // MARK: Private Constant Variables

    private let listener: NSXPCListener

    // MARK: -
    // MARK: Private Variables

    private var connections = [NSXPCConnection]()
    private var shouldQuitCheckInterval = 1.0
    private var lastPid: Int32?

    // MARK: -
    // MARK: Initialization

    override init() {
        self.listener = NSXPCListener(machServiceName: HelperConstants.machServiceName)
        super.init()
        self.listener.delegate = self
    }

    public func run() {
        self.listener.resume()
        while true {
            self.checkRestProxy()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: self.shouldQuitCheckInterval))
        }
    }
    
    func checkRestProxy() -> Void {
        if let pid = self.lastPid {
            let app = NSRunningApplication.init(processIdentifier: pid)
            if app == nil {
                self.resetProxy()
                return
            } else if app!.isTerminated {
                self.resetProxy()
                return
            }
        }
    }
    
    
    func resetProxy() {
        if self.startPorxy {
            self.startPorxy = false
            self.toggleProxy(enable: false, host: self.host, port: self.port) { res in
                exit(0)
            }
        }
    }

    // MARK: -
    // MARK: NSXPCListenerDelegate Methods

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {

        // Verify that the calling application is signed using the same code signing certificate as the helper
        guard self.isValid(connection: connection) else {
            return false
        }

        // Set the protocol that the calling application conforms to.
        connection.remoteObjectInterface = NSXPCInterface(with: PrivilegedHelperManagerProtocol.self)

        // Set the protocol that the helper conforms to.
        connection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.exportedObject = self

        // Set the invalidation handler to remove this connection when it's work is completed.
        connection.invalidationHandler = {
            if let connectionIndex = self.connections.firstIndex(of: connection) {
                self.connections.remove(at: connectionIndex)
            }

            if self.connections.isEmpty {
                //
            }
        }

        self.connections.append(connection)
        self.lastPid = connection.processIdentifier
        connection.resume()

        return true
    }

    // MARK: -
    
    
    func runCommand(_ command: String, params: [String], completion: @escaping (Bool) -> Void) {

        // For security reasons, all commands should be hardcoded in the helper
        let command = command
        let arguments = params

        // Run the task
        self.runTask(command: command, arguments: arguments, completion: completion)
    }

    // MARK: -
    // MARK: Private Helper Methods

    private func isValid(connection: NSXPCConnection) -> Bool {
        do {
            return try CodesignCheck.codeSigningMatches(pid: connection.processIdentifier)
        } catch {
            self.writeError("Code signing check failed with error: \(error)")
            return false
        }
    }


    private func connection() -> NSXPCConnection? {
        return self.connections.last
    }

    private func runTask(command: String, arguments: Array<String>, completion:@escaping ((Bool) -> Void)) -> Void {
        
        let task = Process()
        let stdOut = Pipe()

        let stdOutHandler =  { (file: FileHandle!) -> Void in
            let data = file.availableData
            guard let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return }
            if let remoteObject = self.connection()?.remoteObjectProxy as? PrivilegedHelperManagerProtocol {
                remoteObject.log(stdOut: output as String)
            }
        }
        stdOut.fileHandleForReading.readabilityHandler = stdOutHandler

        let stdErr:Pipe = Pipe()
        let stdErrHandler =  { (file: FileHandle!) -> Void in
            let data = file.availableData
            guard let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return }
            if let remoteObject = self.connection()?.remoteObjectProxy as? PrivilegedHelperManagerProtocol {
                remoteObject.log(stdErr: output as String)
            }
        }
        stdErr.fileHandleForReading.readabilityHandler = stdErrHandler

        task.launchPath = command
        task.arguments = arguments
        task.standardOutput = stdOut
        task.standardError = stdErr

        task.terminationHandler = { task in
            completion(task.terminationStatus == 0)
        }

        task.launch()
    }
    
    private func writeLog(_ log: String) {
        if let remoteObject = self.connection()?.remoteObjectProxy as? PrivilegedHelperManagerProtocol {
            remoteObject.log(stdOut: log)
        }
    }
    
    private func writeError(_ log: String) {
        if let remoteObject = self.connection()?.remoteObjectProxy as? PrivilegedHelperManagerProtocol {
            remoteObject.log(stdErr: log)
        }
    }
    
    enum HelperResult {
        case success(result: String)
        case error(error: String)
    }
    
}

extension Helper: HelperProtocol {
    
    

    func getVersion(completion: (String) -> Void) {
        completion(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0")
    }
    
    func toggleProxy(enable: Bool, host: String, port: Int, completion: @escaping (Bool) -> Void) -> Void {
        self.writeLog("toggleProxy: \(enable)")
        if enable {
            self.host = host
            self.port = port
        }
        
        var authRef: AuthorizationRef? = nil
        let authFlags: AuthorizationFlags = [.extendRights, .interactionAllowed, .preAuthorize]
            
        let authErr = AuthorizationCreate(nil, nil, authFlags, &authRef)
            
        guard authErr == noErr else {
            self.writeError("Error: Failed to create administration authorization due to error \(authErr).")
            completion(false)
            return
        }
            
        guard authRef != nil else {
            self.writeError("Error: No authorization has been granted to modify network configuration.")
            completion(false)
            return
        }
        if let prefRef = SCPreferencesCreateWithAuthorization(nil, "Hamnet" as CFString, nil, authRef),
           let sets = SCPreferencesGetValue(prefRef, kSCPrefNetworkServices) {
            for key in sets.allKeys {
                guard let dict = sets[key] as? NSDictionary else {
                    completion(false)
                    return
                }
                let hardware = ((dict["Interface"]) as? NSDictionary)?["Hardware"] as? String
                if hardware == "AirPort" || hardware == "Ethernet" {
                    let ip = enable ? host : ""
                    let enableInt = enable ? 1 : 0
                        
                    var proxySettings: [String:AnyObject] = [:]
                    proxySettings[kCFNetworkProxiesHTTPProxy as String] = ip as AnyObject
                    proxySettings[kCFNetworkProxiesHTTPEnable as String] = enableInt as AnyObject
                    proxySettings[kCFNetworkProxiesHTTPSProxy as String] = ip as AnyObject
                    proxySettings[kCFNetworkProxiesHTTPSEnable as String] = enableInt as AnyObject
                    proxySettings[kCFNetworkProxiesSOCKSProxy as String] = "" as AnyObject
                    proxySettings[kCFNetworkProxiesSOCKSEnable as String] = 0 as AnyObject
                    proxySettings[kCFNetworkProxiesSOCKSPort as String] = nil
                    if enable {
                        proxySettings[kCFNetworkProxiesHTTPPort as String] = port as AnyObject
                        proxySettings[kCFNetworkProxiesHTTPSPort as String] = port as AnyObject
                    } else {
                        proxySettings[kCFNetworkProxiesHTTPPort as String] = nil
                        proxySettings[kCFNetworkProxiesHTTPSPort as String] = nil
                    }
//                        proxySettings[kCFNetworkProxiesExceptionsList as String] = [
//                            "192.168.0.0/16",
//                            "10.0.0.0/8",
//                            "172.16.0.0/12",
//                            "127.0.0.1",
//                            "localhost",
//                            "*.local"
//                            ] as AnyObject
                        
                    let path = "/\(kSCPrefNetworkServices)/\(key)/\(kSCEntNetProxies)"
                    SCPreferencesPathSetValue(prefRef, path as CFString, proxySettings as CFDictionary)
                }
            }
            if SCPreferencesCommitChanges(prefRef) {
                if SCPreferencesApplyChanges(prefRef) {
                    SCPreferencesSynchronize(prefRef)
                    if enable {
                        self.startPorxy = true
                    }
                    completion(true)
                    return
                }
            }
        }
        completion(false)
        return
}
}
