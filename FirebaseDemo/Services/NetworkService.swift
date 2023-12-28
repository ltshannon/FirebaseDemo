//
//  NetworkService.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 12/25/23.
//
import Foundation
import Firebase

enum Endpoint {
    case createUser
    case createGroup
    case addUserToPod(groupId: String)
    case removeUserFromPod(groupId: String)
    case acceptInvite(groupId: String)
    case declineInvite(groupId: String)
    case leavePod(groupId: String)
    case postStatus(groupId: String)
    case postQuestionAnswers
    case postGroupAnswers
    case checkPhoneNumbers
    case inviteUser
    case deleteGroup(groupId: String)
    case location
    case riskScore
    case leaveGroup(groupId: String)
    case removeUser(groupId: String)
    case addFCMToken
    
    var baseUrlString: String {
        //TODO: move this into its own ENUM at some point in order to switch between staging/dev/prod server environments
        return "https://us-central1-together-c537f.cloudfunctions.net/api/"
    }
    
    var method: HTTPMethod {
        switch self {
        
        case .createUser,
             .createGroup,
             .addUserToPod,
             .removeUserFromPod,
             .acceptInvite,
             .declineInvite,
             .leavePod,
             .postStatus,
             .postQuestionAnswers,
             .postGroupAnswers,
             .checkPhoneNumbers,
             .inviteUser,
             .location,
             .riskScore,
             .leaveGroup,
             .removeUser,
             .addFCMToken:
            return .post
        case .deleteGroup:
            return .delete
        }
    }
    
    var route: String {
        switch self {
            
        case .createUser:
            return "users/create"
        case .createGroup:
            return "groups/create"
        case .addUserToPod(groupId: let groupId):
            return "groups/\(groupId)/inviteUser"
        case .removeUserFromPod(groupId: let groupId):
            return "groups/\(groupId)/removeUser"
        case .acceptInvite(groupId: let groupId):
            return "groups/\(groupId)/accept"
        case .declineInvite(groupId: let groupId):
            return "groups/\(groupId)/decline"
        case .leavePod(groupId: let groupId):
            return "groups/\(groupId)/leave"
        case .postStatus(groupId: let groupId):
            return "groups/\(groupId)/status"
        case .postQuestionAnswers:
            return "answers"
        case .postGroupAnswers:
            return "answerQuestions"
        case .checkPhoneNumbers:
            return "checkPhoneNumbers"
        case .inviteUser:
            return "invites/create"
        case .deleteGroup(groupId: let groupId):
            return "groups/\(groupId)"
        case .location:
            return "users/location"
        case .riskScore:
            return "users/riskScore"
        case .leaveGroup(groupId: let groupId):
            return "groups/\(groupId)/leave"
        case .removeUser(groupId: let groupId):
            return "groups/\(groupId)/removeUser"
        case .addFCMToken:
            return "users/addFCMToken"
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

struct Result: Codable {
    let message: String
}

class NetworkService: ObservableObject {
    static let shared = NetworkService()
    var authentication = Authentication.shared
    
    func callAPI(endpoint: Endpoint, requestBody: Data?) async {
        guard let url = URL(string: "https://us-central1-fir-demo-adeb5.cloudfunctions.net/testFunction") else {
            print("Invalid URL")
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
            
            if let decodedResponse = try? JSONDecoder().decode(Result.self, from: data) {
                let message = decodedResponse.message
                if let response = response as? HTTPURLResponse {
                    if response.statusCode != 200 {
                        debugPrint("🧨", "response.statusCode: \(response.statusCode)", "Error: \(message)")
                    } else {
                        debugPrint("🌎", "response: \(message)")
                    }
                }
            }
        } catch {
            print("Invalid data")
        }
    }
    
}
