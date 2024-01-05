//
//  NetworkService.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 12/25/23.
//
import Foundation
import Firebase

enum Endpoint {
    case testWrite
    case testRead
    
    var baseUrlString: String {
        //TODO: move this into its own ENUM at some point in order to switch between staging/dev/prod server environments
        return "https://us-central1-fir-demo-adeb5.cloudfunctions.net/"
    }
    
    var method: HTTPMethod {
        switch self {
        
        case .testWrite,
             .testRead:
            return .post
        }
    }
    
    var route: String {
        switch self {
            
        case .testWrite:
            return "testWrite"
        case .testRead:
            return "testRead"
        }
    }
}

public enum HTTPMethod: String {
    case connect = "CONNECT"
    case delete  = "DELETE"
    case get     = "GET"
    case head    = "HEAD"
    case options = "OPTIONS"
    case patch   = "PATCH"
    case post    = "POST"
    case put     = "PUT"
    case trace   = "TRACE"
}

struct APIResult: Codable {
    let message: String
}

class NetworkService: ObservableObject {
    static let shared = NetworkService()
    @Published var message: String = ""
    var authentication = Authentication.shared
    
    func resetMessage() {
        message = ""
    }
    
    func callAPI(endpoint: Endpoint, requestBody: Data?) async {
        
        guard let url = URL(string: endpoint.baseUrlString + endpoint.route) else {
            debugPrint("🧨", "Invalid URL")
            return
        }

        let fcm = await authentication.fcmToken
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(fcm)", forHTTPHeaderField: "Authorization")
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = requestBody
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let decodedResponse = try? JSONDecoder().decode(APIResult.self, from: data) {
                let message = decodedResponse.message
                if let response = response as? HTTPURLResponse {
                    if response.statusCode != 200 {
                        debugPrint("🧨", "response.statusCode: \(response.statusCode)", "Error: \(message)")
                    } else {
                        debugPrint("🌎", "response: \(message)")
                        if endpoint == .testRead {
                            DispatchQueue.main.async {
                                self.message = message
                            }
                        }
                    }
                }
            } else {
                debugPrint("🧨", "JSON decode failed")
            }
        } catch {
            debugPrint("🧨", "Invalid data")
        }
    }
    
}
