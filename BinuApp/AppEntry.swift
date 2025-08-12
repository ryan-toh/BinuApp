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
    var centralManager: CentralManager? // Your existing class
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        
        // Configure notificstions
        NotificationHelper.shared.configure()
        
        return true
    }
}


@main
struct AppEntry: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    // Start your CentralManager at launch
    @State private var centralManager = CentralManager()
    @State private var showCentralFromNotification = false
    
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
                } else {
                    MainTabView(centralManager: centralManager)
                        .environmentObject(authViewModel)
                        .environment(centralManager)
                }
            }
            .onAppear {
                authViewModel.listenForAuthChanges()
                centralManager.startScanning(serviceUUIDs: [centralManager.targetServiceUUID])
            }
            .onReceive(NotificationCenter.default.publisher(for: .openCentralFromNotification)) { _ in
                showCentralFromNotification = true
            }
            .sheet(isPresented: $showCentralFromNotification) {
                CentralView2(centralManager: centralManager)        
            }
        }
    }
}
