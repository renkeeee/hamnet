//
//  RecordListController.swift
//  hamnet
//
//  Created by deepread on 2020/11/28.
//

import Cocoa
import RxSwift
import RxCocoa
import NIOHTTP1
import DifferenceKit
import SnapKit
import Carbon

protocol RecordListCellProtocol {
    func bindData(_ record: Record) -> Void
}



class RecordListController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    var service: MITMService?
    weak var recordContext: RecordContext?
    
    var records: [Record] = []
    
    var disposeBag = DisposeBag()
    
    let filterVC = RecordListFilterVC()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = CertService.shared.trustCACert()
        
        HMAction.shared.toggleProxyPort.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            if let service = self?.service {
                service.stop()
            }
            let config = MITMServiceConfig(port: (try? HMAction.shared.toggleProxyPort.value()) ?? 8787, host: "0.0.0.0")
            self?.service = MITMService(configuration: config)
            self?.service?.start()
        }).disposed(by: self.disposeBag)
        
        
        configTableView()
        configFilterVC()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.bindData()
    }
    
    func configTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.scrollView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }
    
    func configFilterVC() {
        self.addChild(self.filterVC)
        self.view.addSubview(self.filterVC.view)
        self.filterVC.view.snp.makeConstraints { make in
            make.left.right.top.equalTo(self.view)
            make.height.equalTo(22)
        }
        self.filterVC.view.isHidden  = true
    }

    
    override func keyDown(with event: NSEvent) {
        if event.characters == "f" && event.modifierFlags.contains(.command) {
            // Command + F
            showFilterVC()
        } else if event.keyCode == kVK_Escape {
            hideFilterVC()
        } else {
            super.keyDown(with: event)
        }
    }
    
    
    func showFilterVC() {
        self.filterVC.view.isHidden = false
        self.filterVC.view.snp.remakeConstraints { make in
            make.left.right.top.equalTo(self.view)
            make.height.equalTo(30)
        }
        self.scrollView.snp.remakeConstraints { make in
            make.top.equalTo(self.view).offset(30)
            make.left.right.bottom.equalTo(self.view)
        }
        self.filterVC.show()
    }
    
    func hideFilterVC() {
        self.filterVC.view.isHidden = true
        self.scrollView.snp.remakeConstraints { make in
            make.edges.equalTo(self.view)
        }
        self.filterVC.hide()
    }
    
    
    
    struct RecordListTableColumn {
        static let index = NSUserInterfaceItemIdentifier("RecordListTableViewIndex")
        static let method = NSUserInterfaceItemIdentifier("RecordListTableViewMethod")
        static let url = NSUserInterfaceItemIdentifier("RecordListTableViewURL")
        static let createTime = NSUserInterfaceItemIdentifier("RecordListTableViewCreateTime")
        static let status = NSUserInterfaceItemIdentifier("RecordListTableViewStatus")
        static let ssl = NSUserInterfaceItemIdentifier("RecordListTableViewSSL")
        static let code = NSUserInterfaceItemIdentifier("RecordListTableViewCode")
    }
    
    
    
    
    func bindData() {
        self.disposeBag = DisposeBag()
        // Attension: WindowController maybe nil while viewDidLoad/viewWillAppear
        self.recordContext = (self.view.window?.windowController as? MainWindowController)?.recordContext
        recordContext!.showRecordsSubject.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] records in
            guard let self = self else {
                return
            }
            self.refreshData(self.sortRecords(records))
        }).disposed(by: self.disposeBag)
    }
    
    func sortRecords(_ records: [Record]) -> [Record] {
        guard let _ = tableView.sortDescriptors.first else {
            return records
        }
        let res = (records as NSArray).sortedArray(using: tableView.sortDescriptors) as? [Record]
        if let res = res {
            return res
        } else {
            return records
        }
    }
    
    
    func refreshData(_ records: [Record]) {
        let changeset = StagedChangeset(source: self.records, target: records)
        let selectedRowIndexes = self.tableView.selectedRowIndexes
        self.tableView.reloadList(using: changeset, with: NSTableView.AnimationOptions.effectFade) { newRecords in
            self.records = newRecords
            self.tableView.selectRowIndexes(selectedRowIndexes, byExtendingSelection: false)
            
            // update select
            let selectRecord = try? self.recordContext?.selectSubject.value()
            if let _ = selectRecord {
                let id = selectRecord!.id
                self.records.forEach { record in
                    if (record.id == id) {
                        if record.isContentEqual(to: selectRecord!) == false {
                            self.recordContext?.selectSubject.onNext(record)
                        }
                    }
                }
            }
            // update start end
        }
    }
}

// --
// MARK: TableView Delegate
// --

extension RecordListController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        let records = self.records
        let selectRows = tableView.selectedRow
        if selectRows >= 0 && selectRows < records.count {
            let record = records[selectRows]
            self.recordContext!.selectSubject.onNext(record)
        } else {
            self.recordContext!.selectSubject.onNext(nil)
        }
    }
}


// --
// MARK: TableView Datasource
// --
extension RecordListController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.records.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item: Record = self.records[row]
        if let cell = tableView.makeView(withIdentifier: tableColumn?.identifier ?? NSUserInterfaceItemIdentifier(rawValue: ""), owner: self.tableView) as? RecordListCellProtocol {
            cell.bindData(item)
            return cell as? NSView
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        self.records = sortRecords(records)
        self.tableView.reloadData()
    }
    
}



