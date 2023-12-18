//
//  SignInView.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 11/7/23.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct SignInView: View {
    @EnvironmentObject var authticationService: AuthenticationService
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showInvaildInput = false
    @State private var showCreateUserFailed = false
    @State private var firebaseError = ""
    @ObservedObject var appleSignInService = AppleSignInService.shared
    
    var body: some View {
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
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        debugPrint("🧨", "Firebase return an error on Sign in: \(error)")
                        firebaseError = error.localizedDescription
                        showCreateUserFailed = true
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
                        presentationMode.wrappedValue.dismiss()
                        return
                    } catch {
                        debugPrint("🧨", "Firebase return an error on create user: \(error)")
                        firebaseError = error.localizedDescription
                        showCreateUserFailed = true
                    }
                }
            } label: {
                Text("Create account with a Email/Password")
                    .DefaultTextButtonStyle()
            }
            Text("Or")
            GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                Task {
                    do {
                        try await GoogleSignInService.shared.signInGoogle()
                        debugPrint("🦁", "user signed in with goolge")
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        print(error)
                    }
                }
            }
            Text("Or")
            Button(action: {
                appleSignInService.startSignInWithAppleFlow()
            }, label: {
                SignInWithAppleButtonViewRepresentable(type: .default, style: colorScheme == .dark ? .white : .black)
                    .frame(height: 55)
            })
            .onChange(of: appleSignInService.didSignInWithApple) { oldValue, newValue in
                if newValue == true {
                    debugPrint("🦁", "user signed in with apple")
                    presentationMode.wrappedValue.dismiss()
                }
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
    }
}

#Preview {
    SignInView()
}
