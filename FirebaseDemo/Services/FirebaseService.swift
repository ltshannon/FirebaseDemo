//
//  FirebaseService.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 12/18/23.
//

import Foundation
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
    
    func updateUsersDocumentWithFCM(token: String) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let currentEmail = Auth.auth().currentUser?.email
        let name = Auth.auth().currentUser?.displayName
        
        let values = [
                        "fcm" : token,
                        "email" : currentEmail ?? "",
                        "name" : name ?? "",
                     ]
        do {
            try await database.collection("users").document(currentUid).updateData(values)
            await getUsers()
        } catch {
            debugPrint(String.boom, "updateUsersDocumentWithFCM: \(error)")
            do {
                try await database.collection("users").document(currentUid).setData(values)
            } catch {
                debugPrint(String.boom, "setUsersDocumentWithFCM: \(error)")
            }
        }
        
    }
    
    func getUsers() async  {
        
        let listener = database.collection("users").whereField("email", isNotEqualTo: "").addSnapshotListener { querySnapshot, error in

            guard let documents = querySnapshot?.documents else {
                debugPrint(String.boom, "gerUsers no documents")
                return
            }
            
            var users: [UserInformation] = []
            for document in documents {
                do {
                    let user = try document.data(as: UserInformation.self)
                    users.append(user)
                }
                catch {
                    print(error)
                }
            }
            self.users = users

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
        let testData = TestData(name: "Joe Cool",
                                address: "1 Pine St",
                                city: "Boulder",
                                state: "CO",
                                zipcode: "82121")
        
        do {
            try database.document("testData/document1").setData(from: testData)
        } catch {
            debugPrint("🧨", "writeTestData failed: \(error.localizedDescription)")
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
