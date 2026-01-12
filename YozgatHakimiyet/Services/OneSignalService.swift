import Foundation
import Combine
import UserNotifications
import UIKit
import OneSignalFramework

// MARK: - OneSignal Service
@MainActor
class OneSignalService: ObservableObject {
    static let shared = OneSignalService()
    
    @Published var isInitialized = false
    @Published var pushToken: String?
    @Published var userId: String?
    
    private let oneSignalAppId: String
    
    private init() {
        // OneSignal App ID'yi Config'den veya Info.plist'ten al
        if let appId = Bundle.main.object(forInfoDictionaryKey: "ONESIGNAL_APP_ID") as? String, !appId.isEmpty {
            self.oneSignalAppId = appId
        } else {
            // Fallback - OneSignal dashboard'dan alınacak App ID buraya eklenecek
            // Geçici olarak boş string, Info.plist'ten yüklenecek
            self.oneSignalAppId = ""
        }
    }
    
    /// OneSignal'i initialize et
    func initialize() {
        guard !oneSignalAppId.isEmpty else {
            print("⚠️ OneSignalService - App ID bulunamadı. Info.plist'e ONESIGNAL_APP_ID ekleyin.")
            return
        }
        
        print("📱 OneSignalService - Initializing with App ID: \(oneSignalAppId)")
        
        // OneSignal'i initialize et
        OneSignal.initialize(oneSignalAppId, withLaunchOptions: nil)
        
        // Push notification izinlerini iste
        OneSignal.Notifications.requestPermission({ accepted in
            if accepted {
                print("✅ OneSignal - Push notification permission granted")
            } else {
                print("⚠️ OneSignal - Push notification permission denied")
            }
        }, fallbackToSettings: false)
        
        isInitialized = true
    }
    
    
    /// Push token'ı kaydet
    func setPushToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        self.pushToken = tokenString
        print("📱 OneSignalService - Push token received: \(tokenString)")
        
        // OneSignal'e token'ı gönder (OneSignal otomatik olarak token'ı alır, bu fonksiyon opsiyonel)
    }
    
    /// User ID'yi kaydet
    func setUserId(_ userId: String) {
        self.userId = userId
        print("📱 OneSignalService - User ID set: \(userId)")
        
        // OneSignal'e user ID'yi gönder
        OneSignal.login(userId)
    }
    
    /// Tag ekle
    func addTag(key: String, value: String) {
        print("📱 OneSignalService - Adding tag: \(key) = \(value)")
        OneSignal.User.addTags([key: value])
    }
    
    /// Tag sil
    func removeTag(key: String) {
        print("📱 OneSignalService - Removing tag: \(key)")
        OneSignal.User.removeTags([key])
    }
}
