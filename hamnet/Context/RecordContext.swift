//
//  RecordContext.swift
//  hamnet
//
//  Created by deepread on 2020/11/29.
//
import Cocoa
import RxSwift
import RxCocoa
import NIOHTTP1
import DifferenceKit
import SwifterSwift




class RecordContext {
    
    private var session: SessionInfo?
    
    private let disposeBag = DisposeBag()
    

    private let updateRecordSubject = BehaviorSubject<RecordInfo?>(value: nil)

    public let recordsSubject = BehaviorSubject<[Record]>(value: [])

    public let filterSubject = BehaviorSubject<[FilterItem]>(value: [])
    

    public let showRecordsSubject = BehaviorSubject<[Record]>(value: [])

    public let selectSubject = BehaviorSubject<Record?>(value: nil)

    public let showFilterSubject = BehaviorSubject<[FilterItem]>(value: [])

    public let updateFilterSubject = BehaviorSubject<FilterOption?>(value: nil)
    
    public let updateListFilterSubject = BehaviorSubject<FilterOption?>(value: nil)
    
    
    
    
    private let recordSerialScheduler = SerialDispatchQueueScheduler.init(internalSerialQueueName: UUID().uuidString)
    private let filterSerialScheduler = SerialDispatchQueueScheduler.init(internalSerialQueueName: UUID().uuidString)
    
    private var updateQueue = DispatchQueue.init(label: UUID().uuidString)
    
    private var filterAppHead = AppFilterItem(type: .head, appName: "", appID:"")
    private var filterDomainHead = DomainFilterItem(type: .head, host: "", path: "")
    
    private var filterAppInfos: [AppFilterItem] = []
    private var filterDomainInfos: [DomainFilterItem] = []
    
    
    public init() {
    }
       
    public func bindSession(_ session: SessionInfo) {
        self.session = session
        self.session?.addRecord = { [weak self] recordInfo in
            guard let self = self else {
                return
            }
            self.updateQueue.async {
                self.updateRecordSubject.onNext((recordInfo))
            }
        }
        self.session?.updateRecord = { [weak self] recordInfo in
            guard let self = self else {
                return
            }
            self.updateQueue.async {
                self.updateRecordSubject.onNext(recordInfo)
            }
        }
        
        self.session?.ignoreRecord = { recordInfo in
            let record = Record(recordInfo)
            let url = record.urlString
            let ignoreURLList = [
                "api.apple-cloudkit.com",
                "icloud.com"
            ]
            var hitList = false
            for item in ignoreURLList {
                if url.contains(item) {
                    hitList = true
                    break
                }
            }
            return hitList
        }
        
        self.session?.needMitM = { recordInfo in
            return true
        }
        
        self.bindRecords()
        self.bindFilter()
        self.bindClear()
        self.bindStop()
    }
    
    func bindClear() {
        HMAction.shared.toggleEmptyRecords.subscribe(onNext: { [weak self] _ in
            self?.session?.clearRecords()
            self?.filterAppInfos = []
            self?.filterDomainInfos = []
            self?.recordsSubject.onNext([])
        }).disposed(by: self.disposeBag)
    }
    
    func bindStop() {
        HMAction.shared.toggleStartRecord.subscribe(onNext: { [weak self] start in
            self?.session?.stopRecord(!start)
        }).disposed(by: self.disposeBag)
    }
}

