//
//  APITestView.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 12/26/23.
//

import SwiftUI

struct Language: Codable {
    var name: String
    var version: Int
}

struct APITestView: View {
    @EnvironmentObject var networkService: NetworkService
    @State var data: Data?
    
    var body: some View {
        VStack {
            Button {
                Task {
                    await networkService.callAPI(endpoint: .addFCMToken, requestBody: data!)
                }
            } label: {
                Text("Send")
                    .DefaultTextButtonStyle()
            }
        }
        .padding()
        .onAppear {
            let swift = Language(name: "Swift", version: 4)
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(swift) {
                data = encoded
            }
        }
    }
}
