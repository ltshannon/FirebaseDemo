//
//  ContentView.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 11/7/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authticationService: AuthenticationService
    @EnvironmentObject var userAuth: Authentication
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var showSignIn: Bool = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink {
                    NotificationListView()
                } label: {
                    Text("Send notification to this device")
                        .DefaultTextButtonStyle()
                }
                NavigationLink {
                    APITestView()
                } label: {
                    Text("Test firebase http API calls")
                        .DefaultTextButtonStyle()
                }
                NavigationLink {
                    DemoFireStoreView()
                } label: {
                    Text("Demo FireStore")
                        .DefaultTextButtonStyle()
                }
                NavigationLink {
                    UserView()
                } label: {
                    Text("Users")
                        .DefaultTextButtonStyle()
                }
                if userAuth.isGuestUser {
                    Text("You are logged in under a Anonymous account")
                } else {
                    Text("You are logged on as : \(userAuth.email)")
                    Text("Under a \(authticationService.loginType.rawValue) account")
                }
            }
            .padding()
            .onAppear {
                debugPrint("😍", "ContentView onAppear userAtuh.state: \(userAuth.state.rawValue)")
                if userAuth.state == .loggedOut {
                    showSignIn = true
                }
            }
            .onChange(of: userAuth.state) { oldValue, newValue in
                debugPrint("😍", "ContentView onChange userAuth.state: oldValue \(oldValue) newValue: \(newValue)")
                if newValue == .loggedOut {
                    DispatchQueue.main.async {
                        showSignIn = true
                    }
                }
                if newValue == .loggedIn {
                    DispatchQueue.main.async {
                        showSignIn = false
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showSignIn) {
                SignInView()
            }
            .onReceive(userAuth.$fcmToken) { token in
                if token.isNotEmpty {
                    Task {
                        await firebaseService.updateAddUsersDocument(token: userAuth.fcmToken)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
