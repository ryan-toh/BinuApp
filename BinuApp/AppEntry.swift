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
import CoreBluetooth

// Runs in the background and before app launch
class AppDelegate: NSObject, UIApplicationDelegate {
    let centralManager = CentralManager()
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        centralManager.startScanning(serviceUUIDs: [centralManager.targetServiceUUID])
        
        // Configure notificstions
        NotificationHelper.shared.configure()
        
        return true
    }
}

// Main entry point for app
@main
struct AppEntry: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showCentralFromNotification = false

    // Global tab appearance setup
    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(named: "BGColor")

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(named: "FontColor")     // selected tab
        UITabBar.appearance().unselectedItemTintColor = .lightGray
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isCheckingAuthState {
                    LogoView()
                } else if authViewModel.user == nil {
                    WelcomeView()
                        .environmentObject(authViewModel)
                } else {
                    // Use the SAME CentralManager instance provided by the AppDelegate
                    MainTabView(centralManager: delegate.centralManager)
                        .environmentObject(authViewModel)
                        .environment(delegate.centralManager) // Observation framework injection
                }
            }
            .onAppear {
                authViewModel.listenForAuthChanges()
                // No need to start scanning here; AppDelegate did it already.
            }
            .onReceive(NotificationCenter.default.publisher(for: .openCentralFromNotification)) { _ in
                showCentralFromNotification = true
            }
            .sheet(isPresented: $showCentralFromNotification) {
                // Present the same shared instance in sheets as well
                CentralView2(centralManager: delegate.centralManager)
            }
        }
    }
}

