//
//  SettingsView.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 11/7/23.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authticationService: AuthenticationService
    @Environment(\.presentationMode) var presentationMode
    @State private var firebaseError = ""
    @State private var showFirebaseError = false
    @State private var showResetPassowrd = false
    
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink {
                    UserProfileView()
                } label: {
                    Text("User Profile")
                        .DefaultTextButtonStyle()
                }
                Button {
                    do {
                        try authticationService.signOut()
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        debugPrint("🧨", "Firebase signout failed")
                        firebaseError = error.localizedDescription
                    }
                } label: {
                    Text("Sign out")
                        .DefaultTextButtonStyle()
                }
                Button {
                    Task {
                        do {
                            try await authticationService.resetPassword()
                            DispatchQueue.main.async {
                                showResetPassowrd = true
                            }
                        } catch {
                            debugPrint("🧨", "Firebase reset password failed")
                            DispatchQueue.main.async {
                                firebaseError = error.localizedDescription
                            }
                        }
                    }
                } label: {
                    Text("Reset password")
                        .DefaultTextButtonStyle()
                }
                Button {
                    Task {
                        await authticationService.deleteAccount()
                    }
                    DispatchQueue.main.async {
                        presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    Text("Delete User Account")
                        .DefaultTextButtonStyle()
                }
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                        .DefaultTextButtonStyle()
                }
            }
            .padding()
            .alert("Email or password invalid", isPresented: $showFirebaseError) {
                Button("Ok", role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Firebase failed, error: \(firebaseError)")
            }
            .alert("Reset Passowrd", isPresented: $showResetPassowrd) {
                Button("Ok", role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Check your email for a reset password")
            }
        }
    }
}

#Preview {
    SettingsView()
}
