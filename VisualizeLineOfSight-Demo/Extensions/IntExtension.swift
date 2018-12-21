//
//  IntExtension.swift
//  VisualizeLineOfSight-Demo
//
//  Created by aptueno on 2018/12/08.
//  Copyright © 2018 aptpod,Inc. All rights reserved.
//

import Foundation

extension Int {
    
    var commaString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let commaString = formatter.string(from: self as NSNumber)
        return commaString ?? "\(self)"
    }
    
}
