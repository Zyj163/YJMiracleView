//
//  ViewController.swift
//  YJMiracleView
//
//  Created by Zyj163 on 08/23/2017.
//  Copyright (c) 2017 Zyj163. All rights reserved.
//

import UIKit
import YJMiracleView

class ViewController2: UIViewController {
    
    @IBOutlet weak var containerView1: UIView!
    @IBOutlet weak var containerView2: UIView!
    @IBOutlet weak var containerView3: UIView!
    @IBOutlet weak var containerView4: UIView!
    @IBOutlet weak var containerView5: UIView!
    @IBOutlet weak var containerView6: UIView!
    
    func addMiracleView(containerView: UIView, animateType: YJMiracleViewAnimateType, identifier: String) {
        containerView.backgroundColor = .clear
        let miracleView: YJMiracleView = YJMiracleView(CGRect(x: containerView.bounds.width / 2 - 10, y: containerView.bounds.height / 2 - 10, width: 20, height: 20), autoTranslucentable: false, movable: false)
        miracleView.dataSource = self
        miracleView.delegate = self
        miracleView.backgroundColor = .red
        miracleView.layer.cornerRadius = 10
        miracleView.layer.masksToBounds = true
        miracleView.clickOn = { [weak miracleView] in
            miracleView?.isOpened ?? false ? miracleView?.close() : miracleView?.open()
        }
        miracleView.animateDriver.animateType = animateType
        miracleView.justOneMiracleView = true
        
        containerView.addSubview(miracleView)
        
        miracleView.identifier = identifier
        
        miracleView.open()
        
        let animate = CABasicAnimation(keyPath: "transform.rotation.z")
        animate.fromValue = 0
        animate.toValue = CGFloat.pi * 2
        animate.repeatCount = MAXFLOAT
        animate.fillMode = CAMediaTimingFillMode.forwards
        animate.duration = 3
        
        containerView.layer.removeAllAnimations()
        containerView.layer.add(animate, forKey: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addMiracleView(containerView: containerView1, animateType: .circle(50, 0, CGFloat.pi * 2), identifier: "1")
        addMiracleView(containerView: containerView2, animateType: .circle(50, CGFloat.pi / 6, CGFloat.pi * 3 / 2), identifier: "2")
        addMiracleView(containerView: containerView3, animateType: .circle(50, 0, CGFloat.pi * 3 / 2), identifier: "3")
        
        addMiracleView(containerView: containerView4, animateType: .circle(50, CGFloat.pi / 6, CGFloat.pi * 3 / 2), identifier: "4-1")
        addMiracleView(containerView: containerView4, animateType: .circle(50, CGFloat.pi * 7 / 6, CGFloat.pi * 5 / 2), identifier: "4-2")
        addMiracleView(containerView: containerView5, animateType: .circle(0, 0, CGFloat.pi * 1 / 2), identifier: "5")
        addMiracleView(containerView: containerView6, animateType: .circle(50, 0, CGFloat.pi * 3 / 2), identifier: "6")
        
    }
}

extension ViewController2: YJMiracleViewDataSource {
    
    func numbersOfItem(in miracleView: YJMiracleView) -> Int {
        guard let identifier = miracleView.identifier else {return 0}
        switch identifier {
        case "1":
            return 9
        case "2":
            return 3
        case "3":
            return 4
        case "4-1", "4-2":
            return 3
        case "5":
            return 2
        case "6":
            return 9
        default:
            return 0
        }
    }
    
    func miracleView(miracleView: YJMiracleView, itemAt position: YJMiracleItemPosition) -> YJMiracleView {
        
        let item = YJMiracleView()
        item.backgroundColor = UIColor(red: CGFloat(arc4random()%256)/255.0, green: CGFloat(arc4random()%256)/255.0, blue: CGFloat(arc4random()%256)/255.0, alpha: 1)
        
        switch miracleView {
        case containerView1.subviews.last!:
            item.layer.cornerRadius = 10
            item.layer.masksToBounds = true
        default:
            break
        }
        return item
    }
    
    func miracleView(_ miracleView: YJMiracleView, sizeOfItemAt position: YJMiracleItemPosition) -> CGSize{
        guard let identifier = miracleView.identifier else {return CGSize.zero}
        switch identifier {
        case "1":
            return CGSize(width: 20, height: 20)
        case "2":
            return CGSize(width: 100 * sin(CGFloat.pi / 3), height: 2)
        case "3":
            return CGSize(width: 100 * sin(CGFloat.pi / 4), height: 2)
        case "4-1", "4-2":
            return CGSize(width: 100 * sin(CGFloat.pi / 3), height: 2)
        case "5":
            return CGSize(width: 100 * sin(CGFloat.pi / 3), height: 2)
        case "6":
            return CGSize(width: 100 * sin(CGFloat.pi / 3), height: 2)
        default:
            return CGSize.zero
        }
    }
}

extension ViewController2: YJMiracleViewDelegate {
    func miracleViewDidOpened(_ miracleView: YJMiracleView) {
        miracleView.alpha = 0.1
        if miracleView.identifier!.hasPrefix("4") {
            (containerView4.subviews as! [YJMiracleView]).filter {$0.identifier?.hasPrefix("4") ?? false && $0 != miracleView}.forEach {$0.open()}
        }
    }
    
    func miracleViewDidClosed(_ miracleView: YJMiracleView) {
        miracleView.alpha = 1
        if miracleView.identifier!.hasPrefix("4") {
            (containerView4.subviews as! [YJMiracleView]).filter {$0.identifier?.hasPrefix("4") ?? false && $0 != miracleView}.forEach {$0.close()}
        }
    }
}

