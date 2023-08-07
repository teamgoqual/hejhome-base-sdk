//
//  HejhomeBase.swift
//  ThingCameraSDKSampleApp
//
//  Created by Dasom Kim on 2023/04/11.
//

import Foundation
import ThingSmartBaseKit
import HejhomeSDKCommon

public enum HejhomeCameraType {
    case camera
    case doorbell
    case petfeeder
    case none
}

public protocol HejhomeBaseDelegate: AnyObject {
    func hejhomeLoginSuccess()
    func hejhomeLoginFailure(_ error: HejhomeLoginErrorCode)
}

public class HejhomeBase: NSObject {
    @objc public static let shared = HejhomeBase()
    
    public weak var delegate: HejhomeBaseDelegate?
    
    
    @objc public func setKey(appKey: String, secretKey: String) {
        User.shared.start(key: appKey, secret: secretKey)
    }
    
    public func setLgAccessCode(_ code: String, onSDKLoginSuccess: @escaping () -> Void, onSDKSetupCancelled: @escaping (HejhomeLoginErrorCode?) -> Void, needLogin: @escaping (String) -> Void) {
        User.shared.setLgAccessCode(code, onSDKLoginSuccess: onSDKLoginSuccess, onSDKSetupCancelled: onSDKSetupCancelled, needLogin: needLogin)
    }
    
    public func callNativeLoginView(_ userId: String, onSuccess: @escaping () -> Void, onFailure: @escaping (HejhomeLoginErrorCode?) -> Void){
        User.shared.callNativeLoginView(userId, onSDKLoginSuccess: onSuccess, onSDKSetupCancelled: onFailure)
    }
    
    public func testResetSessionData(complete: @escaping () -> Void, fail: @escaping (String) -> Void) {
        User.shared.logout(onComplete: complete, onFailure: fail)
    }
    
    public func setPuthToken(_ token: Data) {
        ThingSmartSDK.sharedInstance().deviceToken = token
    }
    
    public func sendRegisterCode(account: String, onSuccess: @escaping () -> Void, onFailure: @escaping (Error?) -> Void) {
        User.shared.sendVerificationCode(email: account, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    public func register(account: String, password: String, code: String, onSuccess: @escaping () -> Void, onFailure: @escaping (Error?) -> Void) {
        User.shared.register(email: account, password: password, code: code, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    public func login(account: String, password: String, timeout: Int = 30, onSuccess: @escaping () -> Void, onFailure: @escaping (HejhomeLoginErrorCode?) -> Void) {
        User.shared.login(account: account, password: password, timeout: timeout, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    public func cancelLogin() {
        User.shared.cancelLogin()
    }
    
    public func checkLogin() -> Bool {
        return User.shared.getLoginStatus()
    }
    
    public func getUserDevice(_ callback: @escaping ([HejhomeDeviceModel]) -> Void) {
        User.shared.getUserDevice(callback)
    }
    
    public func selectDevice(_ deviceId: String, onSuccess: @escaping () -> Void) {
        User.shared.selectDevice(deviceId: deviceId, onSuccess: onSuccess)
    }
    
    public func getCameraType(deviceId: String, complete: @escaping (HejhomeCameraType) -> Void, fail: @escaping (String) -> Void) {
        User.shared.getCameraType(deviceId: deviceId, complete: complete, fail: fail)
    }
}
