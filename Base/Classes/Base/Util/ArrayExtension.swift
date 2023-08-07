//
//  ArrayExtension.swift
//  ThingCameraSDKSampleApp
//
//  Created by Dasom Kim on 2023/04/10.
//

import Foundation
import YYModel

extension Array {
//    static func yy_modelArray(with cls: AnyClass, json: Any?) -> [Any]? {
//        guard let json = json else { return nil }
//        var arr: [Any]?
//        var jsonData: Data?
//        if let jsonArray = json as? [Any] {
//            arr = jsonArray
//        } else if let jsonString = json as? String {
//            jsonData = jsonString.data(using: .utf8)
//        } else if let jsonDataUnwrapped = json as? Data {
//            jsonData = jsonDataUnwrapped
//        }
//        if let jsonData = jsonData {
//            arr = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [Any]
//            if arr == nil {
//                arr = []
//            }
//        }
//        let classType = cls as? NSObject.Type ?? NSObject.self
//        return try? arr?.map { try classType.yy_model(with: $0 as! [AnyHashable : Any]) }
//    }
}
