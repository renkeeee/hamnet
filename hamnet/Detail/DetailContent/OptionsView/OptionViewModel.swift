//
//  OptionViewModel.swift
//  hamnet
//
//  Created by deepread on 2020/12/12.
//

import Cocoa
import RxSwift
import SwifterSwift


class OptionViewModel: NSObject, NSCollectionViewDelegate, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    
    var itemsSignal: Observable<[DetailItem]>?
    var selectIndexSubject: BehaviorSubject<Int?>?
    weak var optionView: OptionsView?
    
    var items: [DetailItem]?
    var disposeBag = DisposeBag()

    
    func bindData() {
        self.disposeBag = DisposeBag()
        self.itemsSignal?
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] items in
                self?.items = items
                self?.optionView?.collectionView.reloadData()
                self?.updateSelect()
            })
            .disposed(by: disposeBag)
    }
    
    func updateSelect() {
        let index = (try? self.selectIndexSubject?.value()) ?? 0
        var selectIndex = index
        let itemCount = self.items?.count ?? 0
        if itemCount == 0 {
            return
        }
        if itemCount <= selectIndex {
            selectIndex = 0
        }
        let selectIndexPath = self.optionView?.collectionView.selectionIndexPaths.first
        if selectIndexPath == nil {
            self.optionView?.collectionView.selectItems(at: [IndexPath(item: selectIndex, section: 0)], scrollPosition: .leadingEdge)
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items?.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let detailItem = self.items![indexPath.item]
        let item = collectionView.makeItem(withIdentifier: OptionCellItem.identifer, for: indexPath)
        if let item = item as? OptionCellItem {
            item.updateCell(detailItem.title(), detailItem.icon())
        }
        return item
    }
    
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        let index = indexPaths.first?.item
        if let index = index, index < (self.items?.count ?? 0) {
            self.selectIndexSubject?.onNext(index)
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let index = indexPath.item
        if index < (self.items?.count ?? 0) {
            let item = self.items![index]
            let text = item.title()
            let font = NSFont.systemFont(ofSize: 13)
            let textSize = NSAttributedString(string: text, swiftyAttributes: [.font(font)]).size()
            let width = 10 + textSize.width
            return .init(width: width, height: 20)
        }
        return .zero
    }
    

}
