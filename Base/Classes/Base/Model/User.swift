//
//  LoginManager.swift
//  ThingCameraSDKSampleApp
//
//  Created by Dasom Kim on 2023/04/11.
//

import Foundation
import ThingSmartBaseKit
import ThingSmartDeviceKit
import HejhomeSDKCommon

class User: NSObject {
    
    // MARK: - Property
    var home: ThingSmartHome?
    let homeManager = ThingSmartHomeManager()
    var cameraListCallback: (([HejhomeDeviceModel]) -> Void)?
    var homeList: [ThingSmartHomeModel] = []
    var listIndex = 0
    var allDeviceList: [HejhomeDeviceModel] = []
    let usercheck = UserCheckModel()
    
    static let shared = User()
    
    var appkey = ""
    var secretkey = ""
    var accessCode = ""
    var account = ""
    
    func getLoginStatus() -> Bool {
        return ThingSmartUser.sharedInstance().isLogin
    }
    
    func start(key: String, secret: String) {
        ThingSmartSDK.sharedInstance().start(withAppKey: key, secretKey: secret)
        appkey = key
        secretkey = secret
        
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            let sdkAccessCode = bundleIdentifier.toBase64()
            API.shared.setSdkAccessCode(sdkAccessCode)
        }
    }
    
    func setLgAccessCode(_ code: String, onSDKLoginSuccess: @escaping () -> Void, onSDKSetupCancelled: @escaping (HejhomeLoginErrorCode?) -> Void, needLogin: @escaping (String) -> Void) {
        guard !code.isEmpty else { onSDKSetupCancelled(.SDK_EMPTY_TOKEN); return }
        
        accessCode = code
        UserData.getUserId(lgAccessCode: code) { info in
            if !info.sessionInfo.isEmpty {
                if User.shared.getLoginStatus() == true, ThingSmartUser.sharedInstance().uid == info.uid {
                    onSDKLoginSuccess()
                    return
                }
                
                User.shared.setSavedUserData(info, onSDKLoginSuccess: onSDKLoginSuccess, onSDKSetupCancelled: onSDKSetupCancelled)
            } else if let userName = info.userName, !userName.isEmpty {
                needLogin(userName)
            }
        } fail: { error in
            print(error)
            if User.shared.getLoginStatus() == true {
                ThingSmartUser.sharedInstance().reset(userInfo:[:], source: 0)
            }
            onSDKSetupCancelled(.SDK_EMPTY_ACCOUNT_LINK)
        }
    }
    
    func reset() {
        accessCode = ""
        account = ""
    }
    
    func testResetSessionData(complete: @escaping () -> Void, fail: @escaping (String) -> Void) {
        let user = ThingSmartUser.sharedInstance()
        UserData.updateUserData(lgAccessCode:User.shared.accessCode, uid: user.uid, userName: nil, sessionInfo: "") {
            complete()
        } fail: { error in
            fail(error)
        }
    }
    
    func setSavedUserData(_ info: UserInfo, onSDKLoginSuccess: @escaping () -> Void, onSDKSetupCancelled: @escaping (HejhomeLoginErrorCode?) -> Void) {
        guard !info.sessionInfo.isEmpty else { return }
        
        let session = Crypto().decrypt(info.sessionInfo)
        
        if let jsonData = session.data(using: .utf8) {
            do {
                if var dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    print(dictionary)
                    dictionary.updateValue(true, forKey: "isLogin")
                    ThingSmartUser.sharedInstance().reset(userInfo: dictionary, source: 0)
                    
                    self.start(key: self.appkey, secret: self.secretkey)
                    HejhomeBase.shared.getUserDevice { list in
                        onSDKLoginSuccess()
                    }
                }
            } catch {
                print("Error: \(error.localizedDescription)")
                onSDKSetupCancelled(.SDK_WRONG_SESSION_DATA)
            }
        }
    }
    
    func callNativeLoginView(_ email: String, onSDKLoginSuccess: @escaping () -> Void, onSDKSetupCancelled: @escaping (HejhomeLoginErrorCode?) -> Void) {
        DispatchQueue.main.async {
            let podBundle = Bundle(for: self.classForCoder)
            var startLogin = false
            if let bundleURL = podBundle.url(forResource: "HejhomeSDKBase", withExtension: "bundle") {
                if let bundle = Bundle(url: bundleURL) {
                    let login = LoginViewController(nibName: "LoginView", bundle: bundle)
                    login.modalPresentationStyle = .fullScreen // 전체 화면으로 표시
                    
                    // 필요한 설정을 진행
                    login.email = email
                    login.loginButtonAction = { pw in
                        guard startLogin == false else { return }
                        
                        startLogin = true
                        User.shared.login(account: email, password: pw, timeout: 30) {
                            startLogin = false
                            onSDKLoginSuccess()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                                login.dismiss(animated: false)
                            })
                        } onFailure: { error in
                            startLogin = false
                            DispatchQueue.main.async {
                                login.setViewStatus(false)
                            }
                        }
                    }
                    login.closeButtonAction = {
                        onSDKSetupCancelled(.SDK_USER_CANCEL)
                    }
                    
                    // 화면 표시
                    getMostTopViewController()?.present(login, animated: false)
                 } else {
                    
                 }

            } else {
               
            }
        }
    }
    
    func login(account: String, password: String, timeout: Int, onSuccess: @escaping () -> Void, onFailure: @escaping (HejhomeLoginErrorCode?) -> Void) {
        let countryCode = "82"
        
        self.account = account
        if account.isValidEmail() {
            ThingSmartUser.sharedInstance().login(byEmail: countryCode,
                                                  email: account,
                                                  password: password) { [weak self] in
                guard let self = self else { return }
                self.afterSdkLogin(timeout: timeout, onSuccess: onSuccess, onFailure: onFailure)
                
            } failure: { [weak self] (error) in
                guard let _ = self else { return }
                
                onFailure(.SDK_EMAIL_LOGIN_FAIL)
            }
        } else {
            
            ThingSmartUser.sharedInstance().login(byPhone: countryCode, phoneNumber: account, password: password) { [weak self] in
                guard let self = self else { return }
                self.afterSdkLogin(timeout: timeout, onSuccess: onSuccess, onFailure: onFailure)
                
            } failure: { [weak self] (error) in
                guard let _ = self else { return }
                
                onFailure(.SDK_PHONE_LOGIN_FAIL)
            }
        }
        
        
    }
    
    func cancelLogin() {
        self.usercheck.cancel()
    }
    
    func afterSdkLogin(timeout: Int, onSuccess: @escaping () -> Void, onFailure: @escaping (HejhomeLoginErrorCode?) -> Void) {
        
        userCheckAfterLogin(uid: ThingSmartUser.sharedInstance().uid, timeout: timeout, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    func updateSessionData(onSuccess: @escaping () -> Void, onFailure: @escaping (HejhomeLoginErrorCode?) -> Void) {
        let user = UserConverter(fromThingUser: ThingSmartUser.sharedInstance())
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(user) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                let encodedString = Crypto().encrypt(jsonString)
                UserData.updateUserData(lgAccessCode:User.shared.accessCode, uid: user.uid, userName:self.account, sessionInfo: encodedString) {
                    print("HejhomeSDK::: login success")
                    onSuccess()
                } fail: { error in
                    print(error)
                    print("HejhomeSDK::: 세션 데이터 업데이트 오류")
                    onFailure(.SDK_SESSION_UPDATE_FAIL)
                }
                
            }
        }
    }
    
    func userCheckAfterLogin(uid: String, timeout: Int, onSuccess: @escaping () -> Void, onFailure: @escaping (HejhomeLoginErrorCode?) -> Void) {
        
        if User.shared.accessCode != "", !User.shared.accessCode.isEmpty {
            self.updateSessionData {
                onSuccess()
            } onFailure: { error in
                onFailure(error)
            }
            return
        }
        
        usercheck.searchUserToken(uid: uid, timeout: timeout) { tokenInfo in
            guard !tokenInfo.userToken.isEmpty else { onFailure(.SDK_EMPTY_TOKEN); return }
            
            User.shared.accessCode = tokenInfo.userToken
            self.updateSessionData {
                onSuccess()
            } onFailure: { error in
                onFailure(error)
            }
        } fail: { code in
            onFailure(.SDK_TOKEN_ERROR)
        }
    }
    
    func checkUpdatedSessionData(onSuccess: @escaping () -> Void, onFailure: @escaping (HejhomeLoginErrorCode?) -> Void) {
        UserData.getUserId(lgAccessCode: User.shared.accessCode) { info in
            if info.uid == ThingSmartUser.sharedInstance().uid {
                onSuccess()
            } else {
                print("HejhomeSDK::: 잘못된 아이디 접근")
                onFailure(.SDK_SESSION_UPDATE_FAIL)
            }
            
        } fail: { error in
            print(error)
            print("HejhomeSDK::: 세션 데이터 체크 오류")
            onFailure(.SDK_SESSION_UPDATE_FAIL)
        }
    }
    
    func logout(onComplete: @escaping () -> Void, onFailure: @escaping (String) -> Void) {
        UserData.deleteUserData(uid: ThingSmartUser.sharedInstance().uid) {
            ThingSmartUser.sharedInstance().loginOut {
                onComplete()
            }
        } fail: { error in
            print(error)
            onFailure(error.description)
        }
    }
    
    func setDefaultUserData() {
        ThingSmartUser.sharedInstance().reset(userInfo: ["sid": "az164785J5247000lnUwfvb3a86927a7f4a7c7cd86fc9de6e1e3e62f",
                                                         "uid": "az1647855247000lUwfv",
                                                         "isLogin": false,
                                                         "domain": ["mobileApiUrl": "https://a1.tuyaus.com"],
                                                         "ecode": "z2z845J727145aaa"], source: 0)
    }
    
    func sendVerificationCode(email: String, onSuccess: @escaping () -> Void, onFailure: @escaping (Error?) -> Void) {
        let countryCode = "82"
        ThingSmartUser.sharedInstance().sendVerifyCode(withUserName: email, region: nil, countryCode: countryCode, type: 1) {
            //Verification Code Sent Successfully
            onSuccess()
        } failure: { [weak self] (error) in
            //Failed to Register
            guard let _ = self else { return }
            
            onFailure(error)
        }
    }
    
    func register(email: String, password: String, code: String, onSuccess: @escaping () -> Void, onFailure: @escaping (Error?) -> Void) {
        let countryCode = "82"
        ThingSmartUser.sharedInstance().register(byEmail: countryCode, email: email, password: password, code: code, success: {
            // Registered Successfully
            onSuccess()
        }, failure: { [weak self] (error) in
            //Failed to Register
            guard let _ = self else { return }
            
            onFailure(error)
        })
    }
}

