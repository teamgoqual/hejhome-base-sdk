//
//  UserConverter.swift
//  HejhomeSDK
//
//  Created by Dasom Kim on 2023/06/26.
//

import Foundation
import ThingSmartBaseKit

struct UserConverter: Codable {
    var sid: String = ""
    var uid: String = ""
    var headIconUrl: String = ""
    var nickname: String = ""
    var userName: String = ""
    var phoneNumber: String = ""
    var email: String = ""
    var countryCode: String = ""
    var isLogin: Bool = false
    var regionCode: String = ""
    var domain: [String: String] = [:]
    var timezoneId: String = ""
    var partnerIdentity: String = ""
    var mbHost: String = ""
    var gwHost: String = ""
    var port: Int = 0
    var useSSL: Bool = false
    var quicHost: String = ""
    var quicPort: Int = 0
    var useQUIC: Bool = false
    var tempUnit: Int = 0
    var regFrom: Int = 0
    var snsNickname: String = ""
    var ecode: String = ""
    var userType: Int = 0
    var extras: [String: String] = [:]
    var userAlias: String = ""

    init(fromThingUser from: ThingSmartUser) {
        self.sid = from.sid
        self.uid = from.uid
        self.headIconUrl = from.headIconUrl
        self.nickname = from.nickname
        self.userName = from.userName
        self.phoneNumber = from.phoneNumber
        self.email = from.email
        self.countryCode = from.countryCode
        self.isLogin = from.isLogin
        self.regionCode = from.regionCode
        self.domain = (from.domain as? [String: String]) ?? [:]
        self.timezoneId = from.timezoneId
        self.partnerIdentity = from.partnerIdentity
        self.mbHost = from.mbHost
        self.gwHost = from.gwHost
        self.port = from.port
        self.useSSL = from.useSSL
        self.quicHost = from.quicHost
        self.quicPort = from.quicPort
        self.useQUIC = from.useQUIC
        self.tempUnit = from.tempUnit
        self.regFrom = from.regFrom.rawValue
        self.snsNickname = from.snsNickname
        self.ecode = from.ecode
        self.userType = from.userType
        self.extras = (from.extras as? [String: String]) ?? [:]
        self.userAlias = from.userAlias
    }
}
