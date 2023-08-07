//
//  WebInterface.swift
//  HejhomeIpc
//
//  Created by Dasom Kim on 2023/05/15.
//

import Foundation
import WebKit

@objc public class HejhomeWebInterface: NSObject {
    @objc public static let handler = "hejhomeInterface"
    
    static let sendLoginInfo = "sendLoginInfo"
    
    
    @objc public static func sendScriptMessage(_ message: WKScriptMessage, timeout: Int = 30) {
        let dic:[String:AnyObject] = message.body as? [String:AnyObject] ?? [:]
        switch message.name {
        case HejhomeWebInterface.handler:
            handlerAction(dic, timeout: timeout)
        default:
            break

        }
    }
}

extension HejhomeWebInterface {
    static func handlerAction(_ dic: [String: AnyObject], timeout: Int) {
        guard let function = dic["action"] as? String else { return }
        switch function {
        case sendLoginInfo:
            sendLoginInfo(dic, timeout: timeout)
        default:
            return
        }
    }
    
    static func sendLoginInfo(_ dic: [String: AnyObject], timeout: Int) {
        guard let argu = dic["arguments"] as? [String : Any] else { return }
        guard let account = argu["username"] as? String else { return }
        guard let password = argu["password"] as? String else { return }
        
        let pw = Crypto().decrypt(password)
        
        HejhomeBase.shared.login(account: account, password: pw, timeout: timeout) {
            HejhomeBase.shared.delegate?.hejhomeLoginSuccess()
        } onFailure: { error in
            HejhomeBase.shared.delegate?.hejhomeLoginFailure(error ?? .UNKNOWN)
        }
    }
    
}
