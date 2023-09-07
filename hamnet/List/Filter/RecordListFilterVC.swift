//
//  RecordListFilterVC.swift
//  hamnet
//
//  Created by hxj on 2021/1/1.
//

import Cocoa
import Carbon
import RxCocoa
import RxSwift
import SwifterSwift

class RecordListFilterVC: NSViewController, NSSearchFieldDelegate {

    @IBOutlet weak var filterOptionsBtn: NSPopUpButton!
    
    @IBOutlet weak var searchField: NSSearchField!
    
    @IBOutlet weak var cancelBtn: NSButton!
    
    public let searchTextSubject = BehaviorSubject<String?>(value: nil)
    
    var isActive = false
    
    var recordContext: RecordContext? {
        get {
            return (self.view.window?.windowController as? MainWindowController)?.recordContext
        }
    }
    
    
    let disposeBag: DisposeBag = DisposeBag()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.cancelBtn.rx.tap.subscribe(onNext: { [weak self] _ in
            (self?.parent as? RecordListController)?.hideFilterVC()
        }).disposed(by: self.disposeBag)
        // popupBtn
        configPopBtn()
        // searchField
        configSearch()
    }
    
    
    override func cancelOperation(_ sender: Any?) {
        (self.parent as? RecordListController)?.hideFilterVC()
    }
    
    
    
    func configPopBtn() {
        let items: [NSMenuItem]  = [
            NSMenuItem(title: "Include", action: nil, keyEquivalent: ""),
            NSMenuItem(title: "Exclude", action: nil, keyEquivalent: ""),
            NSMenuItem.separator(),
            NSMenuItem(title: "Regex", action: nil, keyEquivalent: "")
        ]
        self.filterOptionsBtn.menu?.items = items
        self.filterOptionsBtn.selectItem(at: 0)
       // self.filterOptionsBtn.title = items.first?.title ?? ""
    }
    
    
    func configSearch() {
        self.searchField.delegate = self
        self.searchTextSubject.throttle(.milliseconds(30), scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] value in
            if self?.isActive == false {
                return
            }
            guard let str = value else {
                self?.recordContext?.updateListFilterSubject.onNext(nil)
                return
            }
            let option: ListFilterOption.ListOptionEnum = ListFilterOption.ListOptionEnum(rawValue: self?.filterOptionsBtn.title ?? "") ?? .include
            let filterOption = ListFilterOption(urlStr: str, option: option)
            self?.recordContext?.updateListFilterSubject.onNext(filterOption)
        }).disposed(by: self.disposeBag)
        
    }
    
    func controlTextDidChange(_ obj: Notification) {
        let str = self.searchField.stringValue.trim()
        self.searchTextSubject.onNext(str)
    }
    
    
    func bindSearch() {
        self.isActive = true
        self.searchTextSubject.onNext(try? self.searchTextSubject.value())
    }
    
    func unBindSearch() {
        self.isActive = false
        self.recordContext?.updateListFilterSubject.onNext(nil)
    }

    
    
    func show() {
        self.view.window?.makeFirstResponder(self.searchField)
        self.bindSearch()
    }
    
    func hide() {
        self.resignFirstResponder()
        self.view.window?.makeFirstResponder(self.parent?.view)
        self.unBindSearch()
    }
    
}
