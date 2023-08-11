//
//  LoginView.swift
//  HejhomeSDK
//
//  Created by Dasom Kim on 2023/06/28.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var pwTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    
    @IBOutlet weak var pwView: UIView!
    @IBOutlet weak var errorView: UIView!
    
    var loginButtonAction: (String) -> Void = { _ in }
    var closeButtonAction: () -> Void = {}
    
    var email: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setData(email: email)
        
        pwTextField.delegate = self
        setSwitchStatus(true)
        setViewStatus(true)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    func setData(email: String) {
        emailLabel.text = email
    }
    
    func setButtonImage(_ name: String) {
        if let bundlePath = Bundle.main.path(forResource: "HejhomeSDKBase", ofType: "bundle"),
            let bundle = Bundle(path: bundlePath),
            let image = UIImage(named: name, in: bundle, compatibleWith: nil) {
            // 이미지를 로드하여 사용할 수 있습니다.
            self.switchButton.setImage(image, for: .normal)
        } else {
            // 이미지를 로드할 수 없는 경우에 대한 처리를 여기에 추가합니다.
        }
    }
    
    func setSwitchStatus(_ status: Bool) {
        DispatchQueue.main.async {
            self.pwTextField.isSecureTextEntry = status
            if status {
                self.setButtonImage("secure-on")
            } else {
                self.setButtonImage("secure-off")
            }
        }
    }
    
    @IBAction func clickPwSwitchButton(_ sender: Any) {
        setSwitchStatus(!pwTextField.isSecureTextEntry)
        
    }
    
    @IBAction func clickLoginButton(_ sender: Any) {
        guard let pw = pwTextField.text else {
            setViewStatus(false)
            return
        }
        
        loginButtonAction(pw)
    }
    
    @IBAction func clickCloseButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        
        closeButtonAction()
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    func setViewStatus(_ status: Bool) {
        DispatchQueue.main.async {
            if !status {
                self.pwView.backgroundColor = UIColor(red: 194/225, green: 0/225, blue: 34/225, alpha: 1.0)
                self.errorView.isHidden = false
            } else {
                self.pwView.backgroundColor = UIColor(red: 121/225, green: 118/225, blue: 114/225, alpha: 1.0)
                self.errorView.isHidden = true
            }
        }
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Your implementation here
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        view.endEditing(true)
    }
}
