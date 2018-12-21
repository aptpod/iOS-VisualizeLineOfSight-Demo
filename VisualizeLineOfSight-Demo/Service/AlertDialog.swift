//
//  AlertDialog.swift
//  VisualizeLineOfSight-Demo
//
//  Created by aptueno on 2018/12/08.
//  Copyright © 2018 aptpod,Inc. All rights reserved.
//

import UIKit

class AlertDialog {
    
    static func show(viewController: UIViewController, title: String?, message: String?, btnTitle: String = "OK", completion: (() -> ())? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
            let btn = UIAlertAction.init(title: btnTitle, style: .default, handler: { (_) in
                completion?()
            })
            alert.addAction(btn)
            viewController.present(alert, animated: true, completion: nil)
        }
    }
}
