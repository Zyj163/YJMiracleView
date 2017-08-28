//
//  YJMiracleView.swift
//  YJMiracleView
//
//  Created by ddn on 2017/8/23.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

public protocol YJMiracleViewDataSource: class {
	
    /// 当前miracleView的子item个数
    ///
    /// - Parameter miracleView: 当前miracleView
    /// - Returns: 子item个数
    func numbersOfItem(in miracleView: YJMiracleView) -> Int
	
	/// 当前miracleView的子item
	///
	/// - Parameters:
	///   - miracleView: 当前miracleView
	///   - position: 子item的position
	/// - Returns: 子item
	func miracleView(miracleView: YJMiracleView, itemAt position: YJMiracleItemPosition) -> YJMiracleView
    
	/// 当前miracleView下子item的size
	///
	/// - Parameters:
	///   - miracleView: 当前miracleView
	///   - position: 子item的position
	/// - Returns: 子item的size
	func miracleView(_ miracleView: YJMiracleView, sizeOfItemAt position: YJMiracleItemPosition) -> CGSize
}

@objc public protocol YJMiracleViewDelegate: NSObjectProtocol {
	
	/// 展开完毕
	///
	/// - Parameter mircaleView: 被展开的miracleView
	@objc optional func mircaleViewDidOpened(_ mircaleView: YJMiracleView)
    
	/// 关闭完毕
	///
	/// - Parameter mircaleView: 被关闭的miracleView
	@objc optional func mircaleViewDidClosed(_ mircaleView: YJMiracleView)
    
    /// 结束移动
    ///
    /// - Parameter mircaleView: 被移动的miracleView（默认只有根miracleView可以移动）
    @objc optional func mircaleViewDidEndMoved(_ mircaleView: YJMiracleView)
    /// 开始移动
    ///
    /// - Parameter mircaleView: 被移动的miracleView（默认只有根miracleView可以移动）
    @objc optional func mircaleViewDidBeganMoving(_ mircaleView: YJMiracleView)
    /// 正在移动
    ///
    /// - Parameter mircaleView: 被移动的miracleView（默认只有根miracleView可以移动）
    @objc optional func mircaleViewIsMoving(_ mircaleView: YJMiracleView)
}

open class YJMiracleView: UIView {
	
	/// 数据源
	public weak var dataSource: YJMiracleViewDataSource?
    
	/// 代理
	public weak var delegate: YJMiracleViewDelegate?
	
	/// 文本控件（懒加载）
	public lazy var textLabel: UILabel = {
		let label = UILabel()
		label.font = UIFont.systemFont(ofSize: 13)
		label.textAlignment = .center
		self.addSubview(label)
		self._textLabel = label
		return label
	}()
	
	fileprivate var _textLabel: UILabel?
	
	/// 背景图控件（懒加载）
	public lazy var backgroundImageView: UIImageView = {
		let imageView = UIImageView()
		self.insertSubview(imageView, at: 0)
		return imageView
	}()
	
	fileprivate var _backgroundImageView: UIImageView?
	
	fileprivate lazy var _items: [YJMiracleView] = [YJMiracleView]()
    
	/// 子item集合
	public var items: [YJMiracleView] {
		return _items
	}
	
	fileprivate var opened: Bool = false
	fileprivate var animating: Bool = false
	
	/// 是否处于展开状态
	public var isOpened: Bool {
		return opened
	}
    
	/// 是否正在执行打开或关闭过程中
	public var isAnimating: Bool {
		return animating
	}
	
	fileprivate var autoTranslucentable: Bool = true
	fileprivate var attachable: Bool = true
	
	fileprivate var isRootItem: Bool = true
	
	/// 动画及布局执行者
	public lazy var animateDriver: YJMiracleAnimateDriver = YJMiracleAnimateDriver(self)
	
	/// 点击事件
	public var clickOn: (()->())?
	
	/// 是否需要点击效果
	public var hasClickOnAnimate: Bool = true
	
	/// 所处级位
	public var position: YJMiracleItemPosition = YJMiracleItemPosition()
	
	/// 父miracleView
	public weak var miracleView: YJMiracleView?
	
	/// 构造器
	///
	/// - Parameters:
	///   - frame: frame
	///   - autoTranslucentable: 是否开启自动延时半透明
	///   - attachable: 是否可以移动（根miracleView有效）
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
	
	/// 如果需要修改默认子控件的布局，要重写这个方法
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
    
	/// 展开
	public func open() {
		
		if opened || animating { return }
		
		prepareToOpen()
		
		animateDriver.loadAnimations()
		
		fire()
	}
	
	/// 关闭
	public func close() {
		if !opened || animating { return }
		items.forEach { (item: YJMiracleView) in
			autoreleasepool(invoking: { () -> Void in
				item.close()
			})
		}
		fire()
	}
	
	/// 获取指定position的item
	///
	/// - Parameters:
	///   - position: position
	///   - upper: 是否只向上查找（也会查找直接子item及兄弟item）
	/// - Returns: item
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
		
		let tmpNum = dataSource.numbersOfItem(in: self)
		if tmpNum == 0 { return }
		
		if superview == nil {
			guard let keyWindow = UIApplication.shared.keyWindow else { return }
			keyWindow.addSubview(self)
			self.bounds = CGRect(origin: CGPoint.zero, size: dataSource.miracleView(self, sizeOfItemAt: YJMiracleItemPosition(lane: position.index, index: 0, parent: position)))
		}
		
		for i in 1...tmpNum {
			let pp = YJMiracleItemPosition(lane: position.index, index: i, parent: position)
			let item = dataSource.miracleView(miracleView: self, itemAt: pp)
			item.bounds = CGRect(origin: CGPoint.zero, size: dataSource.miracleView(self, sizeOfItemAt: pp))
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
            delegate?.mircaleViewDidBeganMoving?(self)
			inactiveAutoTranslucent()
		case .ended, .cancelled:
            delegate?.mircaleViewDidEndMoved?(self)
			activeAutoTranslucent()
        case .changed:
            delegate?.mircaleViewIsMoving?(self)
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






















