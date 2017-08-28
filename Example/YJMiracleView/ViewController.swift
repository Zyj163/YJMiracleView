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

	var miracleView: YJMiracleView = YJMiracleView()
	
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
		miracleView.layer.position = CGPoint(x: 15, y: view.bounds.height - 15)
		miracleView.layer.bounds = CGRect(x: 0, y: 0, width: 30, height: 30)
		miracleView.activeAttachable()
		miracleView.activeAutoTranslucent()
		view.addSubview(miracleView)
		
		miracleView.textLabel.text = "0-0"
		miracleView.textLabel.textColor = .white
        
        if title == "line" {
            miracleView.animateDriver.animateType = .lineH(10)
        } else {
            miracleView.animateDriver.animateType = .circle(100, 0, CGFloat.pi / 2)
        }
    }
}

extension ViewController: YJMiracleViewDataSource {

    func numbersOfItem(in miracleView: YJMiracleView) -> Int {
        return 4
    }
	
	func miracleView(miracleView: YJMiracleView, itemAt position: YJMiracleItemPosition) -> YJMiracleView {
		
		let item = YJMiracleView()
		item.backgroundColor = UIColor(red: CGFloat(arc4random()%256)/255.0, green: CGFloat(arc4random()%256)/255.0, blue: CGFloat(arc4random()%256)/255.0, alpha: 1)
		item.layer.cornerRadius = 15
		item.layer.masksToBounds = true
		item.clickOn = { [weak item] in
			item?.isOpened ?? false ? item?.close() : item?.open()
		}
		item.dataSource = self
		item.textLabel.text = "\(position.lane)-\(position.index)"
        item.textLabel.textColor = .white
        
        
        switch miracleView.animateDriver.animateType {
        case .lineH(let space):
            item.animateDriver.animateType = .lineV(space)
        case .lineV(let space):
            item.animateDriver.animateType = .lineH(space)
        default:
            item.animateDriver.animateType = miracleView.animateDriver.animateType
        }
		return item
	}
	
	func miracleView(_ miracleView: YJMiracleView, sizeOfItemAt position: YJMiracleItemPosition) -> CGSize{
		return CGSize(width: 30, height: 30)
	}
}

extension ViewController: YJMiracleViewDelegate {
    func mircaleViewDidOpened(_ mircaleView: YJMiracleView) {
        print("did open position \(miracleView.position)")
    }
    
    func mircaleViewDidClosed(_ mircaleView: YJMiracleView) {
        print("did close position \(miracleView.position)")
    }
}

