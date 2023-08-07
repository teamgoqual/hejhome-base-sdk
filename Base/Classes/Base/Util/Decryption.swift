//
//  Decryption.swift
//  HejhomeIpc
//
//  Created by Dasom Kim on 2023/05/17.
//

import Foundation
import CryptoSwift
 
//라이브러리 : https://github.com/krzyzanowskim/CryptoSwift
//pod 'CryptoSwift', '~> 1.3.8'
class AES256Util {
    //키값 32바이트: AES256(24bytes: AES192, 16bytes: AES128)
    private static let SECRET_KEY = "5166546A576E5A7134743777217A2543"
    private static let IV = ""
 
    static func encrypt(string: String) -> String {
        guard !string.isEmpty else { return "" }
        return try! getAESObject().encrypt(string.bytes).toBase64() ?? ""
    }
 
    static func decrypt(encoded: String) -> String {
        let datas = Data(base64Encoded: encoded)
 
        guard datas != nil else {
            return ""
        }
 
        let bytes = datas!.bytes
        
        do {
            let decode = try getAESObject().decrypt(bytes)
            return String(bytes: decode, encoding: .utf8) ?? ""
        } catch {
            // 오류가 발생했을 때 처리할 로직 작성
            print("Decryption error:", error)
            return ""
        }
    }
 
    private static func getAESObject() -> AES{
        let keyDecodes : Array<UInt8> = Array(SECRET_KEY.utf8)
        var ivDecodes : Array<UInt8> = Array(IV.utf8)
        ivDecodes = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let aesObject = try! AES(key: keyDecodes, blockMode: CBC(iv: ivDecodes), padding: .pkcs7)
 
        return aesObject
    }
    
    func de2(string: String) {
        // 암호문과 키
        let encryptedDataString = string // "crypto-js"로 암호화된 데이터
        let key = "5166546A576E5A7134743777217A2543"

        // 암호문을 Base64 디코딩하여 Data로 변환
        guard let encryptedData = Data(base64Encoded: encryptedDataString) else {
            print("Failed to decode the encrypted data.")
            return
        }

        // 키를 바이트 배열로 변환
        let keyData = Array<UInt8>(hex: key)

        // AES 복호화
        do {
            let decryptedBytes = try AES(key: keyData, blockMode: ECB(), padding: .pkcs7).decrypt(encryptedData.bytes)
            let decryptedData = Data(decryptedBytes)
            if let decryptedString = String(data: decryptedData, encoding: .utf8) {
                print("Decrypted data:", decryptedString)
            } else {
                print("Failed to decode the decrypted data.")
            }
        } catch {
            print("Decryption failed:", error)
        }

    }
    
    func de3(string: String) {
        let key = "5166546A576E5A7134743777217A2543"
//        let iv = "1234567890123456" // 초기화 벡터 설정
        let keyData = Data(hex: key)
//        let ivData = Data(hex: iv)

        guard let encryptedData = Data(base64Encoded: string) else {
            print("Invalid encrypted data.")
            return
        }

        do {
            let decryptedData = try AES(key: keyData.bytes, blockMode: ECB(), padding: .pkcs7).decrypt(encryptedData.bytes)
            if let decryptedString = String(bytes: decryptedData, encoding: .utf8) {
                print("Decrypted string:", decryptedString)
            } else {
                print("Failed to decode decrypted data.")
            }
        } catch {
            print("Decryption error:", error)
        }
    }
    
    func decryptAES(data: String, key: String) -> String? {
        let keyData = Data(hex: key)
        guard let encryptedData = Data(base64Encoded: data) else {
            return nil
        }

        do {
            let decryptedBytes = try AES(key: keyData.bytes, blockMode: ECB(), padding: .pkcs7).decrypt(encryptedData.bytes)
            let decryptedData = Data(decryptedBytes)
            if let decryptedString = String(data: decryptedData, encoding: .unicode) {
                return decryptedString
            } else {
                return nil
            }
        } catch let error {
            debugPrint("Error:", error)
            return nil
        }
    }

    
    
}

