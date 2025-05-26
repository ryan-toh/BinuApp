//
//  BinuAppApp.swift
//  BinuApp
//
//  Created by Ryan on 25/5/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Use Firebase library to configure APIs
    FirebaseApp.configure()
    return true
  }
}

@main
struct BinuAppApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
//            ContentView()
            TestUnifiedView()
        }
    }
}
