//
//  ViewController.swift
//  YJMiracleView
//
//  Created by Zyj163 on 08/23/2017.
//  Copyright (c) 2017 Zyj163. All rights reserved.
//

import UIKit
import YJMiracleView

class ViewController: UIViewController {

	lazy var miracleView: YJMiracleView = YJMiracleView(CGRect(x: 0, y: self.view.bounds.height - 30, width: 30, height: 30), autoTranslucentable: true, movable: true)
    
    var type: Int = 0 {
        didSet {
            switch type {
            case 0:
                miracleView.animateDriver.animateType = .lineH(10)
            case 1:
                miracleView.animateDriver.animateType = .circle(100, 0, CGFloat.pi / 2)
            default:
                break
            }
        }
    }
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		miracleView.dataSource = self
        miracleView.delegate = self
		miracleView.backgroundColor = .red
		miracleView.layer.cornerRadius = 15
		miracleView.layer.masksToBounds = true
		miracleView.clickOn = { [weak miracleView] in
			miracleView?.isOpened ?? false ? miracleView?.close() : miracleView?.open()
		}
        
		view.addSubview(miracleView)
		
		miracleView.textLabel.text = "0-0"
		miracleView.textLabel.textColor = .white
        
        type = 0
    }
}

extension ViewController: YJMiracleViewDataSource {

    func numbersOfItem(in miracleView: YJMiracleView) -> Int {
        
        return 3
    }
	
	func miracleView(miracleView: YJMiracleView, itemAt position: YJMiracleItemPosition) -> YJMiracleView {
		
		let item = YJMiracleView()
		item.backgroundColor = UIColor(red: CGFloat(arc4random()%256)/255.0, green: CGFloat(arc4random()%256)/255.0, blue: CGFloat(arc4random()%256)/255.0, alpha: 1)
		item.clickOn = { [weak item] in
			item?.isOpened ?? false ? item?.close() : item?.open()
		}
		item.dataSource = self
		item.textLabel.text = "\(position.lane)-\(position.index)"
        item.textLabel.textColor = .white
        item.layer.cornerRadius = 15
        item.layer.masksToBounds = true
        
        switch miracleView.animateDriver.animateType {
        case .lineH(let space):
            item.animateDriver.animateType = .lineV(space)
        case .lineV(let space):
            item.animateDriver.animateType = .lineH(space)
        default:
            item.animateDriver.animateType = miracleView.animateDriver.animateType
            break
        }
		return item
	}
	
	func miracleView(_ miracleView: YJMiracleView, sizeOfItemAt position: YJMiracleItemPosition) -> CGSize{
        
        return CGSize(width: 30, height: 30)
	}
}

extension ViewController: YJMiracleViewDelegate {
    func miracleViewDidOpened(_ miracleView: YJMiracleView) {
        print("did open position \(miracleView.position)")
//        miracleView.alpha = 0.1
    }
    
    func miracleViewDidClosed(_ miracleView: YJMiracleView) {
        if miracleView == self.miracleView {
            switch type {
            case 0:
                type = 1
            default:
                type = 0
            }
        }
    }
}

