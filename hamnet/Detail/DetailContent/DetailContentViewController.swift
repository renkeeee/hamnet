//
//  DetailContentViewController.swift
//  hamnet
//
//  Created by deepread on 2020/12/12.
//

import Cocoa
import RxSwift
import SnapKit
import SwifterSwift


enum DetailContentType {
    case request
    case response
}

class DetailContentViewController: NSViewController {
    
    override func loadView() {
          view = NSView()
       }
    
    
    
    let selectSubject = BehaviorSubject<Record?>(value: nil)
    
    var itemsSubject = BehaviorSubject<[DetailItem]>(value: [])
    var selectIndexSubject = BehaviorSubject<Int?>(value: nil)
    
    var disposeBag = DisposeBag()
    
    lazy var topView: NSView = {
        let view = NSView(frame: .zero)
        return view
    }()
    
    lazy var titleView: NSTextField = {
        let textField = NSTextField(frame: .zero)
        textField.stringValue = "Detail"
        textField.font = .boldSystemFont(ofSize: 13)
        textField.isEditable = false
        textField.drawsBackground = false
        textField.isBezeled = false
        return textField
    }()
    
    
    lazy var optionViewModel: OptionViewModel = {
        let viewModel = OptionViewModel()
        viewModel.itemsSignal = self.itemsSubject
        viewModel.selectIndexSubject = selectIndexSubject
        viewModel.bindData()
        return viewModel
    }()
    
    lazy var optionView = {
        OptionsView(self.optionViewModel)
    }()
    
    lazy var bodyViewModel: BodyViewModel = {
        let viewModel = BodyViewModel()
        viewModel.itemsSignal = self.itemsSubject
        viewModel.selectIndexSignal  = selectIndexSubject
        viewModel.bindData()
        return viewModel
    }()
    
    lazy var bodyView = {
        BodyView(self.bodyViewModel)
    }()
    
    
    
    var type: DetailContentType?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.setupUI()
        self.bindData()
    }
    
    func setupUI() {
        self.view.addSubview(topView)
        self.view.addSubview(bodyView)
        self.topView.snp.makeConstraints { make in
            make.left.top.right.equalTo(self.view)
            make.height.equalTo(38)
        }
        self.bodyView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(self.view)
            make.top.equalTo(self.topView.snp.bottom)
        }
        
        self.topView.addSubview(titleView)
        self.titleView.snp.makeConstraints { make in
            make.left.equalTo(self.topView).offset(20)
            make.centerY.equalTo(self.topView)
            make.width.equalTo(80)
        }
        
        self.topView.addSubview(optionView)
        self.optionView.snp.makeConstraints { make in
            make.left.equalTo(self.titleView.snp.right).offset(5)
            make.right.equalTo(self.topView).offset(-20)
            make.centerY.equalTo(self.topView)
            make.height.equalTo(30)
        }
    }

    func bindData() {
        self.disposeBag = DisposeBag()
        
        if let type = self.type {
            switch type {
            case .request:
                titleView.stringValue = "Request"
            case .response:
                titleView.stringValue = "Response"
            }
        } else {
            titleView.stringValue = "Detail Info"
        }
        
        bindSelectSubject()
        bindDetailItems()
    }
    
    func bindSelectSubject() {
        let context = (self.view.window?.windowController as? MainWindowController)?.recordContext
        context?.selectSubject.observeOn(MainScheduler.asyncInstance).subscribe(onNext: {[weak self] record in
            self?.selectSubject.onNext(record)
        }).disposed(by: disposeBag)
    }
    
    func bindDetailItems() {
        self.selectSubject.subscribe(onNext: { [weak self] record in
            var items: [DetailItem] = []
            if let record = record, let self = self {
                switch self.type {
                case .request:
                    items = self.makeReqeustItems(record: record)
                case .response:
                    items = self.makeResponseItems(record: record)
                case .none: break
                }
            }
            self?.itemsSubject.onNext(items)
        }).disposed(by: self.disposeBag)
    }
    
    func makeReqeustItems(record: Record) -> [DetailItem] {
        var items: [DetailItem] = []
        //raw
        let rawItem = ReqeustRawDetailItem.makeItem(record: record)
        if let rawItem = rawItem {
            items.append(rawItem)
        }
        // header
        let headerItem = ReqeustHeaderDetailItem.makeItem(record: record)
        if let headerItem = headerItem {
            items.append(headerItem)
        }
        
        // query
        let queryItem = RequestQueryDetailItem.makeItem(record: record)
        if let queryItem = queryItem {
            items.append(queryItem)
        }
        
        // cookies
        let cookiesItem = RequestCookiesDetailItem.makeItem(record: record)
        if let cookiesItem = cookiesItem {
            items.append(cookiesItem)
        }
        
        // Code
        let codeDataItem = RequestCodeDataDetailItem.makeItem(record: record)
        if let codeDataItem = codeDataItem {
            items.append(codeDataItem)
        }
        
        // forms
        let formsItem = RequestFormDetailItem.makeItem(record: record)
        if let formsItem = formsItem {
            items.append(formsItem)
        }
        
        // Image
        let imageDataItem = ReqeustImageDetailItem.makeItem(record: record)
        if let imageDataItem = imageDataItem {
            items.append(imageDataItem)
        }
        
        // HexData
        let hexDataItem = RequestHexDataDetailItem.makeItem(record: record)
        if let hexDataItem = hexDataItem {
            items.append(hexDataItem)
        }
        
       
        
        
        return items
    }
    
    func makeResponseItems(record: Record) -> [DetailItem] {
        var items: [DetailItem] = []
        //raw
        let rawItem = ResponseRawDetailItem.makeItem(record: record)
        if let rawItem = rawItem {
            items.append(rawItem)
        }
        // header
        let headerItem = ResponseHeaderDetailItem.makeItem(record: record)
        if let headerItem = headerItem {
            items.append(headerItem)
        }
        
        
        // Code
        let codeDataItem = ResponseCodeDataDetailItem.makeItem(record: record)
        if let codeDataItem = codeDataItem {
            items.append(codeDataItem)
        }
        
        // Image
        let imageDataItem = ResponseImageDetailItem.makeItem(record: record)
        if let imageDataItem = imageDataItem {
            items.append(imageDataItem)
        }
        
        // WS
        let wsDataItem = WebSocketDetailItem.makeItem(record: record)
        if let wsDataItem = wsDataItem {
            items.append(wsDataItem)
        }
        
        // HexData
        let hexDataItem = ResponseHexDataDetailItem.makeItem(record: record)
        if let hexDataItem = hexDataItem {
            items.append(hexDataItem)
        }
        
        
        
        return items
    }
    
    
}
