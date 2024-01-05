//
//  UserProfileView.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 1/5/24.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authticationService: AuthenticationService
    
    var body: some View {
        Form {
            Section {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "person.fill")
                            .resizable()
                            .frame(width: 100 , height: 100)
                            .aspectRatio(contentMode: .fit)
                            .clipShape(Circle())
                            .clipped()
                            .padding(4)
                            .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                        Spacer()
                    }
                    Button(action: {}) {
                        Text("edit")
                    }
                }
            }
            .listRowBackground(Color(UIColor.systemGroupedBackground))
            Section("Email") {
                VStack(alignment: .leading) {
                    Text("Name")
                        .font(.caption)
                    Text(authticationService.displayName)
                }
                VStack(alignment: .leading) {
                    Text("Email")
                        .font(.caption)
                    if let email = authticationService.user?.email {
                        Text(email)
                    } else {
                        Text("Unknown")
                    }
                }
                VStack(alignment: .leading) {
                    Text("UID")
                        .font(.caption)
                    Text(authticationService.user?.uid ?? "(unknown)")
                }
                VStack(alignment: .leading) {
                    Text("Anonymous / Guest user")
                        .font(.caption)
                    if let isAnonymous = authticationService.user?.isAnonymous {
                        Text(isAnonymous ? "Yes" : "No")
                    } else {
                        Text("No")
                    }
                }
                VStack(alignment: .leading) {
                    Text("Verified")
                        .font(.caption)
                    if let isVerified = authticationService.user?.isEmailVerified {
                        Text(isVerified ? "Yes" : "No")
                    } else {
                        Text("No")
                    }
                }
                VStack(alignment: .leading) {
                    Text("Service type")
                        .font(.caption)
                    Text(authticationService.loginType.rawValue)
                }
            }
        }
    }
}

#Preview {
    UserProfileView()
}
