//
//  Crypto.swift
//  HejhomeSDK
//
//  Created by Dasom Kim on 2023/07/21.
//

import CryptoSwift

class Crypto: NSObject {
    
    let key = "5166546A576E5A7134743777217A2543"
    let iv = "uvwxyzabcdefghij"
    
    func encrypt(_ string: String) -> String {
        guard !isBase64Encoded(string) else { return string }
        
        do {
            let encryptedString = try encryptString(input: string, key: key, iv: iv)
            return encryptedString
        } catch {
            return ""
        }
    }
    
    func decrypt(_ string: String) -> String {
        let cleanedString = string.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: " ", with: "")
        guard isBase64Encoded(cleanedString) else { return cleanedString }
        
        do {
            let decryptedString = try decryptString(encryptedBase64: cleanedString, key: key, iv: iv)
            return decryptedString
        } catch {
            return ""
        }
    }
}

extension Crypto {
    
    func isBase64Encoded(_ string: String) -> Bool {
        if let data = Data(base64Encoded: string) {
            return string == data.base64EncodedString()
        } else {
            return false
        }
    }
    
    func encryptString(input: String, key: String, iv: String) throws -> String {
        let data = Data(input.utf8)
        let encrypted = try AES(key: Array(key.utf8), blockMode: CBC(iv: Array(iv.utf8)), padding: .pkcs5).encrypt(data.bytes)
        return encrypted.toBase64() ?? ""
    }
    
    
    func decryptString(encryptedBase64: String, key: String, iv: String) throws -> String {
        guard let encryptedData = Data(base64Encoded: encryptedBase64),
              let decrypted = try? AES(key: Array(key.utf8), blockMode: CBC(iv: Array(iv.utf8)), padding: .pkcs5).decrypt(encryptedData.bytes),
              let decryptedString = String(bytes: decrypted, encoding: .utf8) else {
            throw NSError(domain: "Decryption error", code: 0, userInfo: nil)
        }
        
        return decryptedString
    }
}
