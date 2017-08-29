//
//  YJMiracleAnimateDriver.swift
//  Pods
//
//  Created by ddn on 2017/8/25.
//
//

import UIKit

public enum YJMiracleViewAnimateType {
    case none
	case lineH(CGFloat) //item 间隔
	case lineV(CGFloat) //item 间隔
	case circle(CGFloat, CGFloat, CGFloat)//半径，起始角度，结束角度（向右水平线为0度）
	case custom
    
    
    var space: CGFloat? {
        get {
            switch self {
            case .lineV(let space), .lineH(let space):
                return space
            default:
                return nil
            }
        }
        set {
            guard let newValue = newValue else {return}
            switch self {
            case .lineV(let space) where space != newValue:
                self = .lineV(newValue)
            case .lineH(let space) where space != newValue:
                self = .lineH(newValue)
            default:
                break
            }
        }
    }
}

public struct YJMiracleAnimation {
	//坐标
	var openLocation: CGPoint?
	var closeLocation: CGPoint?
	//坐标以外
	var openTransform: CATransform3D?
	var closeTransform: CATransform3D?
	//透明度
	var openOpacity: Float? = 1
	var closeOpacity: Float? = 0
	
	var openOptions: UIViewAnimationOptions = [.curveLinear]
	var closeOptions: UIViewAnimationOptions = [.curveLinear]
	
	var openDuration: TimeInterval = 0.25
	var closeDuration: TimeInterval = 0.25
	
	var openDelay: TimeInterval = 0.1
	var closeDelay: TimeInterval = 0.1
	
	var spring: Bool = true
	
	func install(_ layer: CALayer, open: Bool) {
		
		if open {
			if let openLocation = openLocation {
				layer.position = openLocation
			}
			if let openOpacity = openOpacity {
				layer.opacity = openOpacity
			}
			if let openTransform = openTransform {
				layer.transform = openTransform
			}
		} else {
			if let closeLocation = closeLocation {
				layer.position = closeLocation
			}
			if let closeOpacity = closeOpacity {
				layer.opacity = closeOpacity
			}
			if let closeTransform = closeTransform {
				layer.transform = closeTransform
			}
		}
	}
}


public class YJMiracleAnimateDriver {

	public var animateType: YJMiracleViewAnimateType = .none
	
	fileprivate weak var _miracleView: YJMiracleView?
	
	public var miracleView: YJMiracleView? {
		return _miracleView
	}
	
	public var animate: ((_ open: Bool, _ completion: (()->())?)->())?
	
	required public init(_ miracleView: YJMiracleView) {
		_miracleView = miracleView
	}
	
	/// 装载动画（打开／关闭），可重写的这个方法，自定义动画及展开后的布局，可以调用installAnimation将动画参数添加到miracleView
	open func loadAnimations() {
		switch animateType {
		case .lineH(let space):
			lineHAnimation(space)
		case .lineV(let space):
			lineVAnimation(space)
		case .circle(let radius, let startAngle, let endAngle):
			circleAnimation(radius: radius, startAngle: startAngle, endAngle: endAngle)
		default:
            fatalError("you should set a valide animateType")
			break
		}
	}

}

// MARK: - line布局
extension YJMiracleAnimateDriver {
	
