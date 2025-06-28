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
    @StateObject private var beaconMonitor = ReceiverService() // create global ReceiverService
    
    // eungi: setting OVERALL COLOR THEME
    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(named: "BGColor")

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        UITabBar.appearance().tintColor = UIColor(named: "FontColor") // selected tab
        UITabBar.appearance().unselectedItemTintColor = UIColor.lightGray
    }
    // eungi: END

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isCheckingAuthState {
                    LogoView()
                } else if authViewModel.user == nil {
                    WelcomeView()
                        .environmentObject(authViewModel)
                        .environmentObject(beaconMonitor) // inject ReceiverService here
                } else {
                    MainTabView()
                        .environmentObject(authViewModel)
                        .environmentObject(beaconMonitor) // inject ReceiverService here
                        .onAppear {
                            // This ensures monitoring starts only when signed in
                            _ = beaconMonitor
                        }
                }
            }
            .onAppear {
                authViewModel.listenForAuthChanges()
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    // Handle granted/error if needed
                }
            }
            .environmentObject(beaconMonitor) // inject globally to all views in Group (optional but safe)\
        }
    }
}
