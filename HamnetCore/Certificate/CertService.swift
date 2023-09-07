//
//  CertService.swift
//  hamnet
//
//  Created by deepread on 2020/11/15.
//

import Cocoa
import NIO
import NIOSSL
import SwiftyUserDefaults

class CertService {
    static let shared = CertService()
    
    private init() {
        loadCACert()
        loadRSAKey()
    }
    
    var caCert: NIOSSLCertificate!
    var caKey: NIOSSLPrivateKey!
    
    var rsaKey: NIOSSLPrivateKey!
    var certPool: [String: NIOSSLCertificate]!
    var ipCertPool: [String: NIOSSLCertificate]!
    
    
    func isCACertFileExist() -> Bool {
        let caDir = CertUtils.CACertDir().removingPrefix("file://")
        let caCertPath = caDir.appendingPathComponent("cert.pem")
        let caKeyPath = caDir.appendingPathComponent("key.pem")
        
        guard let _ = try? NIOSSLCertificate(file: caCertPath, format: .pem) else {
            YLog.info("certPath is not exist")
            return false
        }
        
        guard let _ = try? NIOSSLPrivateKey(file: caKeyPath, format: .pem) else {
            YLog.info("caKeyPath is not exist")
            return false
        }
        return true
    }
    
    func caCertObj() -> MOLCertificate? {
        let caDir = CertUtils.CACertDir().removingPrefix("file://")
        let caCertPath = caDir.appendingPathComponent("cert.pem")
        let certData = NSData.init(contentsOfFile: caCertPath)
        guard let _ = certData else {
            return nil
        }
        let certStr = String.init(data: certData! as Data, encoding: .utf8)
        guard let _ = certStr else {
            return nil
        }
        let certObj = MOLCertificate.init(certificateDataPEM: certStr!)
        return certObj
    }
    
    func isCACertExpired() -> Bool {
        let certObj = caCertObj()
        guard let _ = certObj else {
            return true
        }
        let expiredDate = certObj!.validFrom
        guard let exp = expiredDate, exp.isInPast else {
            return true
        }
        return false
    }
    
    func installCACert(_ data: Data) -> Bool {
        
        guard let certificate: SecCertificate = SecCertificateCreateWithData(nil, data as CFData) else {
            YLog.error("has no certificate")
            return false
        }
        
        let addquery: [String: Any] = [kSecClass as String: kSecClassCertificate,
                                        kSecValueRef as String: certificate,
                                        kSecAttrLabel as String: "HamnetCACert"]
        let status = SecItemAdd(addquery as CFDictionary, nil)
        guard status == errSecSuccess else {
            YLog.error("error \(status) : " + (SecCopyErrorMessageString(status, nil)! as String))
            return false
        }

        let result = SecTrustSettingsSetTrustSettings(certificate, .user, [kSecTrustSettingsResult: NSNumber(value: SecTrustSettingsResult.trustRoot.rawValue)] as CFTypeRef)
        YLog.error("result = \(result) : " + (SecCopyErrorMessageString(result, nil)! as String))
        
        if result == 0 {
            return true
        }
        return false
    }
    
    func trustCACert() -> Bool {
        if isCACertFileExist() == false {
            CertUtils.writeCACert()
            if isCACertFileExist() == false {
                return false
            }
        }
        
        let caData = caCertObj()?.certData!
        return self.installCACert(caData!)
    }
    
    func deleteCACert() {
        if !isCACertFileExist() {
            return
        }
    }
    
    
    func loadCACert() {
        self.certPool = [:] as [String: NIOSSLCertificate]
        self.ipCertPool = [:] as [String: NIOSSLCertificate]
        let caDir = CertUtils.CACertDir().removingPrefix("file://")
        let caCertPath = caDir.appendingPathComponent("cert.pem")
        let caKeyPath = caDir.appendingPathComponent("key.pem")
        
        if let cert = try? NIOSSLCertificate(file: caCertPath, format: .pem) {
            self.caCert = cert
        } else {
            YLog.error("Load CA cert error")
            return
        }
        
        if let key = try? NIOSSLPrivateKey(file: caKeyPath, format: .pem) {
            self.caKey = key
        } else {
            YLog.error("Load CA key error")
            return
        }
    }
    
    
    func fetchSSLCertificateLocalHost() -> NIOSSLCertificate? {
        let dynamicCert = self.certPool["localhost.localdomain"]
        if dynamicCert == nil {
            let crtFilePath = CertUtils.generateCSRCertFileLocalHost()
            guard let _ = crtFilePath else {
                return nil
            }
            let cert = try? NIOSSLCertificate(file: crtFilePath!, format: .pem)
            _ = try? FileManager.default.removeItem(atPath: crtFilePath!)
            guard let _ = cert else {
                return nil
            }
            DispatchQueue.main.async {
                self.certPool["localhost.localdomain"] = cert
            }
            return cert
        } else {
             return dynamicCert
        }
    }
    
    func fetchSSLCertificate(_ host: String) -> NIOSSLCertificate? {
        let dynamicCert = self.certPool[host]
        if dynamicCert == nil {
            let crtFilePath = CertUtils.generateCSRCertFile(host: host)
            guard let _ = crtFilePath else {
                return nil
            }
            let cert = try? NIOSSLCertificate(file: crtFilePath!, format: .pem)
            _ = try? FileManager.default.removeItem(atPath: crtFilePath!)
            guard let _ = cert else {
                return nil
            }
            DispatchQueue.main.async {
                self.certPool[host] = cert
            }
            return cert
        } else {
             return dynamicCert
        }
    }
    
    func fetchIPCertificate(_ ip: String) -> NIOSSLCertificate? {
        let dynamicCert = self.ipCertPool[ip]
        if dynamicCert == nil {
            let crtFilePath = CertUtils.generateCSRCertFile(ip: ip)
            guard let _ = crtFilePath else {
                return nil
            }
            let cert = try? NIOSSLCertificate(file: crtFilePath!, format: .pem)
            _ = try? FileManager.default.removeItem(atPath: crtFilePath!)
            guard let _ = cert else {
                return nil
            }
            DispatchQueue.main.async {
                self.ipCertPool[ip] = cert
            }
            return cert
        } else {
             return dynamicCert
        }
    }
    
    func loadRSAKey() {
        YLog.debug("loadRSAKey start")
        let rsaFile = CertUtils.generateRSAKeyFile()
        YLog.debug("rsaFile \(String(describing: rsaFile))")
        self.rsaKey = try? NIOSSLPrivateKey(file: rsaFile!, format: .pem)
        _ = try? FileManager.default.removeItem(atPath: rsaFile!)
    }
}

extension CertService {

    public func generateCACert() {
        
    }
}