    fileprivate func lineHAnimation(_ space: CGFloat, force: Bool = false) {
		
		guard let miracleView = miracleView, let superview = miracleView.superview else {
			return
		}
		let frame = miracleView.frame
		let bounds = miracleView.bounds
		let items = miracleView.items
		if items.isEmpty {return}
		
		//先判断往左还是往右（规则：哪边离得远去哪边）
		let l = miracleView.frame.minX
		let r = superview.frame.maxX - frame.maxX
		var layoutFrame: CGRect
		
		//优先原则：这条线没有其它item，不与其它item碰撞
		if (r > l && !force) || (r <= l && force) {
			var totalW: CGFloat = frame.maxX
			for (i, item) in items.enumerated() {
				let x = totalW + space + item.bounds.width / 2
				var animation = YJMiracleAnimation()
				animation.openLocation = CGPoint(x: x, y: item.layer.position.y)
				animation.closeLocation = item.layer.position
				animation.openDelay = Double(items.count - 1 - i) * animation.closeDuration / 2
				animation.closeDelay = Double(i) * animation.closeDuration / 2
				item.animateDriver.animate = item.animateDriver.installAnimation(animation)
				
				totalW = x + item.bounds.width / 2
			}
			layoutFrame = CGRect(x: frame.maxX, y: frame.minY, width: totalW - frame.maxX, height: bounds.height)
			
		} else {
			var totalW: CGFloat = frame.minX
			for (i, item) in items.enumerated() {
				let x = totalW - space - item.bounds.width / 2
				var animation = YJMiracleAnimation()
				animation.openLocation = CGPoint(x: x, y: item.layer.position.y)
				animation.closeLocation = item.layer.position
				animation.openDelay = Double(items.count - 1 - i) * animation.closeDuration / 2
				animation.closeDelay = Double(i) * animation.closeDuration / 2
				item.animateDriver.animate = item.animateDriver.installAnimation(animation)
				
				totalW = x - item.bounds.width / 2
			}
			layoutFrame = CGRect(x: totalW, y: frame.minY, width: frame.minX - totalW, height: bounds.height)
		}
		
		let has = superview.subviews.filter({ (view: UIView) -> Bool in
			return view != miracleView && view.frame.intersects(layoutFrame)
		}).count > 0
		
		if has && !force { return lineHAnimation(space, force: true) }
		else if has { return }
	}
	
	fileprivate func lineVAnimation(_ space: CGFloat, force: Bool = false) {
		
		guard let miracleView = miracleView, let superview = miracleView.superview else {
			return
		}
		let frame = miracleView.frame
		let bounds = miracleView.bounds
		let items = miracleView.items
		if items.isEmpty {return}
		
		//先判断往上还是往下（规则：哪边离得远去哪边）
		let t = frame.minY
		let b = superview.frame.maxY - frame.maxY
		
		var layoutFrame: CGRect
		
		if (t > b && !force) || (t <= b && force) {
			var totalH: CGFloat = frame.minY
			for (i, item) in items.enumerated() {
				let y = totalH - space - item.bounds.height / 2
				var animation = YJMiracleAnimation()
				animation.openLocation = CGPoint(x: item.layer.position.x, y: y)
				animation.closeLocation = item.layer.position
				animation.openDelay = Double(items.count - 1 - i) * animation.closeDuration / 2
				animation.closeDelay = Double(i) * animation.closeDuration / 2
				item.animateDriver.animate = item.animateDriver.installAnimation(animation)
				
				totalH = y - item.bounds.height / 2
			}
			layoutFrame = CGRect(x: frame.minX, y: totalH, width: bounds.width, height: frame.minY - totalH)
			
		} else {
			var totalH: CGFloat = frame.maxY
			for (i, item) in items.enumerated() {
				let y = totalH + space + item.bounds.height / 2
				var animation = YJMiracleAnimation()
				animation.openLocation = CGPoint(x: item.layer.position.x, y: y)
				animation.closeLocation = item.layer.position
				animation.openDelay = Double(items.count - 1 - i) * animation.closeDuration / 2
				animation.closeDelay = Double(i) * animation.closeDuration / 2
				item.animateDriver.animate = item.animateDriver.installAnimation(animation)
				
				totalH = y + item.bounds.height / 2
			}
			layoutFrame = CGRect(x: frame.minX, y: frame.maxY, width: bounds.width, height: totalH - frame.maxY)
		}
		
		let has = superview.subviews.filter({ (view: UIView) -> Bool in
			return view != miracleView && view.frame.intersects(layoutFrame)
		}).count > 0
		
		if has && !force { return lineVAnimation(space, force: true) }
		else if has { return }
	}
}

