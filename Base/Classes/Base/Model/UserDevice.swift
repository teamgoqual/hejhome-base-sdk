//
//  UserDevice.swift
//  HejhomeSDK
//
//  Created by Dasom Kim on 2023/07/21.
//

import Foundation

struct UserDeviceInfo: Codable {
    var code: String = ""
    var result: ResultInfo?
    
    struct ResultInfo: Codable {
        var deviceId: String = ""
        var deviceType: String = ""
        var deviceName: String = ""
    }
}

class UserDeviceData: NSObject {
    
    override init() {
        super.init()
    }
}

extension UserDeviceData {
    static func getInfo(deviceId: String, complete: @escaping (UserDeviceInfo) -> Void, fail: @escaping (String) -> Void){
        print("HejHomeSDK::: getDevice")
        API.shared.get(urlString: "\(GoqualConstants.PLATFORM_URL(HejhomeBase.shared.isDebug))\(GoqualConstants.API_THINQ_DEVICE(deviceId))") { (response) in
            do {
                let device = try UserDeviceInfo.init(jsonDictionary: response)
                if !(device.result == nil) {
                    complete(device)
                } else {
                    fail("")
                }
            } catch {
                fail("\(error.localizedDescription) \n \(response)")
            }
        }
    }
}
