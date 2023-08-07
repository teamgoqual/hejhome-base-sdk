//
//  LoginView.swift
//  HejhomeSDK
//
//  Created by Dasom Kim on 2023/06/28.
//

import Foundation
import UIKit



class LoginView: UIView {
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var pwTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var pwView: UIView!
    @IBOutlet weak var errorView: UIView!
    
    var view: UIView?
    
    var loginButtonAction: (String) -> Void = { _ in }
    var closeButtonAction: () -> Void = {}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadXib()
    }
    
    func setData(email: String) {
        emailLabel.text = email
    }
    
    @IBAction func clickLoginButton(_ sender: Any) {
        guard let pw = pwTextField.text else {
            
            setViewStatus(false)
            return
        }
        
        loginButtonAction(pw)
        
    }
    
    @IBAction func clickCloseButton(_ sender: Any) {
        self.removeFromSuperview()
        closeButtonAction()
    }
 
    private func loadXib() {
        
        let podBundle = Bundle(for: self.classForCoder)
        if let bundleURL = podBundle.url(forResource: "HejhomeSDKBase", withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                let identifier = String(describing: type(of: self))
                if let nib = UINib(nibName: identifier, bundle: bundle).instantiate(withOwner: self, options: nil).first as? UIView {
                    view = nib
                    self.view!.frame = self.bounds
                    addSubview(self.view!)
                    
                    pwTextField.delegate = self
                    pwTextField.isSecureTextEntry = true

                    setViewStatus(true)
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
                    self.addGestureRecognizer(tapGesture)
                }
             } else {
                assertionFailure("Could not load the bundle")
             }

        } else {
           assertionFailure("Could not create a path to the bundle")
        }
    }
    
    @objc func hideKeyboard() {
        self.endEditing(true)
    }
    
    func setViewStatus(_ status: Bool) {
        if !status {
            pwView.backgroundColor = UIColor(red: 194/225, green: 0/225, blue: 34/225, alpha: 1.0)
            errorView.isHidden = false
        } else {
            pwView.backgroundColor = UIColor(red: 121/225, green: 118/225, blue: 114/225, alpha: 1.0)
            errorView.isHidden = true
        }
    }
}

extension LoginView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.endEditing(true)
    }

}
