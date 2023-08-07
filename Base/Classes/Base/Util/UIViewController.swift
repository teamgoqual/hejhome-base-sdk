//
//  UIViewController.swift
//  HejhomeSDK
//
//  Created by Dasom Kim on 2023/06/28.
//

import UIKit

extension UIViewController {
    static func initViewController<T: UIViewController>(viewControllerClass: T.Type) -> T{

        let podBundle = Bundle(for: HejhomeBase.self)
        if let bundleURL = podBundle.url(forResource: "HejhomeSDK_iOS", withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                let nib = UINib(nibName: "\(T.self)", bundle: bundle)
                let vc = nib.instantiate(withOwner: nil, options: nil)
                if let callViewController = vc.filter( { $0 is T } ).first as? T {
                    return callViewController
                }
            }
        }
        
        return UIViewController() as! T
    }
}
