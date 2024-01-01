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
                Text("You are logged on as : \(userAuth.email)")
            }
            .padding()
            .onAppear {
                if userAuth.state == .loggedOut {
                    showSignIn = true
                }
            }
            .onChange(of: userAuth.state) { oldValue, newValue in
                if newValue == .loggedOut {
                    showSignIn = true
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
                        await firebaseService.updateUsersDocumentWithFCM(token: userAuth.fcmToken)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
