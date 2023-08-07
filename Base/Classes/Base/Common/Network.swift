//
//  Network.swift
//  HejhomeIpc
//
//  Created by Dasom Kim on 2023/05/24.
//

import Network

class API {
    
    enum NetworkStatus {
        case wifi
        case others
        case disconnected
    }
    
    static let shared: API = API()
    
    let monitor = NWPathMonitor()
    var status = NetworkStatus.disconnected
    var session: URLSession
    
    var code = ""
    private init() {

        let conf = URLSessionConfiguration.default
        conf.timeoutIntervalForRequest = 30
        conf.waitsForConnectivity = true
        session = URLSession(configuration: conf)
        
        monitor.start(queue: DispatchQueue.global())
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                if path.usesInterfaceType(.wifi) {
                    self.status = .wifi
                } else {
                    self.status = .others
                }
            } else {
                self.status = .disconnected
            }
        }
    }
    
    func setSdkAccessCode(_ code: String) {
        self.code = code
    }
    
    func checkWifi() -> Bool {
        return self.status == .wifi
    }
    
    
    func get(urlString: String, lgAccessCode: String? = nil, uid: String? = nil, completionHandler: @escaping ([String:AnyObject]) -> Void) {
        guard let url = URL(string: urlString) else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.addValue("UTF-8", forHTTPHeaderField: "Accept-Charset")
        request.addValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.addValue(code, forHTTPHeaderField: "Sdk-Access-Code")
        
        if let code = lgAccessCode {
            request.addValue(code, forHTTPHeaderField: "LG-Access-Code")
        }
        
        if let uid = uid {
            request.addValue(uid, forHTTPHeaderField: "LG-Uid")
        }
        
        session.dataTask(with: request) { data, response, error in
            print(response)
            guard error == nil else {
                print(response)
                completionHandler([:])
                return
            }
            completionHandler(convertToDictionary(data) ?? [:])
        }.resume()
    }
    
    func post<T: Encodable>(urlString: String, parameter: T, lgAccessCode: String? = nil, completionHandler: @escaping ([String: Any]) -> Void) {
        guard let url = URL(string: urlString) else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.addValue("UTF-8", forHTTPHeaderField: "Accept-Charset")
//        request.addValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(code, forHTTPHeaderField: "Sdk-Access-Code")
        
        if let code = lgAccessCode {
            request.addValue(code, forHTTPHeaderField: "LG-Access-Code")
        }
        
        if let requestData = try? JSONEncoder().encode(parameter) {
            request.httpBody = requestData
            if let jsonString = String(data: requestData, encoding: .utf8) {
//                print(jsonString)
            }
        }
        
        session.dataTask(with: request) { data, response, error in
//            print(response)
            guard error == nil, let httpResponse = response as? HTTPURLResponse else {
                print(response)
                completionHandler(["errorCode": 9999])
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                completionHandler(["errorCode": httpResponse.statusCode])
                return
            }
            
            completionHandler(convertToDictionary(data) ?? [:])
        }.resume()
    }
    
    func delete(urlString: String, path: String, lgAccessCode: String? = nil, completionHandler: @escaping ([String: Any]) -> Void) {
        guard let url = URL(string: "\(urlString)/\(path)") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        request.addValue("UTF-8", forHTTPHeaderField: "Accept-Charset")
        request.addValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.addValue(code, forHTTPHeaderField: "Sdk-Access-Code")
        
        if let code = lgAccessCode {
            request.addValue(code, forHTTPHeaderField: "LG-Access-Code")
        }
        
        session.dataTask(with: request) { data, response, error in
//            print(response)
            guard error == nil, let httpResponse = response as? HTTPURLResponse else {
                print(response)
                completionHandler(["errorCode": 9999])
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                completionHandler(["errorCode": httpResponse.statusCode])
                return
            }
            
            completionHandler(convertToDictionary(data) ?? [:])
        }.resume()
    }

}

func convertToDictionary(_ data: Data?) -> [String: AnyObject]? {
    if let data = data {
        print(data)
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
        } catch {
            print(error.localizedDescription)
        }
    }
    print("nil")
    
    return nil
}
