//
//  Authentication.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 11/7/23.
//

import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAuth
import UserNotifications

//Class to manage firebase configuration and backend authentication
@MainActor
class Authentication: ObservableObject {
    static let shared = Authentication()
    private var handler: AuthStateDidChangeListenerHandle? = nil
    @Published var state: AuthState = .waiting
    @Published var fcmToken: String = ""
    @Published var email: String = ""
 
    enum AuthState {
        case waiting
        case accountSetup
        case loggedIn
        case loggedOut
    }
    
    init() {
       
        handler = Auth.auth().addStateDidChangeListener { auth, user in
            debugPrint("🛎️", "Firebase auth state changed, logged in: \(auth.userIsLoggedIn)")
            
            //case where user loggedin but waiting account setup
            guard self.state != .accountSetup else {
                return
            }
            
            //case where no user auth, likely first run
            guard let currentUser = auth.currentUser else {
                self.state = .loggedOut
                return
            }
            
            //bad state, force user to log in again
            guard let email = currentUser.email else {
                self.state = .loggedOut
                return
            }
            
            self.state = auth.userIsLoggedIn ? .loggedIn : .loggedOut
            
            switch self.state {
            case .waiting, .accountSetup:
                break
                
            case .loggedIn:
                self.authenticateUser(email)
                self.email = email
                
            case .loggedOut:
                break
            }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("FCMToken"), object: nil, queue: nil) { notification in
            let newToken = notification.userInfo?["token"] as? String ?? ""
            Task {
                await MainActor.run {
                    self.fcmToken = newToken
                }
            }
        }
        
    }
    
    func authenticateUser(_ email: String) {
        
    }
    
    deinit {
        if let handler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
}

extension Auth {
    var userIsLoggedIn: Bool {
        currentUser != nil
    }
}