// MARK: - circle布局
extension YJMiracleAnimateDriver {
    fileprivate func circleAnimation(radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) {
		guard let miracleView = miracleView else {
			return
		}
		if miracleView.items.isEmpty {return}
		
		let itemCount = miracleView.items.count
        var totalAngle: CGFloat = 0
        miracleView.items.enumerated().forEach { (offset: Int, element: YJMiracleView) in
            let size = element.bounds.size
            let diameter = size.width
            let angle = radius == 0 ? 0 : 2 * asin(diameter / 2 / radius)
            totalAngle += angle * ((offset == 0 || offset == itemCount - 1) ? 0.5 : 1)
        }
        
        let layoutAngle = endAngle - startAngle
        let spaceAngle = (layoutAngle - totalAngle) / CGFloat(itemCount - 1)
        
        totalAngle = startAngle
        
        miracleView.items.enumerated().forEach { (offset: Int, element: YJMiracleView) in
            let size = element.bounds.size
            let diameter = size.width
            let angle = radius == 0 ? 0 : 2 * asin(diameter / 2 / radius)
            
            totalAngle += CGFloat(offset == 0 ? 0 : (angle / 2 + spaceAngle))
            
            let x = radius * cos(angle / 2) * cos(totalAngle)
            let y = radius * cos(angle / 2) * sin(totalAngle)
            
            var animation = YJMiracleAnimation()
            animation.openLocation = CGPoint(x: miracleView.layer.position.x + x, y: miracleView.layer.position.y - y)
            animation.closeLocation = element.layer.position
            animation.openDelay = 0
            animation.closeDelay = 0
            animation.openTransform = CATransform3DMakeRotation(CGFloat.pi / 2 - totalAngle, 0, 0, 1)
            animation.closeTransform = CATransform3DIdentity
            element.animateDriver.animate = element.animateDriver.installAnimation(animation)
            
            totalAngle += angle / 2
        }
	}
}

extension YJMiracleAnimateDriver {
	
	/// 装载动画到具体item，默认使用UIView.animate，可重写使用其它方式
	///
	/// - Parameter animation: 动画参数
	/// - Returns: 执行动画的block
	open func installAnimation(_ animation: YJMiracleAnimation) -> ((Bool, (()->())?)->())? {
		return { [weak self] (open, completion) in
			if let miracleView = self?.miracleView {
				
				let duration = open ? animation.openDuration : animation.closeDuration
				let delay = open ? animation.openDelay : animation.closeDelay
				let options = open ? animation.openOptions : animation.closeOptions
				
				animation.spring ?
					UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.75, options: options, animations: {
						animation.install(miracleView.layer, open: open)
					}, completion: { (finish) in
						completion?()
					})
				:
					UIView.animate(withDuration: duration, delay: delay, options: options, animations: { 
						animation.install(miracleView.layer, open: open)
					}, completion: { (finish) in
						completion?()
					})
			}
		}
	}
	
	/// 执行动画
	///
	/// - Parameters:
	///   - open: 是否是展开
	///   - completion: 完成后的回调
	open func excuteAnimation(open: Bool, completion: @escaping ()->()) {
		animate?(open, completion)
	}
	
	/// 点击效果
	open func clickOnAnimation() {
		guard let miracleView = miracleView else {return}
		if miracleView.isAnimating {return}
		
		var animation = YJMiracleAnimation()
		animation.openTransform = CATransform3DRotate(miracleView.layer.transform, CGFloat.pi / 2, 0, 0, 1)
		animation.closeTransform = CATransform3DRotate(miracleView.layer.transform, -CGFloat.pi / 2, 0, 0, 1)
		animation.openOpacity = 1
		animation.closeOpacity = 1
		animation.openDelay = 0
		animation.closeDelay = 0
		animation.spring = false
		
		installAnimation(animation)?(!miracleView.isOpened, nil)
	}
}





