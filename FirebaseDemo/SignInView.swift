//
//  SignInView.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 11/7/23.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authticationService: AuthenticationService
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userAuth: Authentication
    @Environment(\.colorScheme) var colorScheme
    @State private var email: String = ""
    @State private var emailLink: String = ""
    @State private var password: String = ""
    @State private var showInvaildInput = false
    @State private var showCreateUserFailed = false
    @State private var showEmailLinkFailed = false
    @State private var showEmailLink = false
    @State private var firebaseError = ""
    @ObservedObject var appleSignInService = AppleSignInService.shared
    
    var body: some View {
        ScrollView {
            VStack {
                TextField("Email", text: $email)
                    .EmailPaswordStyle()
                    .textInputAutocapitalization(.never)
                SecureField("Password", text: $password)
                    .EmailPaswordStyle()
                Button {
                    Task {
                        do {
                            let userResults = try await authticationService.signInUser(email: email, password: password)
                            debugPrint("🦁", "user signed in: \(userResults)")
                            DispatchQueue.main.async {
                                presentationMode.wrappedValue.dismiss()
                            }
                        } catch {
                            debugPrint("🧨", "Firebase return an error on Sign in: \(error)")
                            DispatchQueue.main.async {
                                firebaseError = error.localizedDescription
                                showCreateUserFailed = true
                            }
                        }
                    }
                } label: {
                    Text("Sign In with an Email/Password")
                        .DefaultTextButtonStyle()
                }
                Button {
                    Task {
                        do {
                            let userResults = try await authticationService.createUser(email: email, password: password)
                            debugPrint("🦁", "user created: \(userResults)")
                            DispatchQueue.main.async {
                                presentationMode.wrappedValue.dismiss()
                            }
                            return
                        } catch {
                            debugPrint("🧨", "Firebase return an error on create user: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                firebaseError = error.localizedDescription
                                showCreateUserFailed = true
                            }
                        }
                    }
                } label: {
                    Text("Create account with a Email/Password")
                        .DefaultTextButtonStyle()
                }
                Text("Or")
                GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                    authticationService.loginType = .google
                    Task {
                        do {
                            try await GoogleSignInService.shared.signInGoogle()
                            debugPrint("🦁", "user signed in with goolge")
                        } catch {
                            debugPrint("", "GoogleSignInService return error: \(error.localizedDescription)")
                        }
                        DispatchQueue.main.async {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                Text("Or")
                SignInWithAppleButton(.signIn) { request in
                    authticationService.handleSignInWithAppleRequest(request)
                } onCompletion: { result in
                    authticationService.handleSignInWithAppleCompletion(result)
                }
                .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                .frame(height: 50)
                .cornerRadius(8)
                Text("Or")
                TextField("Email", text: $emailLink)
                    .EmailPaswordStyle()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                Button {
                    Task {
                        do {
                            try await authticationService.sendSignInLink(email: emailLink)
                            DispatchQueue.main.async {
                                showEmailLink = true
                            }
                        } catch {
                            debugPrint("🧨", "Firebase return an error on email link: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                firebaseError = error.localizedDescription
                                showEmailLinkFailed = true
                            }
                        }
                    }
                } label: {
                    Text("Create account with just an Email")
                        .DefaultTextButtonStyle()
                }
                Text("Or")
                Button {
                    authticationService.signInAnonymously()
                } label: {
                    Text("Login Anonymously")
                        .DefaultTextButtonStyle()
                }
            }
            .padding()
            .alert("Email or password invalid", isPresented: $showInvaildInput) {
                Button("Ok", role: .cancel) {  }
            } message: {
                Text("Email or password is empty")
            }
            .alert("Create user failed", isPresented: $showCreateUserFailed) {
                Button("Ok", role: .cancel) {  }
            } message: {
                Text("Firebase failed to create account, error: \(firebaseError)")
            }
            .alert("Email Link failed", isPresented: $showEmailLinkFailed) {
                Button("Ok", role: .cancel) {  }
            } message: {
                Text("Firebase failed to create email link, error: \(firebaseError)")
            }
            .alert("Email Link", isPresented: $showEmailLink) {
                Button("Ok", role: .cancel) {  }
            } message: {
                Text("Check your email for link to login")
            }
            .alert("Error", isPresented: $authticationService.showError) {
                Button("Ok", role: .cancel) {  }
            } message: {
                Text("Error: \(authticationService.errorMessage)")
            }
            .onReceive(userAuth.$state) { state in
                debugPrint("😍", "SignInView onReceive userAuth.state: \(state)")
                if authticationService.loginType == .apple && userAuth.state == .loggedIn {
                    DispatchQueue.main.async {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onOpenURL { url in
                Task {
                    await authticationService.handleSignInLink(url: url, email: emailLink)
                }
            }
        }
    }
}

#Preview {
    SignInView()
}
