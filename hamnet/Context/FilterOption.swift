//
//  FilterOption.swift
//  hamnet
//
//  Created by deepread on 2020/12/27.
//

import Foundation


protocol FilterOption {
    static func empty() -> Self
    func isEmpty() -> Bool
    func filter(_ record: Record) -> Bool
}


struct LeftFilterOption: FilterOption {
    let appIds: [String]
    let hosts: [String]
    let paths: [String]
    
    static func empty() -> LeftFilterOption {
        return LeftFilterOption(appIds: [], hosts: [], paths: [])
    }
    
    func isEmpty() -> Bool {
        return appIds.isEmpty && hosts.isEmpty && paths.isEmpty
    }
    
    func appId(_ appId: String) -> FilterOption {
        return LeftFilterOption(appIds: [appId], hosts: [], paths: [])
    }
    
    func host(_ host: String) -> FilterOption {
        return LeftFilterOption(appIds: [], hosts: [host], paths: [])
    }
    
    func url(_ url: String) -> FilterOption {
        return LeftFilterOption(appIds: [], hosts: [], paths: [url])
    }
    
}


extension LeftFilterOption {
    func filter(_ record: Record) -> Bool {
        // 空filter
        if self.isEmpty() {
            return true
        }
        
        if appIds.count > 0 {
            guard let recordAppId = record.processInfo?.bundleID else {
                return false
            }
            if !appIds.contains(recordAppId)  {
                return false
            }
        }
        
        if hosts.count > 0 {
            guard let recordHost = record.urlHost else {
                return false
            }
            if !hosts.contains(recordHost) {
                return false
            }
        }
        
        if paths.count > 0 {
            guard let recordPath = record.urlPath else {
                return false
            }
            if !paths.contains(recordPath) {
                return false
            }
        }
        
        return true
    }
}



struct ListFilterOption: FilterOption {
    let urlStr: String
    
    enum ListOptionEnum: String {
        case include = "Include"
        case exclude = "Exclude"
        case regex  = "Regex"
    }
    
    let option: ListOptionEnum
    
    
    func filter(_ record: Record) -> Bool {
        var url = record.urlString
        var value = self.urlStr
        var components = URLComponents(string: url)
        if let _ = components {
            components?.query = nil
            url = components?.url?.absoluteString ?? url
        }
        switch self.option {
        case .include:
            return url.contains(value.trim())
        case .exclude:
            return !url.contains(value.trim())
        case .regex:
            let RE = try? NSRegularExpression(pattern: value, options: .caseInsensitive)
            let matchs = RE?.numberOfMatches(in: url, options: .reportCompletion, range: .init(location: 0, length: url.count))
            if let matchs = matchs, matchs > 0 {
                return true
            } else {
                return false
            }
        }
    }
    
    static func empty() -> ListFilterOption {
        return ListFilterOption(urlStr: "", option: .include)
    }
    
    func isEmpty() -> Bool {
        var value = self.urlStr
        if value.trim().count == 0 {
            return true
        }
        return false
    }
    
    
}
