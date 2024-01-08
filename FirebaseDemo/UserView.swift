//
//  UserView.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 1/8/24.
//

import SwiftUI

struct UserView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    
    var body: some View {
        
        Section("Users") {
            List {
                ForEach(firebaseService.users, id: \.self) { user in
                    VStack(alignment: .leading) {
                        AsyncImage(url: URL(string: user.profileImage)) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 50, height: 50)
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                        .clipped()
                        .padding(4)
                    }
                    VStack(alignment: .leading) {
                        Text("Name")
                            .font(.caption)
                        Text(user.name)
                    }
                    VStack(alignment: .leading) {
                        Text("Email")
                            .font(.caption)
                        Text(user.email)
                    }
                    VStack(alignment: .leading) {
                        Text("FCM")
                            .font(.caption)
                        Text(user.fcm)
                    }
                    VStack(alignment: .leading) {
                        Text("userId")
                            .font(.caption)
                        Text(user.id ?? "not available")
                    }
                    VStack(alignment: .leading) {
                        Text("Profile image URL")
                            .font(.caption)
                        Text(user.profileImage)
                    }
                }
            }
        }
    }
}

#Preview {
    UserView()
}
