//
//  RightVisualizeDegreesView.swift
//  VisualizeLineOfSight-Demo
//
//  Created by aptueno on 2018/12/08.
//  Copyright © 2018 aptpod,Inc. All rights reserved.
//

import UIKit

class RightVisualizeDegreesView: UIView {
    
    let DIRECTION_START_COLOR = UIColor.init(red: 47/255.0, green: 172/255.0, blue: 255/255.0, alpha: 0.7)
    let DIRECTION_END_COLOR = UIColor.init(red: 47/255.0, green: 172/255.0, blue: 255/255.0, alpha: 0.0)
    let VISUALIZE_DEGREES: CGFloat = 45
    let DEGREES_SPLIT_VALUE = 18
    let LINE_WIDTH: CGFloat = 1
    let LINE_COLOR: UIColor = UIColor.white
    
    private var directionView: GradiationView!
    
    var degrees: CGFloat = 0 {
        didSet {
            UIView.animate(withDuration: 0) {
                self.directionView.transform = CGAffineTransform.init(rotationAngle: -self.degrees.degreesToRadians)
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
        // Direction View
        let directionViewWidth = self.frame.width*2
        self.directionView = GradiationView.init(frame: CGRect.init(x: ((self.frame.width-directionViewWidth)/2)-self.frame.width/2, y: (self.frame.height-directionViewWidth)/2, width: directionViewWidth, height: directionViewWidth))
        self.directionView.layer.cornerRadius = self.directionView.frame.height/2
        self.directionView.gradStartColor = DIRECTION_START_COLOR
        self.directionView.gradEndColor = DIRECTION_END_COLOR
        self.directionView.gradStartPoint = CGPoint.init(x: 0.5, y: 0.5)
        self.directionView.gradEndPoint = CGPoint.init(x: 1.0, y: 0.5)
        let mask = CAShapeLayer()
        let path = UIBezierPath()
        let center = CGPoint(x: self.directionView.frame.width / 2, y: self.directionView.frame.height / 2)
        let baseAngle: CGFloat = 0
        let degreesToAngle = CGFloat.pi * (VISUALIZE_DEGREES / 180.0)
        let startAngle: CGFloat = baseAngle - (degreesToAngle / 2)
        let endAngle: CGFloat = baseAngle + (degreesToAngle / 2)
        path.move(to: center)
        path.addArc(withCenter: center, radius: self.directionView.frame.height/2, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        mask.path = path.cgPath
        self.directionView.layer.mask = mask
        self.addSubview(self.directionView)
        
        // Line View
        var lineWidth = self.frame.width < (self.frame.height/2) ? self.frame.width*2 : (self.frame.height/2)*2
        lineWidth -= lineWidth / 10
        let lineView = UIView.init(frame: CGRect.init(x: -lineWidth, y: (self.frame.height-lineWidth)/2, width: lineWidth, height: lineWidth))
        // Split Degrees
        let splitDegrees = 180 / DEGREES_SPLIT_VALUE
        for i in 0...DEGREES_SPLIT_VALUE {
            let view = UIView.init(frame: CGRect.init(x: lineWidth/2, y: (lineView.frame.height-LINE_WIDTH)/2, width: lineWidth, height: LINE_WIDTH))
            view.backgroundColor = LINE_COLOR
            let lvMask = CAShapeLayer()
            let lvPath = UIBezierPath.init(rect: CGRect.init(x: 0, y: 0, width: lineWidth/2, height: lineWidth))
            lvMask.path = lvPath.cgPath
            view.layer.mask = lvMask
            view.transform = CGAffineTransform.init(rotationAngle: CGFloat(splitDegrees*i+90).degreesToRadians)
            lineView.addSubview(view)
        }
        self.addSubview(lineView)
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
