//
//  HejhomeLoginErrorCode.swift
//  HejhomeSDK
//
//  Created by Dasom Kim on 2023/08/01.
//

import Foundation

@objc public enum HejhomeLoginErrorCode: Int, CustomStringConvertible {
    
    case SDK_EMPTY_TOKEN = 3001
    case SDK_EMPTY_ACCOUNT_LINK = 3002
    case SDK_WRONG_SESSION_DATA = 3003
    case SDK_RE_LOGIN_FAIL = 3004
    
    case SDK_EMAIL_LOGIN_FAIL = 3005
    case SDK_PHONE_LOGIN_FAIL = 3006
    case SDK_SESSION_UPDATE_FAIL = 3007
    
    case SDK_TOKEN_ERROR = 3008
    
    case SDK_USER_CANCEL = 3010
    
    case TIMEOUT = 9990
    case UNKNOWN = 9999
    
    public var description: String {
        switch self {
        case .SDK_EMPTY_TOKEN:              return "토큰 미입력"
        case .SDK_EMPTY_ACCOUNT_LINK:       return "등록된 아이디 없음"
        case .SDK_WRONG_SESSION_DATA:       return "로그인 데이터 설정 실패"
        case .SDK_RE_LOGIN_FAIL:            return "SDK 로그인 실패"
            
        case .SDK_EMAIL_LOGIN_FAIL:         return "이메일 로그인 실패"
        case .SDK_PHONE_LOGIN_FAIL:         return "전화번호 로그인 실패"
        case .SDK_SESSION_UPDATE_FAIL:      return "세션정보 백업 실패"
            
        case .SDK_TOKEN_ERROR:              return "토큰 정보 로드 실패"
            
        case .SDK_USER_CANCEL:              return "사용자 취소"
        
        case .TIMEOUT:                      return "Timeout"
        case .UNKNOWN:                      return "Unknown Error"
        }
    }
}

