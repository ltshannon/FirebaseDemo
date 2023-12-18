//
//  GoogleSignInService.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 11/8/23.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import FirebaseAuth

@MainActor
class GoogleSignInService: ObservableObject {
    static let shared = GoogleSignInService()
    
    init() {
        
    }
    
    func signInGoogle() async throws {
        guard let topViewContoller = Utilities.shared.topViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topViewContoller)
        guard let idToken = gidSignInResult.user.idToken?.tokenString else {
            throw URLError(.unknown)
        }
        let accessToken = gidSignInResult.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        let _ = try await Auth.auth().signIn(with: credential)

    }
}
