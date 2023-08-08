//
//  Pairing.swift
//  ThingCameraSDKSampleApp
//
//  Created by Dasom Kim on 2023/04/11.
//

import Foundation
import ThingSmartActivatorKit
import HejhomeSDKCommon

class Pairing: NSObject {
    
    static let shared = Pairing()
    
    var pidList: [String] = []
    
    var ssidName = ""
    var ssidPw = ""
    var apiPairingToken = ""
    
    var checkProcessing = false
    var isApiToken = false
    
    let model = PairingDeviceModel.init()
    
    //
    
    var onPairingSuccess: ((PairingDevice) -> Void)?
    var onPairingFailure: ((PairingDevice) -> Void)?
    
}


// Initialize
extension Pairing {
    func initialize(isDebug: Bool = false, onSuccess: (()->())? = nil, onFailure: ((PairingErrorCode)->())? = nil) {
        HejhomeBase.shared.isDebug = isDebug
        
        model.getProductIdList { arr in
            print("HejHomeSDK::: initializeData Succuess")
            self.pidList = arr
            DispatchQueue.main.async {
                if let success = onSuccess {
                    success()
                }
            }
        } fail: { err in
            print("HejHomeSDK::: initializeData Error \(err)")
            DispatchQueue.main.async {
                if let onFailure = onFailure {
                    onFailure(.INTERNAL_SERVER_ERROR)
                }
            }
        }
    }
    
    func getPairingToken(onSuccess: @escaping ((String)->()), onFailure: @escaping  ((PairingErrorCode)->())) {
        guard let homeId = HejhomeHome.current?.homeId else { return }
        
        ThingSmartActivator.sharedInstance().getTokenWithHomeId(homeId) { result in
            guard let result = result, !result.isEmpty else { onFailure(.AUTO_PAIRING_TOKEN_EMPTY); return }
            onSuccess(result)
        } failure: { error in
            onFailure(.AUTO_PAIRING_TOKEN_FAIL)
        }
    }
    
    func startConfig(mode: ThingActivatorMode, ssid: String, password: String, token: String, timeout: TimeInterval = 100) {
        
        if !User.shared.getLoginStatus() {
            User.shared.setDefaultUserData()
        }
        
        ThingSmartActivator.sharedInstance().delegate = self
        ThingSmartActivator.sharedInstance().startConfigWiFi(mode, ssid: ssid, password: password, token: token, timeout: timeout)
        
        if self.onPairingSuccess != nil, isApiToken {
            self.devicePairingCheck(timeout: Int(timeout))
        } else {
            checkProcessing = true
        }
    }
}

extension Pairing {
    func pairingCodeImage(ssid: String, password: String, token: String = "", size: Int, onSuccess: @escaping (UIImage?) -> Void, onFailure: @escaping (Error?) -> Void) {
        
        if (token.isEmpty) {
            generateQRCode(ssid: ssid, password: password, size: size, completionHandler: onSuccess, failureHandler: onFailure)
        } else {
            isApiToken = true
            self.apiPairingToken = token
            startQrConfig(getDecodedToken(), ssid: ssid, password: password, size: size, completionHandler: onSuccess)
        }
        
        
    }
    
    func generateQRCode(ssid: String, password: String, size: Int, timeout: TimeInterval = 100, completionHandler: @escaping (UIImage?) -> Void, failureHandler: @escaping (Error?) -> Void) {
        
        guard let homeId = HejhomeHome.current?.homeId else { failureHandler(nil); return }
        
        ThingSmartActivator.sharedInstance().getTokenWithHomeId(homeId) { result in
            let token = result ?? ""
            self.isApiToken = false
            self.startQrConfig(token, ssid: ssid, password: password, size: size, completionHandler: completionHandler)
                        
        } failure: { error in
            //
            failureHandler(error)
        }
        
    }
    
    func startQrConfig(_ token: String, ssid: String, password: String, size: Int, timeout: TimeInterval = 100, completionHandler: @escaping (UIImage?) -> Void) {
        let dictionary: [String: Any] = ["s": ssid, "p": password, "t": token]
        let jsonData = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
        let wifiJsonStr = String(data: jsonData, encoding: .utf8)!

        let image = UIImage.ty_qrCode(with: wifiJsonStr, width: CGFloat(size))
        
        self.startConfig(mode:.qrCode, ssid: ssid, password: password, token: token, timeout: timeout)
        completionHandler(image)
    }
    
}

