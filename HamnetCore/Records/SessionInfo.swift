//
//  Session.swift
//  hamnet
//
//  Created by deepread on 2020/11/24.
//

import Cocoa
import NIOHTTP1

class SessionInfo {
    
    /*
     * PRIVATE
     */
    private var records: [RecordInfo] = []
    private var recordQueue: DispatchQueue?
    
    private var stopRecord = false
    
    private func insertRecord(_ record: RecordInfo) -> Void {
        if self.recordQueue == nil {
            objc_sync_enter(self)
            if self.recordQueue == nil {
                self.recordQueue = DispatchQueue.init(label: "SessionInfo recordQueue")
            }
            objc_sync_exit(self)
        }
        self.recordQueue?.async {
            record.index = self.records.count + 1
            self.records.append(record)
        }
    }
    
    func innerNeedMitM(_ record: RecordInfo) -> Bool {
        if let ignore = self.ignoreRecord {
            if ignore(record) {
                return false
            }
        }
        if let needMitM = self.needMitM {
            return needMitM(record)
        }
        return false
    }
    
    func innerIgnoreRecord(_ record: RecordInfo) -> Bool {
        if self.stopRecord {
            return true
        }
        if let ignore = self.ignoreRecord {
            return ignore(record)
        } else {
            return false
        }
    }
    
    
    /*
     * PUBLIC
     */
    public init() {
        createTime = Date()
    }
    
    public static let active = SessionInfo()

    public var createTime: Date
    public var sessionName: String?

    public func isActive() -> Bool {
        return Self.active === self
    }
    
    public func makeRecord(_ requestHead: HTTPRequestHead?) -> RecordInfo {
        let record = RecordInfo(session: self)
        record.requestHead.onNext(requestHead)
        if self.innerIgnoreRecord(record) {
            return record
        }
        self.insertRecord(record)
        if let add = self.addRecord {
            add(record)
        }
        record.bindUpdate()
        return record
    }
    
    
    
    public func readRecords() -> [RecordInfo] {
        return self.records
    }
    
    public func clearRecords() {
        self.recordQueue?.async {
            self.records = []
        }
    }
    
    public func stopRecord(_ stop: Bool) {
        self.stopRecord = stop
    }
    
    public var addRecord: ((_ record: RecordInfo) -> Void)?
    public var updateRecord: ((_ record: RecordInfo) -> Void)?
    
    public var needMitM: ((_ record: RecordInfo) -> Bool)?
    public var ignoreRecord: ((_ record: RecordInfo) -> Bool)?
    
}
