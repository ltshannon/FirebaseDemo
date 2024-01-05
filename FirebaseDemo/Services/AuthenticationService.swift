//
//  AuthenticationService.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 11/7/23.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import SwiftUI

enum LoginType: String {
    case usernamePassword = "Username & password"
    case google = "Google"
    case apple = "Apple"
    case unknown = "Unknown"
    case emailLink = "Email Link"
}

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

enum AuthenticationState {
  case unauthenticated
  case authenticating
  case authenticated
}

class AuthenticationService: ObservableObject {
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var displayName = ""
    @Published var user: User?
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @AppStorage("email-link") var emailLink: String?
    @AppStorage("login-type") var loginType: LoginType = .unknown
    static let shared = AuthenticationService()
    private var currentNonce: String?
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    init() {
        registerAuthStateHandler()
        verifySignInWithAppleAuthenticationState()
    }
    
    func registerAuthStateHandler() {
        debugPrint("🛎️🛎️🛎️", "AuthenticationService registerAuthStateHandler")
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
                DispatchQueue.main.async {
                    self.user = user
                    self.authenticationState = user == nil ? .unauthenticated : .authenticated
                    self.displayName = user?.displayName ?? user?.email ?? ""
                }
            }
        }
    }
    
    func getAuthenticatedUser() throws -> AuthDataResult {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        return AuthDataResult(user: user)
    }
    
    func createUser(email: String, password: String) async throws -> AuthDataResult {
        DispatchQueue.main.async {
            self.loginType = .usernamePassword
        }
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        DispatchQueue.main.async {
            self.user = authDataResult.user
        }
        return AuthDataResult(user: authDataResult.user)
    }
    
    func signInUser(email: String, password: String) async throws -> AuthDataResult {
        DispatchQueue.main.async {
            self.loginType = .usernamePassword
        }
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        DispatchQueue.main.async {
            self.user = authDataResult.user
        }
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
    
    func sendSignInLink(email: String) async throws {
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.url = URL(string: "https://breakawaydesign.page.link/email-link-login")
        
        try await Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings)
        DispatchQueue.main.async {
            self.emailLink = email
        }
    }
    
    func handleSignInLink(url: URL, email: String) async {
        guard let email = emailLink else {
            DispatchQueue.main.async {
                self.errorMessage = "Invaild email address. Most likely, the link you used has expired. Try signing in again"
                self.showError = true
            }
            return
        }
        let link = url.absoluteString
        if Auth.auth().isSignIn(withEmailLink: link) {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, link: link)
                debugPrint("🌎", "Email link sign in for user: \(result.user.uid) signed in with email: \(result.user.email ?? "none")")
                DispatchQueue.main.async {
                    self.user = result.user
                    self.emailLink = nil
                    self.loginType = .emailLink
                }
            } catch {
                debugPrint("🧨", "handleSignInLink return an error on email link: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "handleSignInLink return an error on email link: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }
    
    func signInAnonymously() {
        if Auth.auth().currentUser == nil {
            debugPrint("🌎", "Nobody is signed in. Trying to sign in anonymously.")
            Task {
                do {
                    let result = try await Auth.auth().signInAnonymously()
                    DispatchQueue.main.async {
                        self.user = result.user
                    }
                }
                catch {
                    debugPrint("🧨", "signInAnonymously error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                    }
                }
            }
        }
        else {
            debugPrint("🌎", "Someone is signed in")
            if let user = Auth.auth().currentUser {
                debugPrint("🌎", "user.id: \(user.uid)")
            }
        }
    }
    
    func deleteAccount() async -> Bool {
        guard let user = user else { return false }
        guard let lastSignInDate = user.metadata.lastSignInDate else { return false }
        let needsReauth = !lastSignInDate.isWithinPast(minutes: 5)

        let needsTokenRevocation = user.providerData.contains { $0.providerID == "apple.com" }

        do {
            if needsReauth || needsTokenRevocation {
                let signInWithApple = SignInWithApple()
                let appleIDCredential = try await signInWithApple()

                guard let appleIDToken = appleIDCredential.identityToken else {
                    debugPrint("🧨", "Unable to fetdch identify token.")
                    DispatchQueue.main.async {
                        self.errorMessage = "Unable to fetdch identify token."
                        self.showError = true
                    }
                    return false
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    debugPrint("🧨", "Unable to serialise token string from data: \(appleIDToken.debugDescription)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Unable to serialise token string from data: \(appleIDToken.debugDescription)"
                        self.showError = true
                    }
                    return false
                }

                let nonce = randomNonceString()
                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                          idToken: idTokenString,
                                                          rawNonce: nonce)

                if needsReauth {
                    try await user.reauthenticate(with: credential)
                }
                if needsTokenRevocation {
                    guard let authorizationCode = appleIDCredential.authorizationCode else { return false }
                    guard let authCodeString = String(data: authorizationCode, encoding: .utf8) else { return false }

                    try await Auth.auth().revokeToken(withAuthorizationCode: authCodeString)
                }
            }

        try await user.delete()
            DispatchQueue.main.async {
                self.errorMessage = ""
            }
            return true
        }
        catch {
            debugPrint("🧨", "\(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
            return false
        }
    }
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        DispatchQueue.main.async {
            self.loginType = .apple
        }
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }

    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        if case .failure(let failure) = result {
            errorMessage = failure.localizedDescription
        }
        else if case .success(let authorization) = result {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: a login callback was received, but no login request was sent.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    debugPrint("🧨", "Unable to fetdch identify token.")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    debugPrint("🧨", "Unable to serialise token string from data: \(appleIDToken.debugDescription)")
                    return
                }

                debugPrint("😍", "handleSignInWithAppleCompletion appleIDCredential.email: \(appleIDCredential.email ?? "no email") ")
                debugPrint("😍", "handleSignInWithAppleCompletion appleIDCredential.fullname: \(appleIDCredential.fullName?.familyName ?? "no name") ")
                let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                               rawNonce: nonce,
                                                               fullName: appleIDCredential.fullName)
                Task {
                    do {
                        let result = try await Auth.auth().signIn(with: credential)
                        DispatchQueue.main.async {
                            self.user = result.user
                        }
                    }
                    catch {
                        debugPrint("🧨", "Error authenticating: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.errorMessage = error.localizedDescription
                            self.showError = true
                        }
                    }
                }
            }
        }
    }
    
    func updateDisplayName(for user: User, with appleIDCredential: ASAuthorizationAppleIDCredential, force: Bool = false) async {
        if let currentDisplayName = Auth.auth().currentUser?.displayName, !currentDisplayName.isEmpty {
            // current user is non-empty, don't overwrite it
        }
        else {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = appleIDCredential.displayName()
            do {
                try await changeRequest.commitChanges()
                self.displayName = Auth.auth().currentUser?.displayName ?? ""
            }
            catch {
                debugPrint("🧨", "Unable to update the user's displayname: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }

    func verifySignInWithAppleAuthenticationState() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let providerData = Auth.auth().currentUser?.providerData
        if let appleProviderData = providerData?.first(where: { $0.providerID == "apple.com" }) {
            Task {
                do {
                    let credentialState = try await appleIDProvider.credentialState(forUserID: appleProviderData.uid)
                    switch credentialState {
                    case .authorized:
                        break // The Apple ID credential is valid.
                    case .revoked, .notFound:
                        // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                        try self.signOut()
                    default:
                        break
                    }
                }
                catch {
                    debugPrint("🧨", "verifySignInWithAppleAuthenticationState failed")
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                    }
                }
            }
        }
    }

    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()

        return hashString
    }
}

extension ASAuthorizationAppleIDCredential {
    func displayName() -> String {
        return [self.fullName?.givenName, self.fullName?.familyName].compactMap( {$0}).joined(separator: " ")
    }
}

class SignInWithApple: NSObject, ASAuthorizationControllerDelegate {

  private var continuation : CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

  func callAsFunction() async throws -> ASAuthorizationAppleIDCredential {
    return try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
      let appleIDProvider = ASAuthorizationAppleIDProvider()
      let request = appleIDProvider.createRequest()
      request.requestedScopes = [.fullName, .email]

      let authorizationController = ASAuthorizationController(authorizationRequests: [request])
      authorizationController.delegate = self
      authorizationController.performRequests()
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if case let appleIDCredential as ASAuthorizationAppleIDCredential = authorization.credential {
      continuation?.resume(returning: appleIDCredential)
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    continuation?.resume(throwing: error)
  }
}

extension Date {
    func isWithinPast(minutes: Int) -> Bool {
        let now = Date.now
        let timeAgo = Date.now.addingTimeInterval(-1 * TimeInterval(60 * minutes))
        let range = timeAgo...now
        return range.contains(self)
    }
}
