//
//  YJAttachable.swift
//  YJMiracleView
//
//  Created by ddn on 2017/8/24.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

extension UIPanGestureRecognizer {
	static func block(_ block: (UIPanGestureRecognizer)->()) -> UIPanGestureRecognizer {
		let pan = UIPanGestureRecognizer(target: self, action: #selector(yj_panOn(sender:)))
		objc_setAssociatedObject(pan, UnsafeRawPointer(bitPattern: "yj_panBlock".hashValue), block, .OBJC_ASSOCIATION_COPY_NONATOMIC)
		return pan
	}
	
	static func yj_panOn(sender: UIPanGestureRecognizer) {
		let block = objc_getAssociatedObject(sender, UnsafeRawPointer(bitPattern: "yj_panBlock".hashValue)) as? (UIPanGestureRecognizer)->()
		block?(sender)
	}
}

public protocol YJAttachable {
	func shouldStateChanged(_ state: UIGestureRecognizerState) -> Bool
}

extension YJAttachable where Self: UIView {
	public func activeAttachable() {
		let pan = UIPanGestureRecognizer.block { attachable_panOn(sender: $0) }
		objc_setAssociatedObject(pan, UnsafeRawPointer(bitPattern: "YJAttachable".hashValue), true, .OBJC_ASSOCIATION_ASSIGN)
		addGestureRecognizer(pan)
	}
	
	public func inactiveAttachable() {
		guard let geses = gestureRecognizers else {return}
		for ges in geses {
			if ges is UIPanGestureRecognizer, objc_getAssociatedObject(ges, UnsafeRawPointer(bitPattern: "YJAttachable".hashValue)) as? Bool ?? false {
				ges.removeTarget(ges.self, action: nil)
				removeGestureRecognizer(ges)
				break
			}
		}
	}
	
	private func attachable_panOn(sender: UIPanGestureRecognizer) {
		guard let superview = superview else {return}
		if !shouldStateChanged(sender.state) {return}
		switch sender.state {
		case .changed:
			let translation = sender.translation(in: superview)
			layer.position = CGPoint(x: layer.position.x + translation.x, y: layer.position.y + translation.y)
			sender.setTranslation(CGPoint.zero, in: superview)
		case .ended, .cancelled:
			var x: CGFloat = 0;
			var r: Bool = false
			if center.x > superview.bounds.width / 2 {
				//靠右
				x = superview.bounds.width - center.x
				r = true
			} else {
				x = center.x
			}
			var y: CGFloat = 0
			var b: Bool = false
			if center.y > superview.bounds.height / 2 {
				//靠下
				y = superview.bounds.height - center.y
				b = true
			} else {
				y = center.y
			}
			
			let disX = bounds.width * layer.anchorPoint.x
			let disY = bounds.height * layer.anchorPoint.y
			if x < y {
				//左右
				x = r ? superview.bounds.width - disX : disX
				y = center.y
			} else {
				x = center.x
				y = b ? superview.bounds.height - disY : disY
			}
			UIView.animate(withDuration: 0.15, animations: {
				self.layer.position = CGPoint(x: x, y: y)
			})
		default:
			break
		}
	}
}

extension YJAttachable {
	public func shouldStateChanged(_ state: UIGestureRecognizerState) -> Bool {
		return true
	}
}
