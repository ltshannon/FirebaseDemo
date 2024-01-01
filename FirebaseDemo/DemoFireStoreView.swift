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
        VStack {
            Button {
                Task {
                    firebaseService.writeTestData()
                }
            } label: {
                Text("Write to firestore")
                    .DefaultTextButtonStyle()
            }
            Button {
                Task {
                    if let data = await firebaseService.readTestData() {
                        debugPrint("", "testData: \(data)")
                    }
                }
            } label: {
                Text("Read from firestore")
                    .DefaultTextButtonStyle()
            }
            Button {
                firebaseService.updateTestData()
            } label: {
                Text("Update field in firestore")
                    .DefaultTextButtonStyle()
            }
        }
        .padding()
    }
}

#Preview {
    DemoFireStoreView()
}