extension User {
    
    // 현재 유저 기준 전체 디바이스 불러오기
    func getUserDevice(_ callback: @escaping (([HejhomeDeviceModel]) -> Void)) {
        cameraListCallback = callback
        getHomeList {
            self.getAllDeviceList()
        }
    }
    
    // current device 선택
    func selectDevice(deviceId: String, onSuccess: @escaping () -> Void) {
        
        // 로컬에 저장된 디바이스 전체 리스트를 불러온다 (리스트를 통해 홈, 디바이스 탐색)
        if allDeviceList.isEmpty, let all = HejhomeDevice.all {
            allDeviceList = all
        }
        
        findHomeIndex(deviceId) {
            onSuccess()
        }
    }
    
    func findHomeIndex(_ deviceId: String, onSuccess: @escaping () -> Void) {
        if let foundDevice = allDeviceList.first(where: { $0.deviceId == deviceId }) {
            selectHome(homeId: foundDevice.homeId) {
                self.findDevice(deviceId: deviceId, onSuccess: onSuccess)
            }
        } else {
            getUserDevice { list in
                self.findHomeIndex(deviceId, onSuccess: onSuccess)
            }
        }
    }
    
    func selectHome(homeId: Int64, callback: @escaping () -> Void) {
        if HejhomeHome.current != nil, HejhomeHome.homeId == homeId {
            callback()
            return
        }
        
        getHomeList {
            HejhomeHome.homeId = homeId
            callback()
        }
        
    }
    
