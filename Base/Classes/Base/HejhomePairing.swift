//
//  HejhomePairing.swift
//  HejhomeIpc
//
//  Created by Dasom Kim on 2023/05/24.
//

import Foundation
import ThingSmartActivatorKit

public protocol HejhomePairingDelegate: AnyObject {
    func hejhomePairingSuccess(_ deviceList: [PairingDevice])
    func hejhomePairingFailure(_ deviceList: [PairingDevice])
    func hejhomePairingProcessComplete(_ deviceList: [PairingDevice])
}

public class HejhomePairing: NSObject {
    
    public weak var delegate: HejhomePairingDelegate?
    
    public enum PairingMode {
        case AP
        case EASY
        case QR
    }
    
    public static let shared = HejhomePairing()
}

// Initialize
extension HejhomePairing {
    public func initialize(isDebug: Bool? = nil, onSuccess: (()->())? = nil, onFailure: ((PairingErrorCode)->())? = nil) {
        Pairing.shared.initialize(isDebug: isDebug, onSuccess: onSuccess, onFailure: onFailure)
        
        Pairing.shared.onPairingFailure = { device in
            self.delegate?.hejhomePairingFailure(device)
        }
        
        Pairing.shared.onPairingSuccess = { deviceList in
            self.delegate?.hejhomePairingSuccess(deviceList)
        }
        
        Pairing.shared.onPairingComplete = { deviceList in
            self.delegate?.hejhomePairingProcessComplete(deviceList)
        }
    }
    
    public func pairingCodeImage(ssid: String, password: String, token:String = "", size: Int, onSuccess: @escaping (UIImage?) -> Void, onFailure: @escaping (Error?) -> Void) {
        Pairing.shared.pairingCodeImage(ssid: ssid, password: password, token: token, size: size, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    public func devicePairing(ssidName: String, ssidPw: String, pairingToken: String = "", timeout:Int = 120, mode: PairingMode = .AP) {
        Pairing.shared.devicePairing(ssidName: ssidName, ssidPw: ssidPw, pairingToken: pairingToken, timeout: timeout, mode: mode)
    }
    
    public func resetDevicePairing() {
        Pairing.shared.stopConfig()
    }
    
    public func stopDevicePairing() {
        Pairing.shared.stopDevicePairing()
    }
    
    public func devicePairingCheck(pairingToken: String, timeout: Int = 30) {
        Pairing.shared.devicePairingCheck(pairingToken: pairingToken, timeout: timeout)
    }
}

