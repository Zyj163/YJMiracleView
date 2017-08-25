//
//  YJMiracleItemPosition.swift
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
