//
//  FirebaseDemoApp.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 11/7/23.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self

        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions) { _, _ in }
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        process(notification)
        completionHandler([[.banner, .sound]])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        process(response.notification)
        completionHandler()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        debugPrint("🧨", "Firebase fcm token: \(String(describing: fcmToken))")
        let tokenDict = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: tokenDict)
    }

    private func process(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            debugPrint("Error setBadgeCount: \(error.debugDescription)")
        }
        if let newsTitle = userInfo["newsTitle"] as? String,
           let newsBody = userInfo["newsBody"] as? String {
            let newsItem = NewsItem(title: newsTitle, body: newsBody, date: Date())
            NewsModel.shared.add([newsItem])
        }
    }
}

@main
struct FirebaseDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var userAuth = Authentication.shared
    @StateObject var authenticationService = AuthenticationService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationService)
                .environmentObject(userAuth)
        }
    }
}
