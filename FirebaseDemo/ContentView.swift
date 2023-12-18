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
    @State private var showSignIn: Bool = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Hello, world!")
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
        }
    }
}

#Preview {
    ContentView()
}