// token
extension Pairing {
    
    func getPairingToken(onSuccess: @escaping (String) -> Void) {
        if self.apiPairingToken.isEmpty {
            getPairingToken { token in
                self.isApiToken = false
                onSuccess(token)
            } onFailure: { code in
                onSuccess("")
            }
        } else {
            self.isApiToken = true
            onSuccess(getDecodedToken())
        }
    }
    
    func getDecodedToken() -> String {
        let token = self.apiPairingToken
        let base64DecString = token.fromBase64()
        let arr = base64DecString?.split(separator: "-")
        if arr?.count == 3 {
            let region = arr![0]
            let secret = arr![1]
            let token = arr![2]

            return "\(region)\(token)\(secret)"
        }
        
        return ""
    }
    
    func getToken() -> String {
        let token = self.apiPairingToken
        
        let base64DecString = token.fromBase64()
        
        let arr = base64DecString?.split(separator: "-")
        if arr?.count == 3 {
            let token = arr![2]
            
            return "\(token)"
        }
        
        return ""
    }
    
}


// Pairing
extension Pairing {
    
    func checkException() -> PairingErrorCode? {
        guard self.pidList.count > 0 else {
            return .NOT_INITIALIZE
        }
        
//        guard self.apiPairingToken.count > 0 else { // 토큰 체크
//            return .PAIRING_TOKEN_PARSING_ERROR
//        }
        
        return nil
    }
    
    
    func devicePairingCheck(timeout: Int) {
        print("HejHomeSDK::: devicePairingCheck")
        
        if checkProcessing == true {
            let device = PairingDevice.init(.PROCESSING_PAIRING_AP_MODE)
            self.sendPairingResult(false, device: device)
            return
        }
        
        checkProcessing = true
        self.pairingDeviceCheck(timeout: timeout)
    }
    
    func pairingDeviceCheck(timeout: Int) {
        
        if let err = checkException() {
            let device = PairingDevice.init(err)
            self.checkProcessing = true
            self.sendPairingResult(false, device: device)
            return
        }
        
        print("HejHomeSDK::: devicePairingCheck Start")
        model.searchPairingDevice(self.getToken(), timeout: timeout) { result in
            //
            self.checkFoundPairingDevice(result)
            
        } fail: { err in
            var copyResult = err
            if copyResult.error_code.isEmpty {
                copyResult.error_code = String(PairingErrorCode.MAIN_PAIRING_EXCEPTION.rawValue)
            }
            self.sendPairingResult(false, device: copyResult)
        }
    }
    
    func checkFoundPairingDevice(_ result: PairingDevice) {
        if self.pidList.contains(result.product_id) {
            print("HejHomeSDK::: devicePairingCheck Success")
            self.sendPairingResult(true, device: result)
        } else {
            let code = PairingErrorCode.NOT_SUPPORT_PAIRING_DEVICE
            var copyResult = result
            copyResult.error_code = String(code.rawValue)
            self.sendPairingResult(false, device: copyResult)
        }

    }
    
    func sendPairingResult(_ status: Bool, device: PairingDevice) {
        if checkProcessing == true {
            checkProcessing = false
            
            ThingSmartActivator.sharedInstance().stopConfigWiFi()
            if status == true {
                if let success = self.onPairingSuccess {
                    DispatchQueue.main.async {
                        success(device)
                    }
                }
            } else {
                if let fail = self.onPairingFailure {
                    DispatchQueue.main.async {
                        fail(device)
                    }
                }
            }
        }
    }
}

extension Pairing {
    
    func devicePairing(ssidName: String, ssidPw: String, pairingToken: String, timeout:Int = 120, mode: HejhomePairing.PairingMode = .AP) {
        print("HejHomeSDK::: devicePairing \(ssidName) \(ssidPw) \(pairingToken)")
        self.apiPairingToken = pairingToken
        self.ssidName = ssidName
        self.ssidPw = ssidPw
        
        self.startPairingAction(mode: mode, timeout: timeout)
    }
    
    
    
