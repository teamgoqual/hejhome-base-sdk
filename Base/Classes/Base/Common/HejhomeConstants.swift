//
//  HejhomeConstants.swift
//  HejhomeIpc
//
//  Created by Dasom Kim on 2023/05/24.
//

import Foundation

class GoqualConstants {
    static let PLATFORM_PRODUCTION_URL = "https://goqual.io"
    static let PLATFORM_STAGING_URL = "https://dev.goqual.io"
    static let PLATFORM_URL = {
        (_ isDebugMode: Bool) -> String in
        return isDebugMode ? PLATFORM_STAGING_URL : PLATFORM_PRODUCTION_URL
    }
    static let PAIRING_STATUS = {
        (_ token: String) -> String in
        let str = "/thinq/pairing-tokens/\(token)/status"
        return str
    }
    static let GET_PRODUCT_ID_LIST = "/thinq/pid-list"
    static let API_THINQ_USER = "/thinq/user"
    static let API_THINQ_USER_CHECK = "/thinq/user/check"
    static let API_THINQ_DEVICE = {
        (_ devId: String) -> String in
        let str = "/thinq/user/device/\(devId)"
        return str
    }
}
