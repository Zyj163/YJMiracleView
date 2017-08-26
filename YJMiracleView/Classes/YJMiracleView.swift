//
//  YJMiracleView.swift
//  YJMiracleView
//
//  Created by ddn on 2017/8/23.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

public protocol YJMiracleViewDataSource: class {
	
	func miracleView(_ miracleView :YJMiracleView, numbersInLane: Int) -> Int
	
	func item(in miracleView: YJMiracleView, at position: YJMiracleItemPosition) -> YJMiracleView
	func miracleView(_ miracleView: YJMiracleView, sizeForItemAt position: YJMiracleItemPosition) -> CGSize
}

@objc public protocol YJMiracleViewDelegate: NSObjectProtocol {
	
	@objc optional func mircaleViewDidOpened(_ mircaleView: YJMiracleView)
	@objc optional func mircaleViewDidClosed(_ mircaleView: YJMiracleView)
	
}

open class YJMiracleView: UIView {
	
	public weak var dataSource: YJMiracleViewDataSource?
	public weak var delegate: YJMiracleViewDelegate?
	
	public lazy var textLabel: UILabel = {
		let label = UILabel()
		label.font = UIFont.systemFont(ofSize: 13)
		label.textAlignment = .center
		self.addSubview(label)
		self._textLabel = label
		return label
	}()
	
	fileprivate var _textLabel: UILabel?
	
	public lazy var backgroundImageView: UIImageView = {
		let imageView = UIImageView()
		self.insertSubview(imageView, at: 0)
		return imageView
	}()
	
	fileprivate var _backgroundImageView: UIImageView?
	
	fileprivate lazy var _items: [YJMiracleView] = [YJMiracleView]()
	public var items: [YJMiracleView] {
		return _items
	}
	
	fileprivate var opened: Bool = false
	fileprivate var animating: Bool = false
	
	public var isOpened: Bool {
		return opened
	}
	public var isAnimating: Bool {
		return animating
	}
	
	fileprivate var autoTranslucentable: Bool = true
	fileprivate var attachable: Bool = true
	
	fileprivate var isRootItem: Bool = true
	
	public lazy var animateDriver: YJMiracleAnimateDriver = YJMiracleAnimateDriver(self)
	
	public var clickOn: (()->())?
	
	public var hasClickOnAnimate: Bool = true
	
	public var position: YJMiracleItemPosition = YJMiracleItemPosition()
	
	public weak var miracleView: YJMiracleView?
	
	convenience public init(_ frame: CGRect, autoTranslucentable: Bool = true, attachable: Bool = true) {
		self.init(frame)
		self.autoTranslucentable = autoTranslucentable
		self.attachable = attachable
	}
	
	override private init(frame: CGRect) {
		super.init(frame: frame)
		let tap = UITapGestureRecognizer(target: self, action: #selector(tapOn(_:)))
		tap.delaysTouchesBegan = true
		addGestureRecognizer(tap)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesBegan(touches, with: event)
		if autoTranslucentable { inactiveAutoTranslucent() }
	}
	
	func tapOn(_ sender: UITapGestureRecognizer) {
		if hasClickOnAnimate { animateDriver.clickOnAnimation() }
		clickOn?()
		if autoTranslucentable { inactiveAutoTranslucent() }
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		if let label = _textLabel {
			label.frame = bounds
		}
		if let imageView = _backgroundImageView {
			imageView.frame = bounds
		}
	}
}


extension YJMiracleView {
	public func open() {
		
		if opened || animating { return }
		
		prepareToOpen()
		
		animateDriver.loadAnimations()
		
		fire()
	}
	
	public func close() {
		if !opened || animating { return }
		items.forEach { (item: YJMiracleView) in
			autoreleasepool(invoking: { () -> Void in
				item.close()
			})
		}
		fire()
	}
	
	public func item(at position: YJMiracleItemPosition, upper: Bool = false) -> YJMiracleView? {
		
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
			let childs = items.filter { !$0.items.isEmpty }
			if childs.isEmpty { return miracleView?.item(at: position, upper: true) }
			for child in childs {
				if let item = autoreleasepool(invoking: { () -> YJMiracleView? in
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
		items.forEach { (item: YJMiracleView) in
			autoreleasepool(invoking: { () -> Void in
				item.reload()
				item.removeFromSuperview()
			})
		}
		_items.removeAll()
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
			item.miracleView = self
			
			item.isRootItem = false
			item.autoTranslucentable = false
			item.attachable = false
			
			superview!.insertSubview(item, belowSubview: self)
			
			_items.append(item)
		}
	}
	
	/// 执行动画（打开／关闭）
	fileprivate func fire() {
		let group = DispatchGroup()
		animating = true
		items.forEach {
			group.enter()
			$0.animateDriver.excuteAnimation(open: !opened) { group.leave() }
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


// MARK: - YJAttachable
extension YJMiracleView: YJAttachable {
	open func shouldStateChanged(_ state: UIGestureRecognizerState) -> Bool {
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






















