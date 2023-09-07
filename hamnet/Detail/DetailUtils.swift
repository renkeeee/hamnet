//
//  RequestDetailUtils.swift
//  hamnet
//
//  Created by deepread on 2020/11/29.
//

import Foundation
import NIOHTTP1
import SwifterSwift
import SwiftyAttributes


func parseRequestOverviewText(_ record: Record) -> NSAttributedString {
    
    let mutableAttributedString = NSMutableAttributedString()
    let newLine = NSAttributedString(string: "\n")
    let spaceLine = NSAttributedString(string: " ")
    
    let method = (record.requestHead?.method.rawValue) ?? ""
    var methodAttr: NSMutableAttributedString?
    if method == "WS" {
        methodAttr = method.withTextColor(.systemOrange).withFont(.boldSystemFont(ofSize: 12))
    } else if method == "GET" {
        methodAttr = method.withTextColor(.systemGreen).withFont(.boldSystemFont(ofSize: 12))
    } else if method == "POST" {
        methodAttr = method.withTextColor(.systemBlue).withFont(.boldSystemFont(ofSize: 12))
    } else if method == "PUT" {
        methodAttr = method.withTextColor(.systemTeal).withFont(.boldSystemFont(ofSize: 12))
    } else if method == "OPTION" {
        methodAttr = method.withTextColor(.systemPink).withFont(.boldSystemFont(ofSize: 12))
    } else if method == "DELETE" {
        methodAttr = method.withTextColor(.systemBrown).withFont(.boldSystemFont(ofSize: 12))
    } else if method == "CONNECT" {
        methodAttr = method.withTextColor(.systemGray).withFont(.boldSystemFont(ofSize: 12))
    } else {
        methodAttr = method.withTextColor(.systemPurple).withFont(.boldSystemFont(ofSize: 12))
    }
    
    
    
    mutableAttributedString.append(methodAttr!)
    mutableAttributedString.append(spaceLine)
    
    let version = (record.requestHead?.version.description) ?? ""
    let versionAttr = version.withTextColor(.systemGray).withFont(.boldSystemFont(ofSize: 12))
    mutableAttributedString.append(versionAttr)
    mutableAttributedString.append(newLine)
    
    let url = record.urlString
    let urlAttr = url.withTextColor(.systemBlue).withFont(.systemFont(ofSize: 12))
    mutableAttributedString.append(urlAttr)
    mutableAttributedString.append(newLine)
    
    let headsOption = record.requestHead?.headers
    var contentType: String? = nil
    if let heads = headsOption {
        for head in heads {
            let keyValue = "\(head.name):  "
            let keyAttr = keyValue.withTextColor(.systemBrown).withFont(.boldSystemFont(ofSize: 12))
            mutableAttributedString.append(keyAttr)
            let valueAttr = head.value.withTextColor(.systemGray).withFont(.systemFont(ofSize: 12))
            mutableAttributedString.append(valueAttr)
            mutableAttributedString.append(newLine)
            if head.name.lowercased().contains("content-type") {
                contentType = head.value
            }
        }
    }
    
    if let bodyBuf = record.requestBody, let contentType = contentType {
        if contentType.contains("text/") {
            let byteStr = bodyBuf.getString(at: 0, length: bodyBuf.readableBytes, encoding: .utf8)
            if let bodyStr = byteStr {
                mutableAttributedString.append(newLine)
                mutableAttributedString.append(newLine)
                let spiltAttr = "<*----Request Body----*>".withTextColor(.systemGray).withFont(.systemFont(ofSize: 11))
                mutableAttributedString.append(spiltAttr)
                mutableAttributedString.append(newLine)
                mutableAttributedString.append(newLine)
                let bodyAttr = bodyStr.withTextColor(.systemGray).withFont(.systemFont(ofSize: 11))
                mutableAttributedString.append(bodyAttr)
                mutableAttributedString.append(newLine)
            } else {
                mutableAttributedString.append(newLine)
                mutableAttributedString.append(newLine)
                let spiltAttr = "/----Request Body Cannot Read As Plain Text----/".withTextColor(.systemGray).withFont(.systemFont(ofSize: 11))
                mutableAttributedString.append(spiltAttr)
                mutableAttributedString.append(newLine)
            }
        } else {
            mutableAttributedString.append(newLine)
            mutableAttributedString.append(newLine)
            let spiltAttr = "/----Request Body Isn't Plain Text----/".withTextColor(.systemGray).withFont(.systemFont(ofSize: 11))
            mutableAttributedString.append(spiltAttr)
            mutableAttributedString.append(newLine)
        }
    }

    return mutableAttributedString
    
}


