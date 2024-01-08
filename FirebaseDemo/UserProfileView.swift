//
//  UserProfileView.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 1/5/24.
//

import SwiftUI
import PhotosUI
import NukeUI

struct UserProfileView: View {
    @EnvironmentObject var authticationService: AuthenticationService
    @State var avatarItem: PhotosPickerItem?
    @State var avatarImage: Image = Image(systemName: "person.crop.circle")
    @State var showErrorDownLoading = false
    @AppStorage("profile-url") var profileURL: String = ""
    var storageService = StorageService.share
    var firebaseService = FirebaseService.shared
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .center) {
                    if profileURL.isEmpty {
                        HStack {
                            Spacer()
                            avatarImage
                                .resizable()
                                .frame(width: 100 , height: 100)
                                .aspectRatio(contentMode: .fit)
                                .clipShape(Circle())
                                .clipped()
                                .padding(4)
                                .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                            Spacer()
                        }
                    } else {
                        HStack {
                            Spacer()
                            AsyncImage(url: URL(string: profileURL)) { image in
                                image.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height: 100)
                            .aspectRatio(contentMode: .fit)
                            .clipShape(Circle())
                            .clipped()
                            .padding(4)
                            .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                            Spacer()
                        }
                    }
                    PhotosPicker(selection: $avatarItem, matching: .images, photoLibrary: .shared()) {
                        Text("Pick a photo")
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
        .onChange(of: avatarItem) {
            Task {
                if let data = try? await avatarItem?.loadTransferable(type: Image.self) {
                    avatarImage = data
                } else {
                    showErrorDownLoading = true
                }
            }
            if let item = avatarItem {
                storageService.saveImage(item: item)
            }
        }
        .onReceive(storageService.$url) { url in
            if url.isNotEmpty {
                profileURL = url
                Task {
                    await firebaseService.updateAddUserProfileImage(url: url)
                }
            }
        }
        .alert("Error", isPresented: $showErrorDownLoading) {
            Button("Ok", role: .cancel) {
               
            }
        } message: {
            Text("Downloading image")
        }
    }

}

#Preview {
    UserProfileView()
}
