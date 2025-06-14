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
        FirebaseApp.configure()
        return true
    }
}

@main
struct AppEntry: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isCheckingAuthState {
                    LogoView()
                } else if authViewModel.user == nil {
                    WelcomeView()
                        .environmentObject(authViewModel)
                } else {
                    MainTabView()
                        .environmentObject(authViewModel)
                }
            }
            .onAppear {
                authViewModel.listenForAuthChanges()
            }
        }
    }
}
