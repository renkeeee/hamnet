//
//  FilterViewController.swift
//  hamnet
//
//  Created by deepread on 2020/11/29.
//

import Cocoa
import RxCocoa
import RxSwift
import SwifterSwift
import DifferenceKit

class FilterViewController: NSViewController {
    
    struct FilterTableColumn {
        static let filterCell = NSUserInterfaceItemIdentifier("filterCell")
    }
    
    weak var recordContext: RecordContext?
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    var disposeBag = DisposeBag()
    
    var filterItems: [FilterItem] = []
    
    var selectItem: FilterItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        configOutlineView()
    }
    
    func configOutlineView() {
        self.outlineView.delegate = self
        self.outlineView.dataSource = self
        self.outlineView.selectionHighlightStyle = .none
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.bindData()
    }
    
    func bindData() {
        self.disposeBag = DisposeBag()
        // Attension: WindowController maybe nil while viewDidLoad/viewWillAppear
        self.recordContext = (self.view.window?.windowController as? MainWindowController)?.recordContext
        recordContext!.showFilterSubject
            //.debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] filterItems in
                guard let self = self else {
                    return
                }
                self.filterItems = filterItems
                self.outlineView.reloadData()
        }).disposed(by: self.disposeBag)
    }
}

// --
// MARK: OutlineView Delegate
// --

extension FilterViewController:NSOutlineViewDelegate {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let item = item as? FilterItem {
            let filterCell = self.outlineView.makeView(withIdentifier: FilterTableColumn.filterCell, owner: self) as? FilterCell
            filterCell?.bindItem(item, isSelect: item == self.selectItem)
            return filterCell
        }
      return nil
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let selectRow = self.outlineView.selectedRow
        let item = self.outlineView.item(atRow: selectRow)
        self.selectItem = (item as? FilterItem)
        if let item = item {
            // App Filter
            if let item = item as? AppFilterItem {
                switch item.type {
                case .head:
                    self.recordContext?.updateFilterSubject.onNext(LeftFilterOption.empty())
                case.info:
                    let filterOption = LeftFilterOption(appIds: [item.appID], hosts: [], paths: [])
                    self.recordContext?.updateFilterSubject.onNext(filterOption)
                }
                return
            }
            // Domain Filter
            if let item = item as? DomainFilterItem {
                switch item.type {
                case .head:
                    self.recordContext?.updateFilterSubject.onNext(LeftFilterOption.empty())
                case .host:
                    let filterOption = LeftFilterOption(appIds: [], hosts: [item.host], paths: [])
                    self.recordContext?.updateFilterSubject.onNext(filterOption)
                case .path:
                    let filterOption = LeftFilterOption(appIds: [], hosts: [item.host], paths: [item.path])
                    self.recordContext?.updateFilterSubject.onNext(filterOption)
                }
            }
        } else {
            self.recordContext?.updateFilterSubject.onNext(LeftFilterOption.empty())
        }
        
    }
    
}


// --
// MARK: TableView Datasource
// --
extension FilterViewController: NSOutlineViewDataSource {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? FilterItem {
            return item.child.count
        } else {
            return self.filterItems.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? FilterItem {
            return item.child[index]
        } else {
            return self.filterItems[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let item = item as? FilterItem {
            return item.child.count > 0
        } else {
            return false
        }
    }
    
    
}

