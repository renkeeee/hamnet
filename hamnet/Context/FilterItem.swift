//
//  FilterItem.swift
//  hamnet
//
//  Created by deepread on 2020/12/10.
//

import Foundation
import DifferenceKit

class FilterItem: NSObject {
    var child: [FilterItem] = []
    var text: String {
        return "FilterItem"
    }
}


class AppFilterItem: FilterItem {
    enum AppFilterType: String {
        case head = "AppFilterTypeHead"
        case info = "AppFilterTypeInfo"
    }
    
    init(type: AppFilterType, appName: String, appID: String) {
        self.type = type
        self.appName = appName
        self.appID = appID
    }
    
    var type: AppFilterType
    var appName: String
    var appID: String
    
    
    override var text: String {
        if type == .head {
            return "Apps"
        } else {
            return appName
        }
    }
    
}


class DomainFilterItem: FilterItem {
    enum DomainFilterType: String {
        case head = "DomainFilterTypeHead"
        case host = "DomainFilterTypeHost"
        case path = "DomainFilterTypePath"
    }
    
    init(type: DomainFilterType, host: String, path: String) {
        self.type = type
        self.host = host
        self.path = path
    }
    var type: DomainFilterType
    var host: String
    var path: String
    
    override var text: String {
        if type == .head {
            return "Domains"
        } else if type == .host {
            return host
        } else {
            return path
        }
    }
    
}