extension RecordContext {
    func bindRecords() {
        self.updateRecordSubject
        .debounce(.milliseconds(30), scheduler: recordSerialScheduler)
        .observeOn(recordSerialScheduler)
        .subscribeOn(recordSerialScheduler)
        .map { [weak self] (_) -> [Record] in
            let recordInfos = self?.session?.readRecords()
            if let infos = recordInfos {
                return infos.map { recordInfo -> Record in
                    Record(recordInfo)
                }
            } else {
                return []
            }
        }
        .subscribe(onNext: {[weak self] records in
            self?.recordsSubject.onNext(records)
        }).disposed(by: self.disposeBag)
        
        Observable.combineLatest(
            self.recordsSubject,
            self.updateFilterSubject,
            self.updateListFilterSubject
        )
        .observeOn(recordSerialScheduler)
        .subscribeOn(recordSerialScheduler)
        .map {(records, filterOption, listFilterOption) -> [Record] in
            let records = records
            
            if filterOption == nil && listFilterOption == nil {
                return records
            }
            
            let result = records.filter { record -> Bool in
                if let filterOption = filterOption, !filterOption.isEmpty(), filterOption.filter(record) == false {
                    return false
                }
                if let listFilterOption = listFilterOption, !listFilterOption.isEmpty(), listFilterOption.filter(record) == false {
                    return false
                }
                return true
            }

            return result
        }
        .subscribe(onNext: {[weak self] records in
            self?.showRecordsSubject.onNext(records)
        }).disposed(by: self.disposeBag)
    }
}

// Filter Node
extension RecordContext {
    func bindFilter() {
        self.updateRecordSubject
        .observeOn(filterSerialScheduler)
        .subscribeOn(filterSerialScheduler)
        .subscribe(onNext: { [weak self] recordInfo in
            if let self = self, let recordInfo = recordInfo  {
                self.makeAppFilters(recordInfo)
                self.makeDomainFilters(recordInfo)
            }
            self?.filterSubject.onNext([])
        }).disposed(by: self.disposeBag)
        
        
        Observable.combineLatest(
            self.filterSubject,
            self.updateFilterSubject
        )
        .observeOn(filterSerialScheduler)
        .subscribeOn(filterSerialScheduler)
        .map {(_, filterOption) -> [FilterItem] in
            self.filterAppHead.child = self.filterAppInfos.sorted(by: \.appName)
            self.filterDomainHead.child = self.filterDomainInfos.sorted(by: \.host)
            return [self.filterAppHead, self.filterDomainHead]
        }
        .subscribe(onNext: {[weak self] filters in
            self?.showFilterSubject.onNext(filters)
        }).disposed(by: self.disposeBag)
        
        
    }
    
    func makeAppFilters(_ recordInfo: RecordInfo) {
        guard let appId = recordInfo.process?.bundleID else {
            return
        }
        guard let appName = recordInfo.process?.appName else {
            return
        }
        let ids: [String] = self.filterAppInfos.map { item -> String in
            item.appID
        }
        guard !ids.contains(appId) else {
            return
        }
        let filterAppInfo = AppFilterItem(type: .info, appName: appName, appID: appId)
        self.filterAppInfos.append(filterAppInfo)
    }
    
    
    func makeDomainFilters(_ recordInfo: RecordInfo) {
        let record = Record(recordInfo)
        guard let host = record.urlHost else {
            return
        }
        let path = record.urlPath
        let hostItemIndex = self.filterDomainInfos.firstIndex { $0.host == host }
        var hostItem: DomainFilterItem? = nil
        
        if hostItemIndex == nil {
            hostItem = DomainFilterItem(type: .host, host: host, path: "")
            self.filterDomainInfos.append(hostItem!)
        } else {
            hostItem = self.filterDomainInfos[hostItemIndex!]
        }
        
        
        var pathItem: DomainFilterItem? = nil
        let pathItemIndex = hostItem?.child.firstIndex { item -> Bool in
            if let item = item as? DomainFilterItem {
                return item.path == path
            } else {
                return false
            }
        }
        
        if pathItemIndex == nil {
            if path != nil {
                pathItem = DomainFilterItem(type: .path, host: host, path: path!)
                hostItem!.child.append(pathItem!)
            }
        } else {
            pathItem = hostItem?.child[pathItemIndex!] as? DomainFilterItem
        }
        let childs = hostItem?.child as! [DomainFilterItem]
        hostItem?.child = childs.sorted(by: \.path)
    }
    
}
