//
//  BodyView.swift
//  hamnet
//
//  Created by deepread on 2020/12/13.
//

import Cocoa
import SnapKit

class BodyView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    let viewModel: BodyViewModel
    
    var viewOrControllers: [String: NSObject] = [:]
    
    init(_ viewModel: BodyViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        
        viewModel.bodyView = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func showViewOrController(_ key: String) {
        guard let _ = self.viewOrControllers[key] else {
            return
        }
        for item in self.viewOrControllers {
            let itemKey = item.key
            let itemValue = item.value
            if itemKey == key {
                setViewOrVCHidden(itemValue, false)
            } else {
                setViewOrVCHidden(itemValue, true)
            }
        }
    }
    
    func setViewOrVCHidden(_ viewOrVC: NSObject, _ isHidden: Bool) {
        if let view = viewOrVC as? NSView {
            view.isHidden = isHidden
        } else if let vc = viewOrVC as? NSViewController {
            vc.view.isHidden = isHidden
        }
    }
    
    func showEmpty() {

        if self.viewOrControllers["showEmpty"] == nil {
            let emptyView: EmptyBodyView = {
                let emptyView = EmptyBodyView(frame: .zero)
                self.addSubview(emptyView)
                emptyView.snp.makeConstraints { make in
                    make.edges.equalTo(self)
                }
                emptyView.isHidden = true
                return emptyView
            }()
            self.viewOrControllers["showEmpty"] = emptyView
        }
        
        showViewOrController("showEmpty")
    }
    
    func showTextField(_ attributeString: NSAttributedString) {

        if self.viewOrControllers["showTextField"] == nil {
            let rawView: RawBodyView = {
                let rawView = RawBodyView(frame: .zero)
                self.addSubview(rawView)
                rawView.snp.makeConstraints { make in
                    make.edges.equalTo(self)
                }
                rawView.isHidden = true
                return rawView
            }()
            self.viewOrControllers["showTextField"] = rawView
        }
        
        if let rawView = self.viewOrControllers["showTextField"] as? RawBodyView {
            rawView.updateAttributeValue(attributeString)
        }
        
        showViewOrController("showTextField")
    }
    
    func showHeaders(_ headers: [(String, String)]) {

        if self.viewOrControllers["showHeaders"] == nil {
            let headerViewVC: KeyValueBodyViewController = {
                let vc = KeyValueBodyViewController()
                let view = vc.view
                self.addSubview(view)
                view.snp.makeConstraints { make in
                    make.edges.equalTo(self)
                }
                view.isHidden = true
                return vc
            }()
            self.viewOrControllers["showHeaders"] = headerViewVC
        }
        
        if let headerViewVC = self.viewOrControllers["showHeaders"] as? KeyValueBodyViewController {
            headerViewVC.updateValues(headers)
        }
        showViewOrController("showHeaders")
    }
    
    func showQueries(_ queries: [(String, String)]) {

        if self.viewOrControllers["showQueries"] == nil {
            let queryViewVC: KeyValueBodyViewController = {
                let vc = KeyValueBodyViewController()
                let view = vc.view
                self.addSubview(view)
                view.snp.makeConstraints { make in
                    make.edges.equalTo(self)
                }
                view.isHidden = true
                return vc
            }()
            self.viewOrControllers["showQueries"] = queryViewVC
        }
        
        if let queryViewVC = self.viewOrControllers["showQueries"] as? KeyValueBodyViewController {
            queryViewVC.updateValues(queries)
        }
        showViewOrController("showQueries")
    }
    
    func showCookies(_ cookies: [(String, String)]) {

        if self.viewOrControllers["showCookies"] == nil {
            let cookiesViewVC: KeyValueBodyViewController = {
                let vc = KeyValueBodyViewController()
                let view = vc.view
                self.addSubview(view)
                view.snp.makeConstraints { make in
                    make.edges.equalTo(self)
                }
                view.isHidden = true
                return vc
            }()
            self.viewOrControllers["showCookies"] = cookiesViewVC
        }
        
        if let cookiesViewVC = self.viewOrControllers["showCookies"] as? KeyValueBodyViewController {
            cookiesViewVC.updateValues(cookies)
        }
        showViewOrController("showCookies")
    }
    
    func showForms(_ forms: [(String, String)]) {

        if self.viewOrControllers["showForms"] == nil {
            let formsViewVC: KeyValueBodyViewController = {
                let vc = KeyValueBodyViewController()
                let view = vc.view
                self.addSubview(view)
                view.snp.makeConstraints { make in
                    make.edges.equalTo(self)
                }
                view.isHidden = true
                return vc
            }()
            self.viewOrControllers["showForms"] = formsViewVC
        }
        
        if let formsViewVC = self.viewOrControllers["showForms"] as? KeyValueBodyViewController {
            formsViewVC.updateValues(forms)
        }
        showViewOrController("showForms")
    }
    
    
    func showHexData(_ data: Data, _ id: String) {

        if self.viewOrControllers["showHexData"] == nil {
            let dataVC: HexBodyViewController = {
                let vc = HexBodyViewController()
                let view = vc.view
                self.addSubview(view)
                view.snp.makeConstraints { make in
                    make.edges.equalTo(self)
                }
                view.isHidden = true
                return vc
            }()
            self.viewOrControllers["showHexData"] = dataVC
        }
        
        if let dataVC = self.viewOrControllers["showHexData"] as? HexBodyViewController {
            dataVC.updateData(data, id)
        }
        showViewOrController("showHexData")
    }
    
    func showCodeData(_ data: String, _ mimeType: String) {

        if self.viewOrControllers["showCodeData"] == nil {
            let dataVC: CodeBodyViewController = {
                let vc = CodeBodyViewController()
                let view = vc.view
                self.addSubview(view)
                view.snp.makeConstraints { make in
                    make.edges.equalTo(self)
                }
                view.isHidden = true
                return vc
            }()
            self.viewOrControllers["showCodeData"] = dataVC
        }
        
        if let dataVC = self.viewOrControllers["showCodeData"] as? CodeBodyViewController {
            dataVC.updateData(data, mimeType)
        }
        showViewOrController("showCodeData")
    }
    
    func showImageData(_ data: NSImage?) {
        // image Data
        if self.viewOrControllers["showImageData"] == nil {
            let dataVC: ImageBodyViewController = {
                let vc = ImageBodyViewController()
                let view = vc.view
                self.addSubview(view)
                view.snp.makeConstraints { make in
                    make.edges.equalTo(self)
                }
                view.isHidden = true
                return vc
            }()
            self.viewOrControllers["showImageData"] = dataVC
        }
        
        if let dataVC = self.viewOrControllers["showImageData"] as? ImageBodyViewController {
            dataVC.updateData(data)
        }
        showViewOrController("showImageData")
    }
    
    func showWebSocket(_ items: [WebSocketItem]) {
        // ws Data
        if self.viewOrControllers["showWebSockets"] == nil {
            let dataVC: WSBodyViewController = {
                let vc = WSBodyViewController()
                let view = vc.view
                self.addSubview(view)
                view.snp.makeConstraints { make in
                    make.edges.equalTo(self)
                }
                view.isHidden = true
                return vc
            }()
            self.viewOrControllers["showWebSockets"] = dataVC
        }
        
        if let dataVC = self.viewOrControllers["showWebSockets"] as? WSBodyViewController {
            dataVC.updateData(items)
        }
        showViewOrController("showWebSockets")
    }
    
}
