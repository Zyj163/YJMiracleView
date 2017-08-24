//
//  YJMiracleView.swift
//  YJMiracleView
//
//  Created by ddn on 2017/8/23.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

public enum YJMiracleViewAnimateType {
	case none
	case lineH_priority
	case lineV_priority
}

public protocol YJMiracleViewDataSource: class {
	
	func numberOfLanes(in miracleView: YJMiracleView) -> Int
	
	func spaceOfItems(in miracleView: YJMiracleView) -> Float
	
	func miracleView(_ miracleView :YJMiracleView, numbersInLane: Int) -> Int
	
	func item(in miracleView: YJMiracleView, at position: YJMiracleItemPosition) -> YJMiracleItem
	func miracleView(_ miracleView: YJMiracleView, sizeForItemAt position: YJMiracleItemPosition) -> CGSize
}

extension YJMiracleViewDataSource {
	
	public func numberOfLanes(in miracleView: YJMiracleView) -> Int {
		return 1
	}
	
	public func spaceOfItems(in miracleView: YJMiracleView) -> Float {
		return 10
	}
}

@objc public protocol YJMiracleViewDelegate: NSObjectProtocol {
	
	@objc optional func mircaleViewDidOpened(_ mircaleView: YJMiracleView)
	@objc optional func mircaleViewDidClosed(_ mircaleView: YJMiracleView)
	
}

public class YJMiracleView: YJMiracleItem {
	
	public weak var dataSource: YJMiracleViewDataSource?
	public weak var delegate: YJMiracleViewDelegate?
	
	fileprivate lazy var items: [YJMiracleItem] = [YJMiracleItem]()
	
	fileprivate var opened: Bool = false
	fileprivate var animating: Bool = false
	
	public var isOpened: Bool {
		return opened
	}
	
	public var animateType: YJMiracleViewAnimateType = .lineH_priority
	
	fileprivate var autoTranslucentable: Bool = true
	fileprivate var attachable: Bool = true
	
	fileprivate var isRootItem: Bool = true
	
	override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesBegan(touches, with: event)
		if autoTranslucentable { inactiveAutoTranslucent() }
	}
	
	override func tapOn(_ sender: UITapGestureRecognizer) {
		super.tapOn(sender)
		if autoTranslucentable { inactiveAutoTranslucent() }
	}
	
	convenience public init(_ frame: CGRect, autoTranslucentable: Bool = true, attachable: Bool = true) {
		self.init(frame)
		self.autoTranslucentable = autoTranslucentable
		self.attachable = attachable
	}
}


extension YJMiracleView {
	public func open() {
		
		if opened || animating { return }
		
		prepareToOpen()
		
		loadAnimations()
		
		fire()
	}
	
	public func close() {
		if !opened || animating { return }
		items.forEach { (item: YJMiracleItem) in
			autoreleasepool(invoking: { () -> Void in
				if let itemView = item as? YJMiracleView {
					itemView.close()
				}
			})
		}
		fire()
	}
	
	public func item(at position: YJMiracleItemPosition, upper: Bool = false) -> YJMiracleItem? {
		
		//根item
		guard let parent = position.parent else {
			if position == self.position {
				return self
			} else {
				return nil
			}
		}
		
		//当前子item
		if parent == self.position {
			for item in items {
				if item.position == position { return item }
			}
			return nil
		}
		
		//向下遍历
		if !upper {
			let childs = items.filter { $0 is YJMiracleView }
			if childs.isEmpty { return nil }
			for child in childs as! [YJMiracleView] {
				if let item = autoreleasepool(invoking: { () -> YJMiracleItem? in
					return child.item(at: position)
				}) {
					return item
				}
			}
		}
		
		//向上遍历
		if let item = miracleView?.item(at: position, upper: true) {
			return item
		}
		return nil
	}
	
	fileprivate func reload() {
		items.forEach { (item: YJMiracleItem) in
			autoreleasepool(invoking: { () -> Void in
				if let itemView = item as? YJMiracleView {
					itemView.reload()
				}
				item.removeFromSuperview()
			})
		}
		items.removeAll()
	}
}


// MARK: - animate
extension YJMiracleView {
	
	/// 打开前的准备工作，调用数据源，添加子item
	fileprivate func prepareToOpen() {
		if !items.isEmpty { return }
		guard let dataSource = dataSource else { return }
		
		let tmpNum = dataSource.miracleView(self, numbersInLane: position.index)
		if tmpNum == 0 { return }
		
		if superview == nil {
			guard let keyWindow = UIApplication.shared.keyWindow else { return }
			keyWindow.addSubview(self)
			self.bounds = CGRect(origin: CGPoint.zero, size: dataSource.miracleView(self, sizeForItemAt: YJMiracleItemPosition(lane: position.index, index: 0, parent: position)))
		}
		
		for i in 1...tmpNum {
			let pp = YJMiracleItemPosition(lane: position.index, index: i, parent: position)
			let item = dataSource.item(in: self, at: pp)
			item.bounds = CGRect(origin: CGPoint.zero, size: dataSource.miracleView(self, sizeForItemAt: pp))
			item.layer.opacity = 0
			item.layer.position = layer.position
			item.position = pp
			item.closedLocation = layer.position
			item.miracleView = self
			if let item = item as? YJMiracleView {
				item.animateType = animateType == .lineH_priority ? .lineV_priority : .lineH_priority
				item.isRootItem = false
				item.autoTranslucentable = false
				item.attachable = false
			}
			superview!.insertSubview(item, belowSubview: self)
			
			items.append(item)
		}
	}
	
	/// 装载动画（打开／关闭）
	fileprivate func loadAnimations() {
		switch animateType {
		case .none:
			return
		case .lineH_priority:
			lineH_priorityAnimate()
		case .lineV_priority:
			lineV_priorityAnimate()
		}
	}
	
