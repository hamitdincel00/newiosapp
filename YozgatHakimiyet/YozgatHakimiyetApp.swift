//
//  YozgatHakimiyetApp.swift
//  YozgatHakimiyet
//
//  Created by Hamit DİNCEL  on 8.01.2026.
//

import SwiftUI
import UserNotifications

@main
struct YozgatHakimiyetApp: App {
    @StateObject private var oneSignalService = OneSignalService.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    // OneSignal'i initialize et
                    Task { @MainActor in
                        oneSignalService.initialize()
                    }
                    
                    // Push notification delegate'i ayarla
                    setupNotificationDelegate()
                }
        }
    }
    
    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // Foreground'da bildirim geldiğinde
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Bildirimi göster
        completionHandler([.banner, .sound, .badge])
    }
    
    // Bildirime tıklandığında
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Deep link işleme
        handleNotificationTap(userInfo: userInfo)
        
        completionHandler()
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // OneSignal'den gelen data'yı işle
        print("📱 NotificationDelegate - UserInfo: \(userInfo)")
        
        var urlString: String?
        
        // OneSignal format: custom -> a -> url
        if let additionalData = userInfo["custom"] as? [String: Any],
           let a = additionalData["a"] as? [String: Any],
           let url = a["url"] as? String {
            urlString = url
        }
        // Alternatif format: direkt url
        else if let url = userInfo["url"] as? String {
            urlString = url
        }
        // Alternatif format: additionalData içinde direkt url
        else if let additionalData = userInfo["additionalData"] as? [String: Any],
                let url = additionalData["url"] as? String {
            urlString = url
        }
        
        if let url = urlString {
            print("📱 NotificationDelegate - Opening URL: \(url)")
            // NavigationManager'a gönder
            Task { @MainActor in
                await NavigationManager.shared.handleURL(url)
            }
        } else {
            print("⚠️ NotificationDelegate - No URL found in notification")
        }
    }
}

