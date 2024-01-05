//
//  ReadTestDataView.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 1/2/24.
//

import SwiftUI
import FirebaseFirestoreSwift

struct ReadTestDataView: View {
    @FirestoreQuery(collectionPath: "testData") var testData: [TestData]
    
    var body: some View {
        List {
            if $testData.error != nil {
                Text("There was an error: " + $testData.error!.localizedDescription)
            }
            ForEach(testData) { item in
                VStack(alignment: .leading) {
                    Text(item.name)
                    Text(item.address)
                    Text("\(item.city), \(item.state)")
                    Text("\(item.zipcode)")
                }
            }
            .onDelete(perform: delete)
        }
        .toolbar {
             EditButton()
         }
    }
    
    func delete(at offsets: IndexSet) {
//        users.remove(atOffsets: offsets)
    }
}

#Preview {
    ReadTestDataView()
}
