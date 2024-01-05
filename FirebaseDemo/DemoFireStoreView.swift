//
//  DemoFireStoreView.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 12/30/23.
//

import SwiftUI

struct DemoFireStoreView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    var body: some View {
        NavigationStack {
            VStack {
                Button {
                    Task {
                        firebaseService.writeTestData()
                    }
                } label: {
                    Text("Write to firestore")
                        .DefaultTextButtonStyle()
                }
                NavigationLink {
                    ReadTestDataView()
                } label: {
                    Text("Read Test Data from firestore")
                        .DefaultTextButtonStyle()
                }
                Button {
                    firebaseService.updateTestData()
                } label: {
                    Text("Update field in firestore")
                        .DefaultTextButtonStyle()
                }
            }
        }
        .padding()
    }
}

#Preview {
    DemoFireStoreView()
}
