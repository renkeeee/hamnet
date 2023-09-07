//
//  HexBodyViewController.swift
//  hamnet
//
//  Created by deepread on 2020/12/14.
//

import Cocoa
import SnapKit

class HexBodyViewController: NSViewController, HFTextViewDelegate {
    
    var hexView: HFTextView? = nil
    var nowId: String? = nil
    
    var ranges: [String: [HFRange]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hexView = HFTextView(frame: self.view.bounds)
        self.hexView!.delegate = self
        self.view.addSubview(hexView!)
        self.hexView!.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
    }
    
    func updateData(_ data:  Data, _ id: String) {
//        if let nowId = nowId, let length = self.hexView?.byteArray.length() {
//            let indexSet = self.hexView?.controller.bookmarks(in: .init(location: 0, length:length))
//            if let indexSet = indexSet {
//                var rangeSet: [HFRange] = []
//                for index in indexSet {
//                    let range = self.hexView?.controller.range(forBookmark: index)
//                    if let range = range {
//                        rangeSet.append(range)
//                        self.hexView?.controller.setRange(.init(location: UInt64.max, length: UInt64.max), forBookmark: index)
//                    }
//                }
//                if !rangeSet.isEmpty {
//                    ranges[nowId] = rangeSet
//                }
//            }
//        }
        self.hexView!.data = data
//        self.nowId = id
//        if let rangeSet = ranges[id], rangeSet.count > 0 {
//            for (index, range) in rangeSet.enumerated() {
//                self.hexView?.controller.setRange(range, forBookmark: index)
//            }
//        }
    }
    
    func hexTextView(_ view: HFTextView, didChangeProperties properties: HFControllerPropertyBits) {
        // do nothing
    }
    
}
