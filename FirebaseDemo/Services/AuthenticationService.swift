//
//  AuthenticationService.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 11/7/23.
//

import Foundation
import FirebaseAuth

struct AuthDataResult {
    let uid: String
    let email: String?
    let photoURL: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photoURL = user.photoURL?.absoluteString
    }
}

class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    init() {
        
    }
    
    func getAuthenticatedUser() throws -> AuthDataResult {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        return AuthDataResult(user: user)
    }
    
    func createUser(email: String, password: String) async throws -> AuthDataResult {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthDataResult(user: authDataResult.user)
    }
    
    func signInUser(email: String, password: String) async throws -> AuthDataResult {
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthDataResult(user: authDataResult.user)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func resetPassword() async throws {
        let userData = try getAuthenticatedUser()
        if let email = userData.email {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        }
    }
    
}
