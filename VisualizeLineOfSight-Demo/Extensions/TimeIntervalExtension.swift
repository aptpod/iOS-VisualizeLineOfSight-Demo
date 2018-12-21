//
//  TimeIntervalExtension.swift
//  VisualizeLineOfSight-Demo
//
//  Created by aptueno on 2018/12/08.
//  Copyright © 2018 aptpod,Inc. All rights reserved.
//

import Foundation

extension TimeInterval {
    
    var timeString: String {
        let time = Int(self)
        let hour = time/3600
        let min = (time/60)%60
        let sec = time%60
        let ms = Int((self - TimeInterval(time)) * 1000)
        return String.init(format: "%02d:%02d:%02d.%03d", hour, min, sec, ms)
    }
}
