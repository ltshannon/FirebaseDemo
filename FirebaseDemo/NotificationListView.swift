//
//  NotificationListView.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 12/18/23.
//

import SwiftUI

struct NotificationListView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State var title: String = ""
    @State var bodyText: String = ""
    @State var silent: Bool = true
    @State var silentToggle: Bool = false
    
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
                            firebaseService.callFirebaseCallableFunction(fcm: user.fcm, title: title, body: bodyText, silent: silent)
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
        }
        .navigationTitle(Text("Send Notification"))
    }
}
