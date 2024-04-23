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
    
    var pairingMode: HejhomePairing.PairingMode = .AP
    var checkProcessing = false
    var isApiToken = false
    
    let model = PairingDeviceModel.init()
    
    //
    
    var pairingDeviceList: [PairingDevice] = []
    var pairingFailedDeviceList: [PairingDevice] = []
    
    var pairingSuccess = false
    var onPairingSuccess: (([PairingDevice]) -> Void)?
    var onPairingFailure: (([PairingDevice]) -> Void)?
    var onPairingComplete: (([PairingDevice], [PairingDevice]) -> Void)?
    
}


// Initialize
extension Pairing {
    func initialize(isDebug: Bool? = nil, onSuccess: (()->())? = nil, onFailure: ((PairingErrorCode)->())? = nil) {
        
        let completion: () -> Void = {
            if let isDebug = isDebug {
                HejhomeBase.shared.isDebug = isDebug
            }
            
            self.model.getProductIdList { arr in
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
        
        if User.shared.getLoginStatus() {
            completion()
        } else {
            User.shared.setDefaultUserData(completion: completion)
        }
    }
    
    func getPairingToken(onSuccess: @escaping ((String)->()), onFailure: @escaping  ((PairingErrorCode)->())) {
        guard let homeId = HejhomeHome.current?.homeId else { onFailure(.AUTO_PAIRING_FAIL_INITIAL); return }
        
        ThingSmartActivator.sharedInstance().getTokenWithHomeId(homeId) { result in
            guard let result = result, !result.isEmpty else { onFailure(.AUTO_PAIRING_TOKEN_EMPTY); return }
            onSuccess(result)
        } failure: { error in
            onFailure(.AUTO_PAIRING_TOKEN_FAIL)
        }
    }
    
    func stopConfig() {
        model.resetTimer()
        ThingSmartActivator.sharedInstance().stopConfigWiFi()
    }
    
    func startConfig(mode: ThingActivatorMode, ssid: String, password: String, token: String, timeout: TimeInterval = 100, timeoutMargin: TimeInterval = 0) {
        print("HejHomeSDK::: startConfig \(mode.rawValue) \(ssid) \(password) \(token) \(timeout)")
        
        if !User.shared.getLoginStatus() {
            print("HejHomeSDK::: startConfig login session Error")
        }
        
        // reset
        self.checkProcessing = false
        self.pairingSuccess = false
        self.model.resetTimer()
        
        // pairing
        ThingSmartActivator.sharedInstance().delegate = self
        ThingSmartActivator.sharedInstance().stopConfigWiFi()
        ThingSmartActivator.sharedInstance().startConfigWiFi(mode, ssid: ssid, password: password, token: token, timeout: timeout - timeoutMargin)

        print("HejHomeSDK::: startConfig \(self.onPairingSuccess != nil) \(self.isApiToken)")
        if self.onPairingSuccess != nil, self.isApiToken {
            self.devicePairingCheck(mode: mode, timeout: Int(timeout), timeoutMargin: Int(timeoutMargin))
        } else {
            self.checkProcessing = true
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
    
    func getPairingToken(onSuccess: @escaping (String, PairingErrorCode?) -> Void) {
        print("HejHomeSDK::: getPairingToken \(self.apiPairingToken)")
        if self.apiPairingToken.isEmpty {
            getPairingToken { token in
                self.isApiToken = false
                onSuccess(token, nil)
            } onFailure: { code in
                onSuccess("", code)
            }
        } else {
            self.isApiToken = true
            onSuccess(getDecodedToken(), nil)
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
    
    
    func devicePairingCheck(mode: ThingActivatorMode, timeout: Int, timeoutMargin: Int) {
        print("HejHomeSDK::: devicePairingCheck \(mode.rawValue) \(timeout)")
        
        if checkProcessing == true {
            
            var code: PairingErrorCode
            switch mode {
            case .AP: code = .PROCESSING_PAIRING_AP_MODE; break;
            case .EZ: code = .PROCESSING_PAIRING_EZ_MODE; break;
            case .qrCode: code = .PROCESSING_PAIRING_QR_MODE; break;
            default: code = .PROCESSING_PAIRING_AP_MODE; break;
            }
            
            let device = PairingDevice.init(code)
            self.sendPairingResult(false, device: [device])
            return
        }
        
        checkProcessing = true
        self.pairingDeviceCheck(mode:mode, timeout: timeout, timeoutMargin: timeoutMargin)
    }
    
    func pairingDeviceCheck(mode: ThingActivatorMode, timeout: Int, timeoutMargin: Int) {
        
        if let err = checkException() {
            let device = PairingDevice.init(err)
            self.checkProcessing = true
            self.sendPairingResult(false, device: [device])
            return
        }
        
        print("HejHomeSDK::: devicePairingCheck Start \(timeout)")
        model.searchPairingDevice(self.getToken(), mode: mode, timeout: timeout, timeoutMargin: timeoutMargin) { result, time in
            
            if time == 0 {
                self.pairingResultComplete()
            }
            
            if time == timeoutMargin {
                ThingSmartActivator.sharedInstance().stopConfigWiFi()
            }
            
            if mode == .EZ { self.checkProcessing = true }
            self.checkFoundPairingDevice(result)
            
        } fail: { err, time in
            
            if time == 0 {
                self.pairingResultComplete()
            }
            
            if time == timeoutMargin {
                ThingSmartActivator.sharedInstance().stopConfigWiFi()
            }
            
            var copylist: [PairingDevice] = []
            for device in err {
                var copy = device
                if copy.error_code.isEmpty {
                    copy.error_code = String(PairingErrorCode.MAIN_PAIRING_EXCEPTION.rawValue)
                }
                copylist.append(copy)
            }
            
            if mode == .EZ { self.checkProcessing = true }
            self.sendPairingResult(false, device: copylist)
        }
    }
    
    func checkFoundPairingDevice(_ result: [PairingDevice]) {
        
        var resultList: [PairingDevice] = []
        var failList: [PairingDevice] = []
        
        for device in result {
            if self.pidList.contains(device.product_id) {
                print("HejHomeSDK::: devicePairingCheck Success")
                resultList.append(device)
            } else {
                let code = PairingErrorCode.NOT_SUPPORT_PAIRING_DEVICE
                var copyResult = device
                copyResult.error_code = String(code.rawValue)
                failList.append(copyResult)
            }
        }
        
        if failList.count > 0 {
            self.sendPairingResult(false, device: failList)
        }
        
        if resultList.count > 0 {
            self.sendPairingResult(true, device: resultList)
        }
    }
    
    func sendPairingResult(_ status: Bool, device: [PairingDevice]) {
        print("HejHomeSDK::: sendPairingResult \(status)")
        
        if checkProcessing == true {
            checkProcessing = false
            
            if self.pairingMode != .EASY {
                stopConfig()
            }
            print("HejHomeSDK::: sendPairingResult stopConfigWiFi")
            if status == true {
                pairingResultSuccess(device)
            } else {
                pairingResultFailure(device)
            }
        }
    }
    
    func pairingResultSuccess(_ device: [PairingDevice]) {
        print("HejHomeSDK::: sendPairingResult success")
        
        if let success = self.onPairingSuccess, pairingDeviceList != device {
            pairingDeviceList = device
            pairingSuccess = true
            print("HejHomeSDK::: sendPairingResult success in")
            DispatchQueue.main.async {
                success(device)
            }
        }
    }
    
    func pairingResultFailure(_ device: [PairingDevice]) {
        print("HejHomeSDK::: sendPairingResult failure")
        if let fail = self.onPairingFailure, pairingSuccess == false, pairingFailedDeviceList != device {
            pairingFailedDeviceList = device
            print("HejHomeSDK::: sendPairingResult failure in")
            DispatchQueue.main.async {
                fail(device)
            }
        }
    }
    
    func pairingResultComplete() {
        let delayInSeconds: Double = 0.5
        let delayTime = DispatchTime.now() + delayInSeconds

        stopConfig()
        
        print("HejHomeSDK::: sendPairingResult complete")
        if let complete = self.onPairingComplete {
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                complete(self.pairingDeviceList, self.pairingFailedDeviceList)
                self.pairingDeviceList = []
            }
        }
    }
}

extension Pairing {
    
    func devicePairing(ssidName: String, ssidPw: String, pairingToken: String, timeout:Int = 120, timeoutMargin:Int = 0, mode: HejhomePairing.PairingMode = .AP) {
        print("HejHomeSDK::: devicePairing \(ssidName) \(ssidPw) \(pairingToken)")
        self.apiPairingToken = pairingToken
        self.ssidName = ssidName
        self.ssidPw = ssidPw
        self.pairingMode = mode
        
        self.startPairingAction(mode: mode, timeout: timeout, timeoutMargin: timeoutMargin)
    }
    
    
    
    func startPairingAction(mode: HejhomePairing.PairingMode, timeout: Int = 100, timeoutMargin:Int = 0) {
        print("HejHomeSDK::: startPairing \(mode)")
        print("HejHomeSDK::: getPairingToken \(self.apiPairingToken)")

        
        self.pairingDeviceList = []
        self.pairingMode = mode
        
        if let err = checkException() {
            let device = PairingDevice.init(err)
            self.checkProcessing = true
            self.sendPairingResult(false, device: [device])
            return
        }
        
        let mode = (mode == .AP) ? ThingActivatorMode.AP : ThingActivatorMode.EZ;
        
        getPairingToken { token, error in
            print("HejHomeSDK::: getPairingToken in \(token)")
            
            guard error == nil else {
                let device = PairingDevice.init(error ?? .UNKNOWN)
                self.checkProcessing = true
                self.sendPairingResult(false, device: [device])
                return
            }
            
            self.startConfig(mode:mode, ssid: self.ssidName, password: self.ssidPw, token: token, timeout: TimeInterval(timeout), timeoutMargin: TimeInterval(timeoutMargin))
        }
    }
    
    func stopDevicePairing() {
        print("HejHomeSDK::: stopDevicePairing")
        
        stopConfig()
        
        if checkProcessing == true {
            model.stopTimer(code: .STOP_PROCESSING_PAIRING)
        } else {
            let device = PairingDevice.init(.STOP_PROCESSING_PAIRING)
            self.sendPairingResult(false, device: [device])
        }
    }
    
    func devicePairingCheck(pairingToken: String, timeout: Int = 30) {
        print("HejHomeSDK::: devicePairingCheck")
        
        self.apiPairingToken = pairingToken
        self.scanDevice(timeout: timeout)
    }
    
    func scanDevice(timeout: Int = 30) {
        
        if onPairingSuccess != nil {
            self.devicePairingCheck(mode:.AP, timeout: timeout, timeoutMargin: 0)
        }
    }
}

extension Pairing: ThingSmartActivatorDelegate {
    func activator(_ activator: ThingSmartActivator!, didReceiveDevice deviceModel: ThingSmartDeviceModel!, error: Error!) {
        
        guard !isApiToken else { return }
        
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
            
            self.sendPairingResult(false, device: [device])
            return
        }
    }
    
    func activator(_ activator: ThingSmartActivator!, didDiscoverWifiList wifiList: [Any]!, error: Error!) {
        print("HejHomeSDK::: didDiscoverWifiList")
    }
    
    func activator(_ activator: ThingSmartActivator!, didReceiveDevice deviceModel: ThingSmartDeviceModel?, step: ThingActivatorStep, error: Error!) {
        
        guard !isApiToken else { return }
        
        print("HejHomeSDK::: didReceiveDevice:step:error")
        
        var device = PairingDevice()

        guard let deviceModel = deviceModel, !deviceModel.devId.isEmpty else { return }

        device.device_id = deviceModel.devId
        device.model_name = deviceModel.name
        device.name = deviceModel.name
        device.product_id = deviceModel.productId

        if let error = error {
            device.error_code = String(PairingErrorCode.AUTO_PAIRING_FAIL.rawValue)
            self.sendPairingResult(false, device: [device])
            return
        }

        checkFoundPairingDevice([device])
    }
    
    func activator(_ activator: ThingSmartActivator!, didPassWIFIToSecurityLevelDeviceWithUUID uuid: String!) {
        print("HejHomeSDK::: didPassWIFIToSecurityLevelDeviceWithUUID")
    }
    
    func activator(_ activator: ThingSmartActivator!, didFindGatewayWithDeviceId deviceId: String!, productId: String!) {
        print("HejHomeSDK::: didFindGatewayWithDeviceId")
    }
}
