//
//  VisualizeDegreesView.swift
//  VisualizeLineOfSight-Demo
//
//  Created by aptueno on 2018/12/08.
//  Copyright © 2018 aptpod,Inc. All rights reserved.
//

import UIKit

class VisualizeDegreesView: UIView {
    
    let DIRECTION_START_COLOR = UIColor.init(red: 47/255.0, green: 172/255.0, blue: 255/255.0, alpha: 0.7)
    let DIRECTION_END_COLOR = UIColor.init(red: 47/255.0, green: 172/255.0, blue: 255/255.0, alpha: 0.0)
    let CIRCLE_SPLIT_SIZE = 5
    let CIRCLE_COLOR: UIColor = UIColor.white
    let BORDER_WIDTH: CGFloat = 1.0
    let CENTER_DOT_SIZE: CGFloat = 4
    let VISUALIZE_DEGREES: CGFloat = 45
    
    private var directionView: GradiationView!
    
    var offsetDegrees: CGFloat = 0
    
    var degrees: CGFloat = 0 {
        didSet {
            UIView.animate(withDuration: 0) {
                self.directionView.transform = CGAffineTransform.init(rotationAngle: (self.offsetDegrees+self.degrees).degreesToRadians)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)        
        _init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }
    
    private func _init() {
        // Check resize view item event.
        self.addObserver(self, forKeyPath: "bounds", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (object as? UIView == self && keyPath == "bounds") {
            self.removeObserver(self, forKeyPath: "bounds")
            //  Setup layout
            self.setupLayout()
        }
    }
    
    private func setupLayout() {
        let maxSize = self.frame.width < self.frame.height ? self.frame.width : self.frame.height
        let splitWidth = maxSize / CGFloat(CIRCLE_SPLIT_SIZE)
        
        // Direction View
        let directionViewWidth = maxSize+splitWidth*2
        self.directionView = GradiationView.init(frame: CGRect.init(x: (self.frame.width-directionViewWidth)/2, y: (self.frame.height-directionViewWidth)/2, width: directionViewWidth, height: directionViewWidth))
        self.directionView.layer.cornerRadius = self.directionView.frame.height/2
        self.directionView.gradStartColor = DIRECTION_START_COLOR
        self.directionView.gradEndColor = DIRECTION_END_COLOR
        self.directionView.gradStartPoint = CGPoint.init(x: 0.5, y: 0.5)
        self.directionView.gradEndPoint = CGPoint.init(x: 0.5, y: 0)
        let mask = CAShapeLayer()
        let path = UIBezierPath()
        let center = CGPoint(x: self.directionView.frame.width / 2, y: self.directionView.frame.height / 2)
        let baseAngle = -(CGFloat.pi / 2)
        let degreesToAngle = CGFloat.pi * (VISUALIZE_DEGREES / 180.0)
        let startAngle: CGFloat = baseAngle - (degreesToAngle / 2)
        let endAngle: CGFloat = baseAngle + (degreesToAngle / 2)
        path.move(to: center)
        path.addArc(withCenter: center, radius: self.directionView.frame.height/2, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        mask.path = path.cgPath
        self.directionView.layer.mask = mask
        self.addSubview(self.directionView)
        
        // Add Circle Views
        for i in 0..<CIRCLE_SPLIT_SIZE {
            let size = maxSize - splitWidth*CGFloat(i)
            let view = UIView.init(frame: CGRect.init(x: (self.frame.width-size)/2, y: (self.frame.height-size)/2, width: size, height: size))
            view.layer.borderColor = CIRCLE_COLOR.cgColor
            view.layer.borderWidth = BORDER_WIDTH
            view.layer.cornerRadius = size / 2
            self.addSubview(view)
        }
        
        // Add Center Dot View
        let dotView = UIView.init(frame: CGRect.init(x: (self.frame.width-CENTER_DOT_SIZE)/2, y: (self.frame.height-CENTER_DOT_SIZE)/2, width: CENTER_DOT_SIZE, height: CENTER_DOT_SIZE))
        dotView.backgroundColor = CIRCLE_COLOR
        dotView.layer.cornerRadius = CENTER_DOT_SIZE / 2
        self.addSubview(dotView)
    }
}

fileprivate class GradiationView: UIView {
    
    public var gradientLayer: CAGradientLayer?
    
    var gradStartColor: UIColor = UIColor.white {
        didSet {
            self.setGradation()
        }
    }
    
    var gradEndColor: UIColor = UIColor.black {
        didSet {
            self.setGradation()
        }
    }
    
    var gradStartPoint: CGPoint = CGPoint.init(x: 0, y: 0.5) {
        didSet {
            self.setGradation()
        }
    }
    
    var gradEndPoint: CGPoint = CGPoint.init(x: 1, y: 0.5) {
        didSet {
            self.setGradation()
        }
    }
    
    public func setGradation(startColor: UIColor, endColor: UIColor) {
        self.gradStartColor = startColor
        self.gradEndColor = endColor
    }
    
    private func setGradation() {
        self.gradientLayer?.removeFromSuperlayer()
        self.gradientLayer = CAGradientLayer()
        self.gradientLayer!.colors = [self.gradStartColor.cgColor, self.gradEndColor.cgColor]
        self.gradientLayer!.frame.size = self.frame.size
        self.gradientLayer!.startPoint = self.gradStartPoint
        self.gradientLayer!.endPoint = self.gradEndPoint
        layer.addSublayer(self.gradientLayer!)
        layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        // Update Layouts.
        self.setGradation()
    }
}
