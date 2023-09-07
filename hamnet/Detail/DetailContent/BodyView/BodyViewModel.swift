//
//  BodyViewModel.swift
//  hamnet
//
//  Created by deepread on 2020/12/13.
//

import Cocoa
import RxSwift
import SwifterSwift

class BodyViewModel: NSObject {
    
    var itemsSignal: Observable<[DetailItem]>?
    var selectIndexSignal: Observable<Int?>?
    weak var bodyView: BodyView?
    
    var disposeBag = DisposeBag()
    
    func bindData() {
        self.disposeBag = DisposeBag()
        if let itemsSignal = itemsSignal, let selectIndexSignal = selectIndexSignal {
            Observable.combineLatest(itemsSignal, selectIndexSignal)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (items, index) in
                    var index = index ?? 0
                    if index >= items.count {
                        index = 0
                    }
                    self?.adjustBodyView(items: items, index: index)
                }).disposed(by: disposeBag)
        }
        
    }
    
    func adjustBodyView(items: [DetailItem], index: Int) {
        if items.count == 0 {
            self.bodyView?.showEmpty()
            return
        }
        
        let item = items[index]
        
        // Raw
        if let item = item as? RawDetailItem {
            if let attributeString = item.attributeString {
                self.bodyView?.showTextField(attributeString)
            } else {
                self.bodyView?.showEmpty()
            }
            return
        }
        
        // Header
        if let item = item as? HeaderDetailItem {
            if let headers = item.headers {
                self.bodyView?.showHeaders(headers)
            } else {
                self.bodyView?.showEmpty()
            }
            return
        }
        
        // Query
        if let item = item as? RequestQueryDetailItem {
            if let queries = item.queries {
                self.bodyView?.showQueries(queries)
            } else {
                self.bodyView?.showEmpty()
            }
        }
        
        // Cookies
        if let item = item as? RequestCookiesDetailItem {
            if let cookies = item.cookies {
                self.bodyView?.showCookies(cookies)
            } else {
                self.bodyView?.showEmpty()
            }
        }
        
        // Forms
        if let item = item as? RequestFormDetailItem {
            if let forms = item.forms {
                self.bodyView?.showForms(forms)
            } else {
                self.bodyView?.showEmpty()
            }
        }
        
        // Hex
        if let item = item as? HexDataDetailItem {
            if let data = item.data, let id = item.id {
                self.bodyView?.showHexData(data, id)
            } else {
                self.bodyView?.showEmpty()
            }
        }
        
        // Code
        if let item = item as? CodeDataDetailItem {
            if let data = item.data, let type = item.mimeType {
                self.bodyView?.showCodeData(data, type)
            } else {
                self.bodyView?.showEmpty()
            }
        }
        
        // Image
        if let item = item as? ImageDetailItem {
            if let data = item.image {
                self.bodyView?.showImageData(data)
            } else {
                self.bodyView?.showEmpty()
            }
        }
        
        // WS
        if let item = item as? WebSocketDetailItem {
            self.bodyView?.showWebSocket(item.webSocketItems)
        }
    }
    

}
