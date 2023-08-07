//
//  Convert.swift
//  HejhomeIpc
//
//  Created by Dasom Kim on 2023/05/24.
//

import Foundation

func getBoolValue(_ str: String?) -> Bool? {
    guard let str = str else { return nil }
    return str == "1"
}

func stringToDate(_ dateString: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

    guard let date = dateFormatter.date(from: dateString) else { return nil }
    return date
}

func timestampToDate(_ timestamp: Int) -> Date {
    let timestamp = timestamp
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    
    return date

}
