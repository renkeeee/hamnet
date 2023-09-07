//
//  CertUtils.swift
//  hamnet
//
//  Created by deepread on 2020/11/15.
//

import Cocoa
import NIO
import CNIOBoringSSL
import NIOSSL

func tmpPath() -> URL {
    let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
    let bundDir = URL.init(fileURLWithPath: cacheDir).appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
    let tmpDir = bundDir.appendingPathComponent("tmp", isDirectory: true)
    try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true, attributes: nil)
    return tmpDir;
}

class CertUtils: NSObject {
    
    static let rsaKey = generateRSAKeyPair()
    static let tmpDir = tmpPath()
    
    static func generateRSAKeyPair() -> UnsafeMutablePointer<EVP_PKEY> {
        let exponent = CNIOBoringSSL_BN_new()
        defer {
            CNIOBoringSSL_BN_free(exponent)
        }
        CNIOBoringSSL_BN_set_u64(exponent, UInt64(RSA_F4))
        let rsa = CNIOBoringSSL_RSA_new()!
        let generateRC = CNIOBoringSSL_RSA_generate_key_ex(rsa, CInt(2048), exponent, nil)
        precondition(generateRC == 1)
        
        let pkey = CNIOBoringSSL_EVP_PKEY_new()!
        let assignRC = CNIOBoringSSL_EVP_PKEY_assign(pkey, EVP_PKEY_RSA, rsa)
        
        precondition(assignRC == 1)
        return pkey
    }
    
