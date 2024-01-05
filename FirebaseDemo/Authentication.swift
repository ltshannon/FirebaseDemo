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
    @Published var user: User?
    @Published var state: AuthState = .waiting
    @Published var fcmToken: String = ""
    @Published var firebaseUserId = ""
    @Published var email: String = ""
    @Published var silent: Bool = false
    @Published var key1: String = ""
    @Published var key2: String = ""
    @Published var isGuestUser = false
    var firebaseService = FirebaseService.shared
 
    enum AuthState: String {
        case waiting = "waiting"
        case accountSetup = "accountSetup"
        case loggedIn = "loggedIn"
        case loggedOut = "loggedOut"
    }
    
    init() {
       
        handler = Auth.auth().addStateDidChangeListener { auth, user in
            debugPrint("🛎️", "Authentication Firebase auth state changed, logged in: \(auth.userIsLoggedIn)")
            
            self.user = user
            
            DispatchQueue.main.async {
                self.isGuestUser = false
                if let isAnonymous = user?.isAnonymous {
                    self.isGuestUser = isAnonymous
                }
            }
            
            //case where user loggedin but waiting account setup
            guard self.state != .accountSetup else {
                return
            }
            
            //case where no user auth, likely first run
            guard let currentUser = auth.currentUser else {
                self.state = .loggedOut
                return
            }
            
            var email = ""
            if let temp = currentUser.email {
                email = temp
            }
            
            self.state = auth.userIsLoggedIn ? .loggedIn : .loggedOut
            
            switch self.state {
            case .waiting, .accountSetup:
                break
                
            case .loggedIn:
                DispatchQueue.main.async {
                    self.firebaseUserId = user?.uid ?? ""
                    self.authenticateUser(email)
                    self.email = email
                }
                Task {
                    await self.firebaseService.updateAddUsersDocument(token: self.fcmToken.isNotEmpty ? self.fcmToken : nil)
                }
                
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
        
        NotificationCenter.default.addObserver(forName: Notification.Name("silent"), object: nil, queue: nil) { notification in
            let key1 = notification.userInfo?["key1"] as? String ?? ""
            let key2 = notification.userInfo?["key2"] as? String ?? ""
            debugPrint("key1 \(key1)")
            debugPrint("key2 \(key2)")
            DispatchQueue.main.async {
                self.key1 = key1
                self.key2 = key2
                self.silent = true
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
