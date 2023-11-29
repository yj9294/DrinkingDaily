//
//  DrinkingDiaryApp.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/2.
//

import SwiftUI
import UIKit
import GADUtil
import ComposableArchitecture
import AppTrackingTransparency

@main
struct DrinkingDiaryApp: App {
    @UIApplicationDelegateAdaptor(Appdelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            RootView(store: Store(initialState: Root.State(), reducer: {
                Root()
            }))
        }
    }
    
    class Appdelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            UITabBar.appearance().isHidden = true
            NotificationHelper.shared.register()
            GADUtil.share.requestConfig()
            Task{
                try await Task.sleep(nanoseconds:2_000_000_000)
                Task.detached { @MainActor in
                    ATTrackingManager.requestTrackingAuthorization { _ in
                    }
                }
            }
            return true
        }
    }
}
