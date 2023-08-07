//
//  ErrorCode.swift
//  HejhomeIpc
//
//  Created by Dasom Kim on 2023/05/24.
//

import Foundation

public enum PairingErrorCode: Int, CustomStringConvertible {
    case MAIN_PAIRING_EXCEPTION = 9999
    case NOT_INITIALIZE = 9998
    case UNAUTHENTICATED_CLIENT = 9997
    case MAIN_PAIRING_API_EXCEPTION = 9996
    case PROCESSING_PAIRING_AP_MODE = 9995
    case PROCESSING_PAIRING_EZ_MODE = 9994
    case PROCESSING_PAIRING_QR_MODE = 9993

    case NOT_CONNECTION_WIFI = 9000
    case STOP_PROCESSING_PAIRING = 9001 // 사용자 취소

        /*Process Error*/
    case NOT_FOUND_PAIRING_DEVICE = 8000
    case PAIRING_TOKEN_PARSING_ERROR = 8001
    case NOT_SUPPORT_PAIRING_DEVICE = 8002
    
    // SDK
    case AUTO_PAIRING_TOKEN_FAIL = 7001
    case AUTO_PAIRING_TOKEN_EMPTY = 7002
    case AUTO_PAIRING_FAIL = 7003
    case AUTO_PAIRING_FAIL_TIMEOUT = 7004
    case AUTO_PAIRING_FAIL_UNKNOWN = 7005
    
    
    // Server
    case UNAUTHORIZED = 4001
    case DEVICE_IS_NOT_FOUND = 4002
    case DEVICE_IS_OFFLINE = 4003
    case DEVICE_ID_IS_NOT_SUPPORT = 4004
    case REQ_PARAM_ERROR = 4005
    case CHECK_REQ_INFORMATION = 4006
    case NO_SEARCH_RESULTS = 4007
    case NOT_FOUND_USER = 4008
    case DEVICE_TOKEN_EXPIRED = 4009
    case UNAVAILABLE_DEVICE_ID = 4010

    case INTERNAL_SERVER_ERROR = 500
    case UNKNOWN = 0
    
    public var description: String {
        switch self {
        case .MAIN_PAIRING_EXCEPTION:       return "Main Pairing Exception"
        case .NOT_INITIALIZE:               return "Not Initialize"
        case .UNAUTHENTICATED_CLIENT:       return "Unauthenticated Client"
        case .MAIN_PAIRING_API_EXCEPTION:   return "Main Pairing API Exception"
        case .PROCESSING_PAIRING_AP_MODE:   return "Processing Pairing AP Mode"
        case .PROCESSING_PAIRING_EZ_MODE:   return "Processing Pairing EZ Mode"
        case .PROCESSING_PAIRING_QR_MODE:   return "Processing Pairing QR Mode"
        case .NOT_CONNECTION_WIFI:          return "Not Connection WiFi"
        case .STOP_PROCESSING_PAIRING:      return "Stop Processing Pairing"
        case .NOT_FOUND_PAIRING_DEVICE:     return "Not Found Pairing Device"
        case .PAIRING_TOKEN_PARSING_ERROR:  return "Pairing Token Parsing Error"
        case .NOT_SUPPORT_PAIRING_DEVICE:   return "Not Support Pairing Device"
            // New
        case .AUTO_PAIRING_TOKEN_FAIL:      return "Pairing Token was not issued."
        case .AUTO_PAIRING_TOKEN_EMPTY:     return "Pairing Token is empty"
        case .AUTO_PAIRING_FAIL:            return "Pairing Fail"
        case .AUTO_PAIRING_FAIL_TIMEOUT:            return "Pairing Timeout"
        case .AUTO_PAIRING_FAIL_UNKNOWN:            return "Pairing Fail (Unknown)"
            
            // server
        case .UNAUTHORIZED:             return "Unauthorized"
        case .DEVICE_IS_NOT_FOUND:      return "Device is not found"
        case .DEVICE_IS_OFFLINE:        return "Device is offline"
        case .DEVICE_ID_IS_NOT_SUPPORT: return "Device Id Is Not Support"
        case .REQ_PARAM_ERROR:          return "Requirements can not be null or empty"
        case .CHECK_REQ_INFORMATION:    return "Please check the request information"
        case .NO_SEARCH_RESULTS:        return "No search results"
        case .NOT_FOUND_USER:           return "User not found"
        case .DEVICE_TOKEN_EXPIRED:     return "Device Token Expired"
        case .UNAVAILABLE_DEVICE_ID:    return "Unavailable deviceId"

        case .INTERNAL_SERVER_ERROR:    return "Internal Server Error"
            
        case .UNKNOWN:                  return "Unknown Error"
        }
    }
}

