//
//  FirebaseService.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 12/18/23.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFunctions
import FirebaseFirestoreSwift

let database = Firestore.firestore()

struct UserInformation: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var fcm: String
    var profileImage: String?
}

struct TestData: Codable, Identifiable {
    @DocumentID var id: String?
    var name:String
    var address: String
    var city: String
    var state: String
    var zipcode: String
}

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    @Published var users: [UserInformation] = []
    private var userListener: ListenerRegistration?
    @AppStorage("profile-url") var profileURL: String = ""
    
    func updateAddUserProfileImage(url: String) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let value = [
                        "profileImage" : url
                    ]
        do {
            try await database.collection("users").document(currentUid).updateData(value)
        } catch {
            debugPrint(String.boom, "updateAddUserProfileImage: \(error)")
        }
    }
    
    func updateAddUsersDocument(token: String?) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let currentEmail = Auth.auth().currentUser?.email
        let name = Auth.auth().currentUser?.displayName
        
        var values = [
                        "email" : currentEmail ?? "unknown",
                        "name" : name ?? "unknown",
                        "userId" : currentUid,
                        "profileImage" : profileURL
                     ]
        if token != nil {
            values["fcm"] = token
        }
        do {
            try await database.collection("users").document(currentUid).updateData(values)
            DispatchQueue.main.async {
                self.getUsers()
            }
        } catch {
            debugPrint(String.boom, "updateAddUsersDocument: \(error)")
            do {
                try await database.collection("users").document(currentUid).setData(values)
            } catch {
                debugPrint(String.boom, "uodateAddUsersDocument: \(error)")
            }
        }
        
    }
    
    func getUsers() {
        
        let listener = database.collection("users").whereField("email", isNotEqualTo: "").addSnapshotListener { querySnapshot, error in

            guard let documents = querySnapshot?.documents else {
                debugPrint(String.boom, "Users no documents")
                return
            }
            
            var items: [UserInformation] = []
            for document in documents {
                do {
                    let user = try document.data(as: UserInformation.self)
                    items.append(user)
                }
                catch {
                    debugPrint("🧨", "\(error.localizedDescription)")
                }
            }
            DispatchQueue.main.async {
                self.users = items
            }

        }
        userListener = listener
    }
    
    func callFirebaseCallableFunction(fcm: String, title: String, body: String, silent: Bool) {
        lazy var functions = Functions.functions()
        
        let payload = [
                        "silent": silent,
                        "fcm": fcm,
                        "title": title,
                        "body": body
        ] as [String : Any]
        functions.httpsCallable("sendNotification").call(payload) { result, error in
            if let error = error as NSError? {
                debugPrint(String.boom, error.localizedDescription)
            }
            if let data = result?.data {
                debugPrint("result: \(data)")
            }
            
        }
    }
    
    func writeTestData() {
        Task {
            do {
                var names = ["James", "Robert", "John", "Michael", "David", "William", "Richard", "Joseph", "Thomas", "Christopher", "Charles"]
                names.shuffle()
                let name = names.shuffled().first
                var cities = ["Washington", "Franklin", "Clinton", "Arlington", "Centerville", "Lebanon", "Georgetown", "Springfield", "Springfield", "Bristol", "Fairview", "Salem"]
                cities.shuffle()
                let city = cities.shuffled().first
                var states = ["Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"]
                states.shuffle()
                let state = states.shuffled().first
                
                let randomInt = Int.random(in: 1..<100)
                let randomInt2 = Int.random(in: 10000..<99999)
                try await database.collection("testData").addDocument(data: [
                    "name": name ?? "no name",
                    "address": "\(randomInt) Pine St",
                    "city": city ?? "no city",
                    "state": state ?? "no state",
                    "zipcode": "\(randomInt2)"
                ])
            } catch {
                debugPrint("🧨", "writeTestData failed: \(error.localizedDescription)")
            }
        }
    }
    
    func updateTestData() {
        database.document("testData/document1").updateData(["name": "Fred Smith"])
    }
    
    func readTestData() async -> TestData? {
        do {
            let testData = try await database.document("testData/document1").getDocument(as: TestData.self)
            return testData
        } catch {
            debugPrint("🧨", "readTestData failed: \(error.localizedDescription)")
            return nil
        }
    }

}
