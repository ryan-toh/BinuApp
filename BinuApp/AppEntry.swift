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

//class AppDelegate: NSObject, UIApplicationDelegate {
//    var centralManager: CentralManager? // Your existing class
//    
//    func application(_ application: UIApplication,
//                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        
//        FirebaseApp.configure()
//        
//        // Configure notificstions
//        NotificationHelper.shared.configure()
//        
//        return true
//    }
//}
//
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


//@main
//struct AppEntry: App {
//    @State private var scanningUUIDs: [CBUUID]? = [CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")]
//    @State private var allowDuplicateKey: Bool = false
//    @State private var solicitedServiceUUIDs: [CBUUID] = [CBUUID(string: "E100")]
//    
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    @StateObject private var authViewModel = AuthViewModel()
//    // Start your CentralManager at launch
//    @State private var centralManager = CentralManager()
//    @State private var showCentralFromNotification = false
//    
//    // eungi: setting OVERALL COLOR THEME
//    init() {
//        let tabBarAppearance = UITabBarAppearance()
//        tabBarAppearance.configureWithOpaqueBackground()
//        tabBarAppearance.backgroundColor = UIColor(named: "BGColor")
//
//        UITabBar.appearance().standardAppearance = tabBarAppearance
//        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
//
//        UITabBar.appearance().tintColor = UIColor(named: "FontColor") // selected tab
//        UITabBar.appearance().unselectedItemTintColor = UIColor.lightGray
//    }
//    // eungi: END
//
//    var body: some Scene {
//        WindowGroup {
//            Group {
//                if authViewModel.isCheckingAuthState {
//                    LogoView()
//                } else if authViewModel.user == nil {
//                    WelcomeView()
//                        .environmentObject(authViewModel)
//                } else {
//                    MainTabView(centralManager: centralManager)
//                        .environmentObject(authViewModel)
//                }
//            }
//            .onAppear {
//                authViewModel.listenForAuthChanges()
//                centralManager.startScanning(
//                    serviceUUIDs: scanningUUIDs,
//                    allowDuplicateKey: allowDuplicateKey,
//                    solicitedServiceUUIDs: solicitedServiceUUIDs
//                )
////                centralManager.startScanning(serviceUUIDs: [centralManager.targetServiceUUID])
//            }
//            .onReceive(NotificationCenter.default.publisher(for: .openCentralFromNotification)) { _ in
//                showCentralFromNotification = true
//            }
//            .sheet(isPresented: $showCentralFromNotification) {
//                CentralView2(centralManager: centralManager)        
//            }
//        }
//    }
//}

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

