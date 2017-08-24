//
//  YJMiracleItem.swift
//  YJMiracleView
//
//  Created by ddn on 2017/8/23.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

public class YJMiracleItemPosition {
	
	public var index: Int = 0
	public var lane: Int = 0
	public var parent: YJMiracleItemPosition?
	
	public init(lane: Int = 0, index: Int = 0, parent: YJMiracleItemPosition? = nil) {
		self.lane = lane
		self.index = index
		self.parent = parent
	}
	
	public static func ==(lhs: YJMiracleItemPosition, rhs: YJMiracleItemPosition) -> Bool {
		let equal = lhs.index == rhs.index && lhs.lane == rhs.lane
		if !equal { return false }
		if let lParent = lhs.parent, let rParent = rhs.parent {
			return lParent == rParent
		}
		return lhs.parent == nil && rhs.parent == nil
	}
}

extension YJMiracleItemPosition {
	private func findAncestor(_ position: YJMiracleItemPosition) -> YJMiracleItemPosition {
		guard let parent = position.parent else { return position }
		return findAncestor(parent)
	}
}

public class YJMiracleItem: UIView {
	
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
	
	override public init(frame: CGRect) {
		super.init(frame: frame)
		layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		let tap = UITapGestureRecognizer(target: self, action: #selector(tapOn(_:)))
		tap.delaysTouchesBegan = true
		addGestureRecognizer(tap)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override public func layoutSubviews() {
		super.layoutSubviews()
		if let label = _textLabel {
			label.frame = bounds
		}
		if let imageView = _backgroundImageView {
			imageView.frame = bounds
		}
	}
	
	public var clickOn: (()->())?
	
	public var position: YJMiracleItemPosition = YJMiracleItemPosition()
	
	var openedLocation: CGPoint = CGPoint.zero
	
	var closedLocation: CGPoint = CGPoint.zero
	
	var animate: ((_ completion: (()->())?)->())?
	
	public weak var miracleView: YJMiracleView?
	
	func tapOn(_ sender: UITapGestureRecognizer) {
		clickOn?()
	}
}
