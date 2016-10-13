//
// Copyright (c) 2016 PHUNG ANH TUAN. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

var UITableLoadingViewKey = "UITableLoadingViewKey"

typealias Mapping = (heightBlock:((_ model: Any) -> CGFloat), configureCellBlock: (_ cell: UITableViewCell, _ model: Any) -> (), identifier: String, modelType: Any.Type)

open class ATTableViewDelegateConfiguration {
    open var scrollViewDidScroll: ((_ scrollView: UIScrollView) -> ())?
}

open class ATTableView: UITableView {
    open var defaultSection = ATTableViewSection()
    
    open var delegateConfiguration = ATTableViewDelegateConfiguration()
    
    open var onDidSelectItem: ((_ item: Any) -> ())?
    
    // Abstract the way to implement LoadMore feature.
    // Under implementation.
    open var shouldLoadMore: Bool = false
    private var isLoadingMore = false
    open var onLoadMore: (() -> ())?
    
    private var signalMonitorHandler: ((_ signal: ATSignal) -> ())?
    
    open func loadDataCompletedWithItems(items: [Any]) {
        self.shouldLoadMore = (items.count == 0) ? false : true
        self.addItems(items: items)
        
        isLoadingMore = false
    }
    
    // Keep referrence to models, encapsulated into LazyTableViewSection.
    var source = [ATTableViewSection]()
    
    // Keep all setup for each CellType registered.
    private var mappings = [Mapping]()
    
    // Find registed cell type that accept model.
    func mappingForModel(model: Any) -> Mapping? {
        for mapping in mappings {
            if mapping.modelType == type(of: model) {
                return mapping
            }
        }
        
        return nil
    }
    
    // MARK: - Loading View
    open var loadingView: UIView?
    open var centerOffset = CGPoint.zero
    
    open func showLoadingIndicator(centerOffset: CGPoint = CGPoint.zero
        ) {
        self.centerOffset = centerOffset
        
        if let loadingView = self.loadingView {
            if loadingView.superview == nil {
                self.addSubview(loadingView)
            }
            
            loadingView.isHidden = false
            self.bringSubview(toFront: loadingView)
        }
    }
    
    open func hideLoadingIndicator() {
        self.loadingView?.isHidden = true
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        self.adjustSizeOfLoadingIndicator()
    }
    
    func adjustSizeOfLoadingIndicator() {
        if let loadingView = self.loadingView {
            let bounds = self.frame
            loadingView.center = CGPoint(x: bounds.width / 2 + self.centerOffset.x, y: bounds.height / 2 + centerOffset.y)
        }
    }
    
    // Initializers
    public
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        
        self.initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initialize()
    }
    
    open func initialize() {
        self.dataSource = self
        self.delegate = self
        self.scrollsToTop = false
        
        // Auto Setup first section
        self.source.append(defaultSection)
    }
    
    open func addSection(section: ATTableViewSection, atIndex index: Int) {
        self.source.insert(section, at: index)
    }
    
    open func addSection(section: ATTableViewSection) {
        self.source.append(section)
        
        // Render data
        self.reloadData()
    }
    
    open func addItems(items: [Any], section: Int) {
        let sectionData = self.source[section]
        sectionData.addItems(newItems: items)
        
        // Render data
        self.reloadData()
    }
    
    open func addItems(items: [Any]) {
        self.addItems(items: items, section: 0)
    }
    
    // To fix issue `array cannot be bridged from Objective-C` when push array of AnyObject.
    // https://forums.developer.apple.com/thread/28678
    open func addObjects(objects: [AnyObject]) {
        self.addObjects(objects: objects, section: 0)
    }
    
    open func addObjects(objects: [AnyObject], section: Int) {
        let section = self.source[section]
        section.addItems(newItems: objects.map { $0 as AnyObject })
        
        // Render data
        self.reloadData()
    }
    
    // Register cell, setup some code blocks and store them to execute later.
    open func register<T: ATTableViewCellProtocol>(cellType: T.Type) {
        let identifier = cellType.reuseIdentifier()
        
        guard let _ = self.dequeueReusableCell(withIdentifier: identifier) else {
            // Create block code to execute class method `height:`
            // This block will be executed in `tableView:heightForRowAtIndexPath:`
            let heightBlock = { (model: Any) -> CGFloat in
                if let model = model as? T.ModelType {
                    return cellType.height(model: model)
                }
                return 0
            }
            
            // Create block code to execute method `configureCell:` of cell
            // This block will be executed in `tableView:cellForRowAtIndexPath:`
            let configureCellBlock = { (cell: UITableViewCell, model: Any) in
                if let cell = cell as? T, let model = model as? T.ModelType {
                    cell.configureCell(model: model)
                }
            }
            
            self.mappings.append(Mapping(heightBlock, configureCellBlock, identifier, T.ModelType.self))
            
            if let nibName = cellType.nibName() {
                self.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: identifier)
            }
            else {
                self.register(cellType, forCellReuseIdentifier: identifier)
            }
            return
        }
    }
    
    open func clearAll() {
        for section in self.source {
            section.clear()
        }
        
        self.reloadData()
    }
    
    open func clearItemsAtSection(section: Int) {
        self.source[section].clear()
        
        self.reloadData()
    }
    
    open override func reloadData() {
        
        super.reloadData()
    }
    
    open func startMonitorSignal(handler: @escaping (_ signal: ATSignal) -> ()) {
        self.signalMonitorHandler = handler
    }
    
    internal func fireSignal(signal: ATSignal) {
        self.signalMonitorHandler?(signal)
    }
}

extension ATTableView: UITableViewDataSource {
    // Configure sections
    open func numberOfSections(in tableView: UITableView) -> Int {
        return self.source.count
    }
    
    // Configure header for section
    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.source[section].headerTitle
    }
    
    // Configure footer for section
    open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return self.source[section].footerTitle
    }
    
    // Configure cells
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.source[section].items.count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model: Any = self.source[indexPath.section].items[indexPath.row]
        
        if let mapping = self.mappingForModel(model: model) {
            let cell = tableView.dequeueReusableCell(withIdentifier: mapping.identifier, for: indexPath)
            mapping.configureCellBlock(cell, model)
            return cell
            
        }
        return UITableViewCell()
        
    }
}

extension ATTableView: UITableViewDelegate {
    // Customize Section Header
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.source[section].customHeaderView?()
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.source[section].headerHeight
    }
    
    // Customize Section Footer
    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return self.source[section].customFooterView?()
    }
    
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return self.source[section].footerHeight
    }
    
    // Handle actions
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.onDidSelectItem?(item: self.source[indexPath.section].items[indexPath.row])
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let model: Any = self.source[indexPath.section].items[indexPath.row]
        
        if let mapping = self.mappingForModel(model: model) {
            return mapping.heightBlock(model: model)
        }
        
        return 0
    }
}
