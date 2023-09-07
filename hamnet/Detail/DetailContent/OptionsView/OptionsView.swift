//
//  OptionsView.swift
//  hamnet
//
//  Created by deepread on 2020/12/12.
//

import Cocoa

class OptionsView: NSView {

    let viewModel: OptionViewModel

    lazy var scrollView = NSScrollView(frame: bounds)

    lazy var collectionView: NSCollectionView = {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        let collection = NSCollectionView()
        collection.collectionViewLayout = flowLayout
        collection.isSelectable = true
        collection.allowsMultipleSelection = false
        collection.register(OptionCellItem.self, forItemWithIdentifier: OptionCellItem.identifer)
        collection.delegate = self.viewModel
        collection.dataSource = self.viewModel
        collection.backgroundColor = .clear
        collection.backgroundColors = [.clear]
        return collection
    }()



    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    init(_ viewModel: OptionViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        
        viewModel.optionView = self
        self.setupUI()
        self.setupConstraint()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setupUI() {
        let clipView = NSClipView(frame: bounds)
        clipView.documentView = collectionView
        scrollView.contentView = clipView
        scrollView.drawsBackground = false
        scrollView.contentView.drawsBackground = false
        scrollView.contentView.backgroundColor = .clear
        scrollView.backgroundColor = .clear
        scrollView.scrollerInsets = .init(top: 0, left: 0, bottom: -20, right: 0)
        addSubview(scrollView)
    }
    
    func setupConstraint() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

}
