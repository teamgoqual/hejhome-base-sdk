//
//  UserData.swift
//  HejhomeSDK
//
//  Created by Dasom Kim on 2023/06/27.
//

import Foundation

struct UserInfo: Codable {
    var uid: String = ""
    var userName: String?
    var eventToken: String?
    var sessionInfo: String = ""
}

class UserData: NSObject {
    
    override init() {
        super.init()
    }
}

extension UserData {
        
    static func getUserId(lgAccessCode: String, complete: @escaping (UserInfo) -> Void, fail: @escaping (String) -> Void){
        print("HejHomeSDK::: getUser \(GoqualConstants.PLATFORM_URL(HejhomeBase.shared.isDebug))\(GoqualConstants.API_THINQ_USER)")
        API.shared.get(urlString: "\(GoqualConstants.PLATFORM_URL(HejhomeBase.shared.isDebug))\(GoqualConstants.API_THINQ_USER)", lgAccessCode: lgAccessCode) { (response) in
            do {
                var userInfo = try UserInfo.init(jsonDictionary: response)
                if !userInfo.uid.isEmpty {
                    print("HejHomeSDK::: complete \(userInfo.uid) \(userInfo.userName ?? "()") \(userInfo.sessionInfo)")
                    complete(userInfo)
                } else {
                    print("HejHomeSDK::: fail ()")
                    fail("")
                }
            } catch {
                print("HejHomeSDK::: fail \(error.localizedDescription) \(response)")
                fail("\(error.localizedDescription) \n \(response)")
            }
        }
    }
    
    static func updateUserData(param: UserInfo, complete: @escaping () -> Void, fail: @escaping (String) -> Void){
        print("HejHomeSDK::: updateUserData \(GoqualConstants.PLATFORM_URL(HejhomeBase.shared.isDebug))\(GoqualConstants.API_THINQ_USER)")
        
//        let param = UserInfo(uid: uid, userName: userName, eventToken: lgAccessCode, sessionInfo: sessionInfo)
        
        API.shared.post(urlString: "\(GoqualConstants.PLATFORM_URL(HejhomeBase.shared.isDebug))\(GoqualConstants.API_THINQ_USER)", parameter: param, lgAccessCode: param.eventToken) { (response) in
            do {
                if let errorCode = response["errorCode"] as? Int {
                    print("HejHomeSDK::: fail code - \(errorCode)")
                    fail("Error Code: \(errorCode)")
                } else {
                    print("HejHomeSDK::: complete 200")
                    complete()
                }
                
            } catch {
                print("HejHomeSDK::: fail \(error.localizedDescription)")
                fail("\(error.localizedDescription) \n \(response)")
            }
        }
    }
    
    static func deleteUserData(uid: String, complete: @escaping () -> Void, fail: @escaping (String) -> Void){
        print("HejHomeSDK::: deleteUser \(GoqualConstants.PLATFORM_URL(HejhomeBase.shared.isDebug))\(GoqualConstants.API_THINQ_USER)")
        
        API.shared.delete(urlString: "\(GoqualConstants.PLATFORM_URL(HejhomeBase.shared.isDebug))\(GoqualConstants.API_THINQ_USER)", path: uid) { (response) in
            do {
                if let errorCode = response["errorCode"] as? Int {
                    print("HejHomeSDK::: fail code - \(errorCode)")
                    fail("Error Code: \(errorCode)")
                } else {
                    print("HejHomeSDK::: complete 200")
                    complete()
                }
            } catch {
                print("HejHomeSDK::: fail \(error.localizedDescription)")
                fail("\(error.localizedDescription) \n \(response)")
            }
        }
    }
    
}
