//
//  UserCheckModel.swift
//  HejhomeSDK
//
//  Created by Dasom Kim on 2023/06/27.
//

import Foundation


struct UserTokenInfo: Codable {
    var userToken: String = ""
}

class UserCheckModel: NSObject {
    
    var tokenInfo = UserTokenInfo()
    
    var successAction: ((UserTokenInfo)->())?
    var failAction: ((HejhomeLoginErrorCode) -> ())?
    
    var timer:Timer?
    var timeLeft: Int = 30
    
    override init() {
        super.init()
    }
}

extension UserCheckModel {
    
    func searchUserToken(uid: String, timeout: Int, complete: @escaping (UserTokenInfo) -> Void, fail: @escaping (HejhomeLoginErrorCode) -> Void) {
        
        let timeInSeconds = Int64(Date().timeIntervalSince1970 * 100)
        
        successAction = complete
        failAction = fail
        print("HejHomeSDK::: searchUserToken")
        
        self.tokenInfo = UserTokenInfo()
        self.timeLeft = timeout
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            
            self.timeLeft -= 1
            if self.timeLeft <= 0 {
                self.timer?.invalidate()
                self.timer = nil
                
                fail(.TIMEOUT)
                self.successAction = nil
                self.failAction = nil
            }
            
            self.getUserCheckData(uid: uid, complete: complete, fail: fail)
        })
    }
    
    func getUserCheckData(uid: String, complete: @escaping (UserTokenInfo) -> Void, fail: @escaping (HejhomeLoginErrorCode) -> Void){
        print("HejHomeSDK::: getUserToken \(GoqualConstants.PLATFORM_URL(HejhomeBase.shared.isDebug))\(GoqualConstants.API_THINQ_USER_CHECK)")
        API.shared.get(urlString: "\(GoqualConstants.PLATFORM_URL(HejhomeBase.shared.isDebug))\(GoqualConstants.API_THINQ_USER_CHECK)", uid: uid) { (response) in
            do {
                var tokenInfo = try UserTokenInfo.init(jsonDictionary: response)
                if !tokenInfo.userToken.isEmpty {
                    print("HejHomeSDK::: complete \(tokenInfo.userToken)")
                    self.timer?.invalidate()
                    self.timer = nil
                    complete(tokenInfo)
                    self.successAction = nil
                    self.failAction = nil
                } else {
                    print("HejHomeSDK::: search.. ")
                }
            } catch {
                print("HejHomeSDK::: search... ")
            }
        }
    }
    
    func cancel() {
        self.timeLeft = 0
        self.timer?.invalidate()
        self.timer = nil
        
        failAction?(.SDK_USER_CANCEL)
        self.successAction = nil
        self.failAction = nil
    }
}
