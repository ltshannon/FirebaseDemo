//
//  NotificationListView.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 12/18/23.
//

import SwiftUI

struct NotificationListView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var userAuth: Authentication
    @State var title: String = ""
    @State var bodyText: String = ""
    @State var silentToggle: Bool = false
    @State var showingAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Input values for title and body for notification")
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                TextField("Body", text: $bodyText)
                    .textFieldStyle(.roundedBorder)
                Toggle("Silent notification", isOn: $silentToggle)
                ScrollView {
                    ForEach (firebaseService.users) { user in
                        Button {
                            firebaseService.callFirebaseCallableFunction(fcm: user.fcm, title: title, body: bodyText, silent: silentToggle)
                        } label: {
                            HStack {
                                Text(user.email)
                                    .DefaultTextButtonStyle()
                                    .padding(.top, 20)
                            }
                        }
                    }
                    Spacer()
                }
            }
            .padding([.leading, .trailing], 20)
            .onReceive(userAuth.$silent) { silent in
                if silent {
                    showingAlert = true
                    userAuth.silent = false
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(userAuth.key1), message: Text(userAuth.key2), dismissButton: .default(Text("OK")))
            }
        }
        .navigationTitle(Text("Send Notification"))
    }
}