    func findDevice(deviceId: String, onSuccess: @escaping () -> Void) {
        if HejhomeDevice.current != nil, HejhomeDevice.deviceId == deviceId {
            onSuccess()
            return
        }
        
        getDeviceListByHome { model in
            HejhomeDevice.deviceId = deviceId
            onSuccess()
        }
    }
    
    func getDeviceListByHome(_ callback: @escaping ((ThingSmartHomeModel?) -> Void)) {
        
        if HejhomeHome.current != nil {
            home = ThingSmartHome(homeId: HejhomeHome.current!.homeId)
            home?.delegate = self
            
            home?.getDataWithSuccess({ model in
                callback(model)
            }, failure: { error in
                let errorMessage = error?.localizedDescription ?? ""
            })
        }
    }
    
    func getDeviceModelList(_ model: ThingSmartHomeModel) -> [HejhomeDeviceModel] {
        guard let home = ThingSmartHome.init(homeId: model.homeId) else { return [] }
        
        var list:[HejhomeDeviceModel] = []
        
        for d in home.deviceList {
            let dm = HejhomeDeviceModel(deviceId: d.devId, productId: d.productId, name: d.name, homeId: home.homeId)
            list.append(dm)
        }
        
        return list
    }
    
    
    func getHomeList(_ callback: @escaping (() -> Void)) {
        homeManager.getHomeList { (homeModels) in
            guard let homeModels = homeModels else { self.addHome("Home"); return }
            guard homeModels.count > 0 else { self.addHome("Home"); return }
            
            self.homeList = homeModels
            callback()
            
        } failure: { (error) in
            
        }
    }
    
