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
    @State var requestBodyWrite: Data?
    @State var requestBodyRead: Data?
    @State var inputText = ""
    @State var outputText = ""
    var authentication = Authentication.shared
    
    var body: some View {
        VStack {
            TextField("Input text to write to firebase", text: $inputText)
                .textFieldStyle(.roundedBorder)
            Button {
                Task {
                    await networkService.callAPI(endpoint: .testWrite, requestBody: requestBodyWrite!)
                }
            } label: {
                Text("write")
                    .DefaultTextButtonStyle()
            }
            TextField("Data read from firebase", text: $outputText)
                .textFieldStyle(.roundedBorder)
            Button {
                Task {
                    await networkService.callAPI(endpoint: .testRead, requestBody: requestBodyRead!)
                }
            } label: {
                Text("read")
                    .DefaultTextButtonStyle()
            }
        }
        .padding()
        .onAppear {
            networkService.resetMessage()
            requestBodyWrite = try? JSONSerialization.data(withJSONObject: ["data" : inputText], options: [])
            requestBodyRead = try? JSONSerialization.data(withJSONObject: [], options: [])
        }
        .onChange(of: inputText) { oldValue, newValue in
            requestBodyWrite = try? JSONSerialization.data(withJSONObject: ["data" : newValue], options: [])
        }
        .onChange(of: networkService.message) { oldValue, newValue in
            outputText = newValue
        }
    }
}
