//
//  PairingDeviceModel.swift
//  HejhomeIpc
//
//  Created by Dasom Kim on 2023/05/24.
//

import Foundation

struct ProductIdList: Codable {
    var code: String = ""
    var result: ResultInfo?
    
    struct ResultInfo: Codable {
        var pidList: [String] = []
    }
}

public struct PairingDevice: Codable {
    @DefaultEmptyString var error_code: String = ""
    @DefaultEmptyString public var device_id: String = ""
    @DefaultEmptyString public var name: String = ""
    @DefaultEmptyString public var product_id: String = ""
    @DefaultEmptyString public var model_name: String = ""
    
    public init() {
        
    }
    
    init(_ error: PairingErrorCode) {
        error_code = String(error.rawValue)
    }
    
    public func pairingErrorCode() -> PairingErrorCode? {
        if error_code == "" {
            return nil
        }
        if let code = Int(self.error_code) {
            return PairingErrorCode(rawValue: code)
        } else {
            return .UNKNOWN
        }
    }
}

struct PairingDeviceResult: Codable {
    var code: String = ""
    var result: ResultInfo?
    
    struct ResultInfo: Codable {
        var failed: [PairingDevice]?
        var success: [PairingDevice]?
    }
    
    enum PairingDeviceResultKey: String, CodingKey {
        case code
        case result
    }
}

class PairingDeviceModel: NSObject {
    
    var productIdListModel = ProductIdList()
    var pairingDeviceResult = PairingDeviceResult()
    
    var successAction: ((PairingDevice)->())?
    var failAction: ((PairingDevice) -> ())?
    
    var timer:Timer?
    var timeLeft: Int = 30
    
    override init() {
        super.init()
    }
}

extension PairingDeviceModel {

    
    func getProductIdList(complete: @escaping ([String]) -> Void, fail: @escaping (String) -> Void){
        print("HejHomeSDK::: getProductIdList")
        API.shared.get(urlString: "\(GoqualConstants.PLATFORM_URL(HejhomeBase.shared.isDebug))\(GoqualConstants.GET_PRODUCT_ID_LIST)") { (response) in
            do {
                self.productIdListModel = try ProductIdList.init(jsonDictionary: response)
                print(response)
                if self.productIdListModel.result != nil {
                    complete(self.productIdListModel.result?.pidList ?? [])
                } else {
                    fail("")
                }
            } catch {
                fail("\(error.localizedDescription) \n \(response)")
            }
        }
            
    }
    
    func searchPairingDevice(_ token: String, timeout:Int, complete: @escaping (PairingDevice) -> Void, fail: @escaping (PairingDevice) -> Void) {
        
        let timeInSeconds = Int64(Date().timeIntervalSince1970 * 100)
        
        successAction = complete
        failAction = fail
        print("HejHomeSDK::: searchPairingDevice")
        
        var device = PairingDevice.init()
        self.timeLeft = timeout
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            
            self.timeLeft -= 1
            if self.timeLeft <= 0 {
                self.timer?.invalidate()
                self.timer = nil
                
                if let failedArray = self.pairingDeviceResult.result?.failed, !failedArray.isEmpty {
                    self.sendResult(fail, device: failedArray[0])
                } else {
                    if device.error_code.isEmpty {
                        device.error_code = String(PairingErrorCode.NOT_FOUND_PAIRING_DEVICE.rawValue)
                    }
                    self.sendResult(fail, device: device)
                }
            }
            
            API.shared.get(urlString: "\(GoqualConstants.PLATFORM_URL(HejhomeBase.shared.isDebug))\(GoqualConstants.PAIRING_STATUS(token))?pairingStartTime=\(String(timeInSeconds))") { (response) in
                print("HejHomeSDK::: searchPairingDevice \(self.timeLeft.description)")
                do {
                    self.pairingDeviceResult = try PairingDeviceResult.init(jsonDictionary: response)
                    if self.pairingDeviceResult.result != nil {
                        
                        if let successArray = self.pairingDeviceResult.result?.success, successArray.count > 0 {
                            self.sendResult(complete, device: successArray[0])
                            self.timer?.invalidate()
                            self.timer = nil
                        }
                        
                    } else if self.pairingDeviceResult.code == String(PairingErrorCode.DEVICE_TOKEN_EXPIRED.rawValue)
                                || self.pairingDeviceResult.code == String(PairingErrorCode.CHECK_REQ_INFORMATION.rawValue) {
                        device.error_code = self.pairingDeviceResult.code
                        self.sendResult(fail, device: device)
                        self.timer?.invalidate()
                        self.timer = nil
                    } else {
                        
                    }
                } catch {
//                    device.error_code = String(PairingErrorCode.MAIN_PAIRING_API_EXCEPTION.rawValue)
                }
            }
        })
    }
    
    func stopTimer(code: PairingErrorCode) {
        self.timeLeft = 0
        self.timer?.invalidate()
        self.timer = nil
        
        if failAction != nil {
            var device = PairingDevice.init()
            device.error_code = String(code.rawValue)
            self.sendResult(failAction!, device: device)
        }
    }
    
    func sendResult(_ block: @escaping (PairingDevice) -> Void, device: PairingDevice) {
        block(device)
        self.pairingDeviceResult = PairingDeviceResult.init()
        self.successAction = nil
        self.failAction = nil
    }
}