    func startPairingAction(mode: HejhomePairing.PairingMode, timeout: Int = 100) {
        print("HejHomeSDK::: startPairing")

        if let err = checkException() {
            let device = PairingDevice.init(err)
            self.checkProcessing = true
            self.sendPairingResult(false, device: device)
            return
        }
        
        let mode = (mode == .AP) ? ThingActivatorMode.AP : ThingActivatorMode.EZ;
        
        getPairingToken { token in
            self.startConfig(mode:mode, ssid: self.ssidName, password: self.ssidPw, token: token, timeout: TimeInterval(timeout))
        }
    }
    
    func stopDevicePairing() {
        print("HejHomeSDK::: stopDevicePairing")
        
        if checkProcessing == true {
            model.stopTimer(code: .STOP_PROCESSING_PAIRING)
        } else {
            let device = PairingDevice.init(.STOP_PROCESSING_PAIRING)
            self.sendPairingResult(false, device: device)
        }
    }
    
    func devicePairingCheck(pairingToken: String, timeout: Int = 30) {
        print("HejHomeSDK::: devicePairingCheck")
        
        self.apiPairingToken = pairingToken
        self.scanDevice(timeout: timeout)
    }
    
    func scanDevice(timeout: Int = 30) {
        
        if onPairingSuccess != nil {
            self.devicePairingCheck(timeout: timeout)
        }
    }
}

extension Pairing {
    func successAction(_ device: PairingDevice) {
        
//        self.delegate?.hejhomePairingSuccess(device)
        onPairingSuccess?(device)
    }
    
    func failAction(_ device: PairingDevice) {
        
//        self.delegate?.hejhomePairingFailure(device)
        onPairingFailure?(device)
    }
}

extension Pairing: ThingSmartActivatorDelegate {
    func activator(_ activator: ThingSmartActivator!, didReceiveDevice deviceModel: ThingSmartDeviceModel!, error: Error!) {
        print("HejHomeSDK::: didReceiveDevice:error:")
        
        if let error = error {
            
            var device = PairingDevice()

            device.device_id = ""
            device.model_name = ""
            device.name = ""
            device.product_id = ""
            
            let errorCode = (error as NSError).code as Int
            
            switch errorCode {
            case 1512:
                device.error_code = String(PairingErrorCode.AUTO_PAIRING_FAIL_TIMEOUT.rawValue)
            default:
                device.error_code = String(PairingErrorCode.AUTO_PAIRING_FAIL_UNKNOWN.rawValue)
            }

            self.sendPairingResult(false, device: device)
            return
        }
    }
    
    func activator(_ activator: ThingSmartActivator!, didDiscoverWifiList wifiList: [Any]!, error: Error!) {
        print("HejHomeSDK::: didDiscoverWifiList")
    }
    
    func activator(_ activator: ThingSmartActivator!, didReceiveDevice deviceModel: ThingSmartDeviceModel?, step: ThingActivatorStep, error: Error!) {
        print("HejHomeSDK::: didReceiveDevice:step:error")
        var device = PairingDevice()

        guard let deviceModel = deviceModel, !deviceModel.devId.isEmpty else { return }

        device.device_id = deviceModel.devId
        device.model_name = deviceModel.name
        device.name = deviceModel.name
        device.product_id = deviceModel.productId

        if let error = error {
            device.error_code = String(PairingErrorCode.AUTO_PAIRING_FAIL.rawValue)
            self.sendPairingResult(false, device: device)
            return
        }

        checkFoundPairingDevice(device)
    }
    
    func activator(_ activator: ThingSmartActivator!, didPassWIFIToSecurityLevelDeviceWithUUID uuid: String!) {
        print("HejHomeSDK::: didPassWIFIToSecurityLevelDeviceWithUUID")
    }
    
    func activator(_ activator: ThingSmartActivator!, didFindGatewayWithDeviceId deviceId: String!, productId: String!) {
        print("HejHomeSDK::: didFindGatewayWithDeviceId")
    }
}