    static func generateX509Cert(_ pkey: UnsafeMutablePointer<EVP_PKEY> ) -> UnsafeMutablePointer<X509> {
        // https://stackoverflow.com/questions/256405/programmatically-create-x509-certificate-using-openssl
        let x509 = CNIOBoringSSL_X509_new()!
        CNIOBoringSSL_ASN1_INTEGER_set(CNIOBoringSSL_X509_get_serialNumber(x509), 1)
        CNIOBoringSSL_X509_gmtime_adj(CNIOBoringSSL_X509_get_notBefore(x509), 0)
        CNIOBoringSSL_X509_gmtime_adj(CNIOBoringSSL_X509_get_notAfter(x509), 31536000)
        CNIOBoringSSL_X509_set_pubkey(x509, pkey)
        
        let commonNameDateStr = Date().adding(.year, value: 1).dateTimeString()
        
        let subjectName = CNIOBoringSSL_X509_get_subject_name(x509)
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "C", MBSTRING_ASC, "CA", -1, -1, 0)
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "O", MBSTRING_ASC, "Hamnet App Inc.", -1, -1, 0)
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "CN", MBSTRING_ASC, "Hamnet CA( \(commonNameDateStr))", -1, -1, 0)
        CNIOBoringSSL_X509_set_issuer_name(x509, subjectName)
        
        CNIOBoringSSL_X509_sign(x509, pkey, CNIOBoringSSL_EVP_sha256())
        return x509
    }

    static func CACertDir() -> String {
        let documentDir = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
        let appDir = URL.init(fileURLWithPath: documentDir).appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
        let certDir = appDir.appendingPathComponent("cert", isDirectory: true)
        let isExist = FileManager.default.fileExists(atPath: certDir.absoluteString)
        if !isExist {
            try! FileManager.default.createDirectory(atPath: certDir.absoluteString.removingPrefix("file://"), withIntermediateDirectories: true, attributes: nil)
        }
        return certDir.absoluteString
    }
    
    static func CACertPath() -> String {
        return CACertDir().removingPrefix("file://").appendingPathComponent("cert.pem")
    }
    
    static func CAKeyPath() -> String {
        return CACertDir().removingPrefix("file://").appendingPathComponent("key.pem")
    }
    
    
    static func writeCACert() {
        let pkey = generateRSAKeyPair()
        let x509 = generateX509Cert(pkey)
        let caDir = CACertDir().removingPrefix("file://")
        
        let pemPath = caDir.appendingPathComponent("key.pem")
        let certPath = caDir.appendingPathComponent("cert.pem")
        
        let pkey_file = fopen(pemPath, "wb")
        if pkey_file == nil {
            YLog.error("Unable to open \"key.pem\" for writing.")
            return;
        }
        let pemRes = CNIOBoringSSL_PEM_write_PrivateKey(pkey_file, pkey, nil, nil, 0, nil, nil)
        fclose(pkey_file)
        if pemRes == 0 {
            YLog.error("Unable to write private key to disk.")
            return;
        }
        
        let x509_file = fopen(certPath, "wb")
        if x509_file == nil {
            YLog.error("Unable to open \"cert.pem\" for writing.")
            return;
        }
        let certRes = CNIOBoringSSL_PEM_write_X509(x509_file, x509)
        fclose(x509_file)
        if certRes == 0 {
            YLog.error("Unable to write x509 to disk.")
            return;
        }
        CNIOBoringSSL_EVP_PKEY_free(pkey)
        CNIOBoringSSL_X509_free(x509)
    }
    
    
    static func generateRSAKeyFile() -> String? {
        let tmpPath = tmpDir.absoluteString.removingPrefix("file://").appendingPathComponent("\(UUID().uuidString).pem")
        
        YLog.debug("generateRSAKeyFile tmpPath: \(tmpPath)")
        
        let rsa_key_file = fopen(tmpPath, "wb")
        if rsa_key_file == nil {
            YLog.error("Unable to open \"rsa_key_file\" for writing.")
            return nil
        }
        let _ = CNIOBoringSSL_PEM_write_PrivateKey(rsa_key_file, self.rsaKey, nil, nil, 0, nil, nil)
        fclose(rsa_key_file)
        return tmpPath
    }
    
    static func generateCSRCertFile(host: String) -> String? {
        let caKeyFile = fopen(CAKeyPath(), "rb")
        defer {
            _ = fclose(caKeyFile)
        }
        let caKey = CNIOBoringSSL_PEM_read_PrivateKey(caKeyFile, nil, nil, nil)
        
        let caCertFile = fopen(CACertPath(), "rb")
        defer {
            _ = fclose(caCertFile)
        }
        let caCert = CNIOBoringSSL_PEM_read_X509(caCertFile, nil, nil, nil)
        let rsaKey = CertUtils.rsaKey
        
        let req = CNIOBoringSSL_X509_REQ_new()
        CNIOBoringSSL_X509_REQ_set_pubkey(req, rsaKey)
        
        let subjectName = CNIOBoringSSL_X509_NAME_new()
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "C", MBSTRING_ASC, "CA", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "ST", MBSTRING_ASC, "", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "L", MBSTRING_ASC, "", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "O", MBSTRING_ASC, "Hamnet App Inc.", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "OU", MBSTRING_ASC, "", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "CN", MBSTRING_ASC, host, -1, -1, 0);
        CNIOBoringSSL_X509_REQ_set_subject_name(req, subjectName)
        
        CNIOBoringSSL_X509_REQ_sign(req, rsaKey, CNIOBoringSSL_EVP_sha256())
        
        let crt = CNIOBoringSSL_X509_new()

        CNIOBoringSSL_X509_set_version(crt, 2)
        let serial = Int(arc4random_uniform(UInt32.max))
        CNIOBoringSSL_ASN1_INTEGER_set(CNIOBoringSSL_X509_get_serialNumber(crt), serial)
        CNIOBoringSSL_X509_set_issuer_name(crt, CNIOBoringSSL_X509_get_subject_name(caCert))
        
        CNIOBoringSSL_X509_gmtime_adj(CNIOBoringSSL_X509_get_notBefore(crt), 0)
        CNIOBoringSSL_X509_gmtime_adj(CNIOBoringSSL_X509_get_notAfter(crt), 31536000)
        CNIOBoringSSL_X509_set_subject_name(crt, subjectName)
        
        let reqPubKey = CNIOBoringSSL_X509_REQ_get_pubkey(req)
        CNIOBoringSSL_X509_set_pubkey(crt, reqPubKey)
        CNIOBoringSSL_EVP_PKEY_free(reqPubKey)
        
        // See https://support.apple.com/en-us/HT210176
        addExtension(x509: crt!, nid: NID_basic_constraints, value: "critical,CA:FALSE")
        addExtension(x509: crt!, nid: NID_ext_key_usage, value: "serverAuth,OCSPSigning")
        addExtension(x509: crt!, nid: NID_subject_key_identifier, value: "hash")
        addExtension(x509: crt!, nid: NID_subject_alt_name, value: "DNS:" + host)
        /* Now perform the actual signing with the CA. */
        CNIOBoringSSL_X509_sign(crt, caKey, CNIOBoringSSL_EVP_sha256())
        CNIOBoringSSL_X509_REQ_free(req)
        
        let tmpPath = tmpDir.absoluteString.removingPrefix("file://").appendingPathComponent("\(UUID().uuidString).crt")
        
        let crt_file = fopen(tmpPath, "wb")
        if crt_file == nil {
            YLog.error("Unable to open \"crt_file\" for writing.")
            return nil
        }
        let _ = CNIOBoringSSL_PEM_write_X509(crt_file, crt)
        fclose(crt_file)
        CNIOBoringSSL_X509_free(crt)
        return tmpPath
    }
    
    static func generateCSRCertFileLocalHost() -> String? {
        let caKeyFile = fopen(CAKeyPath(), "rb")
        defer {
            _ = fclose(caKeyFile)
        }
        let caKey = CNIOBoringSSL_PEM_read_PrivateKey(caKeyFile, nil, nil, nil)
        
        let caCertFile = fopen(CACertPath(), "rb")
        defer {
            _ = fclose(caCertFile)
        }
        let caCert = CNIOBoringSSL_PEM_read_X509(caCertFile, nil, nil, nil)
        let rsaKey = CertUtils.rsaKey
        
        let req = CNIOBoringSSL_X509_REQ_new()
        CNIOBoringSSL_X509_REQ_set_pubkey(req, rsaKey)
        
        let subjectName = CNIOBoringSSL_X509_NAME_new()
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "C", MBSTRING_ASC, "CA", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "ST", MBSTRING_ASC, "", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "L", MBSTRING_ASC, "", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "O", MBSTRING_ASC, "Hamnet App Inc.", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "OU", MBSTRING_ASC, "", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "CN", MBSTRING_ASC, "localhost.localdomain", -1, -1, 0);
        CNIOBoringSSL_X509_REQ_set_subject_name(req, subjectName)
        
        CNIOBoringSSL_X509_REQ_sign(req, rsaKey, CNIOBoringSSL_EVP_sha256())
        
        let crt = CNIOBoringSSL_X509_new()

        CNIOBoringSSL_X509_set_version(crt, 2)
        let serial = Int(arc4random_uniform(UInt32.max))
        CNIOBoringSSL_ASN1_INTEGER_set(CNIOBoringSSL_X509_get_serialNumber(crt), serial)
        CNIOBoringSSL_X509_set_issuer_name(crt, CNIOBoringSSL_X509_get_subject_name(caCert))
        
        CNIOBoringSSL_X509_gmtime_adj(CNIOBoringSSL_X509_get_notBefore(crt), 0)
        CNIOBoringSSL_X509_gmtime_adj(CNIOBoringSSL_X509_get_notAfter(crt), 31536000)
        CNIOBoringSSL_X509_set_subject_name(crt, subjectName)
        
        let reqPubKey = CNIOBoringSSL_X509_REQ_get_pubkey(req)
        CNIOBoringSSL_X509_set_pubkey(crt, reqPubKey)
        CNIOBoringSSL_EVP_PKEY_free(reqPubKey)
        
        // See https://support.apple.com/en-us/HT210176
        addExtension(x509: crt!, nid: NID_basic_constraints, value: "critical,CA:FALSE")
        addExtension(x509: crt!, nid: NID_ext_key_usage, value: "serverAuth,OCSPSigning")
        addExtension(x509: crt!, nid: NID_subject_key_identifier, value: "hash")
        addExtension(x509: crt!, nid: NID_subject_alt_name, value: "DNS:" + "localhost.localdomain")
        /* Now perform the actual signing with the CA. */
        CNIOBoringSSL_X509_sign(crt, caKey, CNIOBoringSSL_EVP_sha256())
        CNIOBoringSSL_X509_REQ_free(req)
        
        let tmpPath = tmpDir.absoluteString.removingPrefix("file://").appendingPathComponent("\(UUID().uuidString).crt")
        
        let crt_file = fopen(tmpPath, "wb")
        if crt_file == nil {
            YLog.error("Unable to open \"crt_file\" for writing.")
            return nil
        }
        let _ = CNIOBoringSSL_PEM_write_X509(crt_file, crt)
        fclose(crt_file)
        CNIOBoringSSL_X509_free(crt)
        return tmpPath
    }
    
    
    static func generateCSRCertFile(ip: String) -> String? {
        let caKeyFile = fopen(CAKeyPath(), "rb")
        defer {
            _ = fclose(caKeyFile)
        }
        let caKey = CNIOBoringSSL_PEM_read_PrivateKey(caKeyFile, nil, nil, nil)
        
        let caCertFile = fopen(CACertPath(), "rb")
        defer {
            _ = fclose(caCertFile)
        }
        let caCert = CNIOBoringSSL_PEM_read_X509(caCertFile, nil, nil, nil)
        let rsaKey = CertUtils.rsaKey
        
        let req = CNIOBoringSSL_X509_REQ_new()
        CNIOBoringSSL_X509_REQ_set_pubkey(req, rsaKey)
        
        let subjectName = CNIOBoringSSL_X509_NAME_new()
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "C", MBSTRING_ASC, "CA", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "ST", MBSTRING_ASC, "", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "L", MBSTRING_ASC, "", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "O", MBSTRING_ASC, "Hamnet App Inc.", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "OU", MBSTRING_ASC, "", -1, -1, 0);
        CNIOBoringSSL_X509_NAME_add_entry_by_txt(subjectName, "CN", MBSTRING_ASC, ip, -1, -1, 0);
        CNIOBoringSSL_X509_REQ_set_subject_name(req, subjectName)
        
        CNIOBoringSSL_X509_REQ_sign(req, rsaKey, CNIOBoringSSL_EVP_sha256())
        
        let crt = CNIOBoringSSL_X509_new()

        CNIOBoringSSL_X509_set_version(crt, 2)
        let serial = Int(arc4random_uniform(UInt32.max))
        CNIOBoringSSL_ASN1_INTEGER_set(CNIOBoringSSL_X509_get_serialNumber(crt), serial)
        CNIOBoringSSL_X509_set_issuer_name(crt, CNIOBoringSSL_X509_get_subject_name(caCert))
        
        CNIOBoringSSL_X509_gmtime_adj(CNIOBoringSSL_X509_get_notBefore(crt), 0)
        CNIOBoringSSL_X509_gmtime_adj(CNIOBoringSSL_X509_get_notAfter(crt), 31536000)
        CNIOBoringSSL_X509_set_subject_name(crt, subjectName)
        
        let reqPubKey = CNIOBoringSSL_X509_REQ_get_pubkey(req)
        CNIOBoringSSL_X509_set_pubkey(crt, reqPubKey)
        CNIOBoringSSL_EVP_PKEY_free(reqPubKey)
        
        // See https://support.apple.com/en-us/HT210176
        addExtension(x509: crt!, nid: NID_basic_constraints, value: "critical,CA:FALSE")
        addExtension(x509: crt!, nid: NID_ext_key_usage, value: "serverAuth,OCSPSigning")
        addExtension(x509: crt!, nid: NID_subject_key_identifier, value: "hash")
        addExtension(x509: crt!, nid: NID_subject_alt_name, value: "IP:" + ip)
        /* Now perform the actual signing with the CA. */
        CNIOBoringSSL_X509_sign(crt, caKey, CNIOBoringSSL_EVP_sha256())
        CNIOBoringSSL_X509_REQ_free(req)
        
        let tmpPath = tmpDir.absoluteString.removingPrefix("file://").appendingPathComponent("\(UUID().uuidString).crt")
        
        let crt_file = fopen(tmpPath, "wb")
        if crt_file == nil {
            YLog.error("Unable to open \"crt_file\" for writing.")
            return nil
        }
        let _ = CNIOBoringSSL_PEM_write_X509(crt_file, crt)
        fclose(crt_file)
        CNIOBoringSSL_X509_free(crt)
        return tmpPath
    }
    
    static func addExtension(x509: UnsafeMutablePointer<X509>, nid: CInt, value: String) {
        var extensionContext = X509V3_CTX()
        
        CNIOBoringSSL_X509V3_set_ctx(&extensionContext, x509, x509, nil, nil, 0)
        let ext = value.withCString { (pointer) in
            return CNIOBoringSSL_X509V3_EXT_nconf_nid(nil, &extensionContext, nid, UnsafeMutablePointer(mutating: pointer))
        }!
        CNIOBoringSSL_X509_add_ext(x509, ext, -1)
        CNIOBoringSSL_X509_EXTENSION_free(ext)
    }
    
    
}