func parseResonseOverviewText(_ record: Record) -> NSAttributedString {
    
    let mutableAttributedString = NSMutableAttributedString()
    let newLine = NSAttributedString(string: "\n")
    let spaceLine = NSAttributedString(string: " ")
    
    guard let _ = record.responseHead else {
        return mutableAttributedString
    }
    
    let statusCode = "\((record.responseHead?.status.code) ?? 0)"
    let statusPhrase = "(\((record.responseHead?.status.reasonPhrase) ?? ""))"
    var statusCodeAttr: NSMutableAttributedString?
    
    if statusCode.hasPrefix("2") {
        statusCodeAttr = statusCode.withTextColor(.systemGreen).withFont(.boldSystemFont(ofSize: 12))
    } else if statusCode.hasPrefix("1") {
        statusCodeAttr = statusCode.withTextColor(.systemGray).withFont(.boldSystemFont(ofSize: 12))
    } else if statusCode.hasPrefix("3") {
        statusCodeAttr = statusCode.withTextColor(.systemOrange).withFont(.boldSystemFont(ofSize: 12))
    } else if statusCode.hasPrefix("4") {
        statusCodeAttr = statusCode.withTextColor(.systemYellow).withFont(.boldSystemFont(ofSize: 12))
    } else if statusCode.hasPrefix("5") {
        statusCodeAttr = statusCode.withTextColor(.systemRed).withFont(.boldSystemFont(ofSize: 12))
    } else {
        statusCodeAttr = statusCode.withTextColor(.systemBrown).withFont(.boldSystemFont(ofSize: 12))
    }
    
    
    mutableAttributedString.append(statusCodeAttr!)
    mutableAttributedString.append(spaceLine)
    let statusPhraseAttr = statusPhrase.withTextColor(.systemGray).withFont(.systemFont(ofSize: 12))
    mutableAttributedString.append(statusPhraseAttr)
    mutableAttributedString.append(spaceLine)
    
    let version = (record.responseHead?.version.description) ?? ""
    let versionAttr = version.withTextColor(.systemGray).withFont(.boldSystemFont(ofSize: 12))
    mutableAttributedString.append(versionAttr)
    mutableAttributedString.append(newLine)
    
    let headsOption = record.responseHead?.headers
    var contentType: String? = nil
    if let heads = headsOption {
        for head in heads {
            let keyValue = "\(head.name):  "
            let keyAttr = keyValue.withTextColor(.systemBrown).withFont(.boldSystemFont(ofSize: 12))
            mutableAttributedString.append(keyAttr)
            let valueAttr = head.value.withTextColor(.systemGray).withFont(.systemFont(ofSize: 12))
            mutableAttributedString.append(valueAttr)
            mutableAttributedString.append(newLine)
            if head.name.lowercased().contains("content-type") {
                contentType = head.value
            }
        }
    }
    
    if let bodyData = record.actualRspBodyData, let contentType = contentType {
        if contentType.contains("text/") {
            let byteStr = String(data: bodyData, encoding: .utf8)
            if let bodyStr = byteStr {
                mutableAttributedString.append(newLine)
                mutableAttributedString.append(newLine)
                let spiltAttr = "<*----Request Body----*>".withTextColor(.systemGray).withFont(.systemFont(ofSize: 11))
                mutableAttributedString.append(spiltAttr)
                mutableAttributedString.append(newLine)
                mutableAttributedString.append(newLine)
                let bodyAttr = bodyStr.withTextColor(.systemGray).withFont(.systemFont(ofSize: 11))
                mutableAttributedString.append(bodyAttr)
                mutableAttributedString.append(newLine)
            } else {
                mutableAttributedString.append(newLine)
                mutableAttributedString.append(newLine)
                let spiltAttr = "/----Request Body Isn't Plain Text----/".withTextColor(.systemGray).withFont(.systemFont(ofSize: 11))
                mutableAttributedString.append(spiltAttr)
                mutableAttributedString.append(newLine)
            }
        }
    }

    return mutableAttributedString
    
}