    func getAllDeviceList() {
        allDeviceList = []
        listIndex = 0
        checkNextIndex()
    }
    
    func checkNextIndex() {
        if listIndex >= homeList.count {
            HejhomeDevice.all = self.allDeviceList
            HejhomeHome.current = homeList.first
            guard let cameraListCallback = self.cameraListCallback else { return }
            self.cameraListCallback = nil
            cameraListCallback(self.allDeviceList)
            return
        }
        
        HejhomeHome.current = homeList[listIndex]
        
        listIndex += 1
        getDeviceListByHome{ model in
            if let model = model {
                let sub = self.getDeviceModelList(model)
                self.allDeviceList.append(contentsOf: sub)
            }
            
            self.checkNextIndex()
        }
    }
    
    func addHome(_ name: String) {
        homeManager.addHome(withName: name, geoName: name, rooms: [], latitude: 37.5665, longitude: 126.9780, success: { result in
            self.getHomeList {
                //
            }
        }, failure: { error in
            
        })

    }
}

extension User {
    func getCameraType(deviceId: String, complete: @escaping (HejhomeCameraType) -> Void, fail: @escaping (String) -> Void) {
        UserDeviceData.getInfo(deviceId: deviceId) { info in
            guard let type = info.result?.deviceType else { fail("타입 없음"); return }
            switch type {
            case let str where str.contains("hej-camera"): complete(.camera); break
            case let str where str.contains("hej-doorbell"): complete(.camera); break
            case let str where str.contains("hej-pet-feeder"): complete(.camera); break
            default: complete(.none); break
            }
        } fail: { error in
            fail(error)
        }
    }
}

extension User: ThingSmartHomeDelegate{
    func homeDidUpdateInfo(_ home: ThingSmartHome!) {
        getAllDeviceList()
    }
    
    func home(_ home: ThingSmartHome!, didAddDeivice device: ThingSmartDeviceModel!) {
        getAllDeviceList()
    }
    
    func home(_ home: ThingSmartHome!, didRemoveDeivice devId: String!) {
        getAllDeviceList()
    }
    
    func home(_ home: ThingSmartHome!, deviceInfoUpdate device: ThingSmartDeviceModel!) {
        getAllDeviceList()
    }
    
    func home(_ home: ThingSmartHome!, device: ThingSmartDeviceModel!, dpsUpdate dps: [AnyHashable : Any]!) {
        getAllDeviceList()
    }
}