	/// 执行动画（打开／关闭）
	fileprivate func fire() {
		let group = DispatchGroup()
		animating = true
		items.forEach {
			group.enter()
			$0.animate?{ group.leave() }
		}
		group.notify(queue: DispatchQueue.main, execute: {[weak self] in
			if let `self` = self {
				`self`.opened = !`self`.opened
				`self`.animating = false
				if !`self`.opened {
					`self`.didClosed()
				} else {
					`self`.didOpened()
				}
			}
		})
	}
	
	/// 打开后的设置
	private func didOpened() {
		if isRootItem && attachable {inactiveAttachable()}
		
		delegate?.mircaleViewDidOpened?(self)
	}
	
	/// 关闭后的设置
	private func didClosed() {
		reload()
		activeAutoTranslucent()
		if isRootItem && attachable {activeAttachable()}
		
		delegate?.mircaleViewDidClosed?(self)
	}
}

// MARK: - 具体动画设计
extension YJMiracleView {
	fileprivate func lineH_priorityAnimate(_ force: Bool = false) {
		
		//先判断往左还是往右（规则：哪边离得远去哪边）
		let l = frame.minX
		let r = superview!.frame.maxX - frame.maxX
		var layoutFrame: CGRect
		
		//优先原则：这条线没有其它item，不与其它item碰撞
		if (r > l && !force) || (r <= l && force) {
			var totalW: CGFloat = frame.maxX
			for item in items {
				let x = totalW + CGFloat(dataSource!.spaceOfItems(in: self)) + item.bounds.width / 2
				item.openedLocation = CGPoint(x: x, y: item.layer.position.y)
				totalW = x + item.bounds.width / 2
			}
			layoutFrame = CGRect(x: frame.maxX, y: frame.minY, width: totalW - frame.maxX, height: bounds.height)
			
		} else {
			var totalW: CGFloat = frame.minX
			for item in items {
				let x = totalW - CGFloat(dataSource!.spaceOfItems(in: self)) - item.bounds.width / 2
				item.openedLocation = CGPoint(x: x, y: item.layer.position.y)
				totalW = x - item.bounds.width / 2
			}
			layoutFrame = CGRect(x: totalW, y: frame.minY, width: frame.minX - totalW, height: bounds.height)
		}
		
		let has = superview!.subviews.filter({ (view: UIView) -> Bool in
			return view != self && view.frame.intersects(layoutFrame)
		}).count > 0
		
		if has && !force { return lineH_priorityAnimate(true) }
		else if has { return }
		
		line_priorityAnimate()
	}
	
	fileprivate func lineV_priorityAnimate(_ force: Bool = false) {
		
		//先判断往上还是往下（规则：哪边离得远去哪边）
		let t = frame.minY
		let b = superview!.frame.maxY - frame.maxY
		
		var layoutFrame: CGRect
		
		if (t > b && !force) || (t <= b && force) {
			var totalH: CGFloat = frame.minY
			for item in items {
				let y = totalH - CGFloat(dataSource!.spaceOfItems(in: self)) - item.bounds.height / 2
				item.openedLocation = CGPoint(x: item.layer.position.x, y: y)
				totalH = y - item.bounds.height / 2
			}
			layoutFrame = CGRect(x: frame.minX, y: totalH, width: bounds.width, height: frame.minY - totalH)
			
		} else {
			var totalH: CGFloat = frame.maxY
			for item in items {
				let y = totalH + CGFloat(dataSource!.spaceOfItems(in: self)) + item.bounds.height / 2
				item.openedLocation = CGPoint(x: item.layer.position.x, y: y)
				totalH = y + item.bounds.height / 2
			}
			layoutFrame = CGRect(x: frame.minX, y: frame.maxY, width: bounds.width, height: totalH - frame.maxY)
		}
		
		let has = superview!.subviews.filter({ (view: UIView) -> Bool in
			return view != self && view.frame.intersects(layoutFrame)
		}).count > 0
		
		if has && !force { return lineV_priorityAnimate(true) }
		else if has { return }
		
		line_priorityAnimate()
	}
	
	fileprivate func line_priorityAnimate() {
		items.forEach { (item: YJMiracleItem) in
			item.animate = { [weak item, weak self] (completion) in
				if let item = item, let `self` = self {
					UIView.animate(withDuration: 0.25, delay: 0.2, options: [.curveEaseOut], animations: {
						item.layer.position = `self`.opened ? item.closedLocation : item.openedLocation
						item.layer.opacity = `self`.opened ? 0 : 1
					}, completion: { (finish) in
						completion?()
					})
				}
			}
		}
	}
}


// MARK: - YJAttachable
extension YJMiracleView: YJAttachable {
	public func shouldStateChanged(_ state: UIGestureRecognizerState) -> Bool {
		switch state {
		case .began:
			inactiveAutoTranslucent()
		case .ended, .cancelled:
			activeAutoTranslucent()
		default:
			break
		}
		return true
	}
}

// MARK: - 自动半透明
extension YJMiracleView {
	public func activeAutoTranslucent() {
		if !autoTranslucentable {return}
		perform(#selector(makeTranslucent), with: nil, afterDelay: 5, inModes: [.commonModes])
	}
	
	public func inactiveAutoTranslucent() {
		if !autoTranslucentable {return}
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(makeTranslucent), object: nil)
		cancelTranslucent()
	}
	
	@objc fileprivate func makeTranslucent() {
		UIView.animate(withDuration: 0.2) { 
			self.layer.opacity = 0.5
		}
	}
	
	@objc fileprivate func cancelTranslucent() {
		UIView.animate(withDuration: 0.2) {
			self.layer.opacity = 1
		}
	}
}






















