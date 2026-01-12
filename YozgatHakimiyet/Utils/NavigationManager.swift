import Foundation
import SwiftUI
import Combine

// MARK: - Navigation Destination
enum NavigationDestination: Identifiable {
    case post(postId: Int)
    case video(videoId: Int)
    case gallery(galleryId: Int)
    
    var id: String {
        switch self {
        case .post(let postId):
            return "post-\(postId)"
        case .video(let videoId):
            return "video-\(videoId)"
        case .gallery(let galleryId):
            return "gallery-\(galleryId)"
        }
    }
}

// MARK: - Navigation Manager
@MainActor
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var destination: NavigationDestination?
    @Published var shouldNavigate = false
    
    private let apiService = APIService.shared
    private let baseURL = Config.shared.baseURL
    
    private init() {}
    
    /// URL'yi parse edip navigation destination oluştur
    func handleURL(_ urlString: String) async {
        print("🔗 NavigationManager - Handling URL: \(urlString)")
        
        // URL'yi parse et
        guard let url = URL(string: urlString) else {
            print("❌ NavigationManager - Invalid URL: \(urlString)")
            return
        }
        
        let path = url.path
        let pathComponents = path.components(separatedBy: "/").filter { !$0.isEmpty }
        
        print("🔗 NavigationManager - Path components: \(pathComponents)")
        
        // URL tipini belirle
        if pathComponents.isEmpty {
            print("⚠️ NavigationManager - Empty path")
            return
        }
        
        // İlk component tipi belirler (videos, galleries, veya post slug)
        let firstComponent = pathComponents[0].lowercased()
        let slug = pathComponents.last ?? ""
        
        if firstComponent == "videos" || firstComponent == "video" {
            // Video URL'i
            if let videoId = await findVideoIdBySlug(slug) {
                print("✅ NavigationManager - Found video ID: \(videoId)")
                destination = .video(videoId: videoId)
                shouldNavigate = true
            } else {
                print("⚠️ NavigationManager - Could not find video ID for slug: \(slug)")
            }
        } else if firstComponent == "galleries" || firstComponent == "gallery" {
            // Gallery URL'i
            if let galleryId = await findGalleryIdBySlug(slug) {
                print("✅ NavigationManager - Found gallery ID: \(galleryId)")
                destination = .gallery(galleryId: galleryId)
                shouldNavigate = true
            } else {
                print("⚠️ NavigationManager - Could not find gallery ID for slug: \(slug)")
            }
        } else {
            // Post URL'i (default)
            if let postId = await findPostIdBySlug(slug) {
                print("✅ NavigationManager - Found post ID: \(postId)")
                destination = .post(postId: postId)
                shouldNavigate = true
            } else {
                print("⚠️ NavigationManager - Could not find post ID for slug: \(slug)")
            }
        }
    }
    
    /// Slug'dan post ID'sini bul
    private func findPostIdBySlug(_ slug: String) async -> Int? {
        do {
            // Önce slug ile direkt post çekmeyi dene
            // API'de slug ile post çekme endpoint'i yoksa, latest posts'tan arama yap
            let response = try await apiService.fetchLatestPosts(limit: 100)
            
            // Slug'a göre post bul
            if let post = response.data.first(where: { $0.slug == slug }) {
                return post.id
            }
            
            // Eğer bulunamazsa, URL'den ID çıkarmayı dene
            // Bazı URL'ler şu formatta olabilir: /posts/123
            if let id = Int(slug) {
                return id
            }
            
        } catch {
            print("❌ NavigationManager - Error finding post by slug: \(error)")
        }
        
        return nil
    }
    
    /// Slug'dan video ID'sini bul
    private func findVideoIdBySlug(_ slug: String) async -> Int? {
        do {
            let response = try await apiService.fetchLatestVideos(limit: 100)
            
            // Slug'a göre video bul
            if let video = response.data.first(where: { $0.slug == slug }) {
                return video.id
            }
            
            // Eğer bulunamazsa, URL'den ID çıkarmayı dene
            if let id = Int(slug) {
                return id
            }
            
        } catch {
            print("❌ NavigationManager - Error finding video by slug: \(error)")
        }
        
        return nil
    }
    
    /// Slug'dan gallery ID'sini bul
    private func findGalleryIdBySlug(_ slug: String) async -> Int? {
        do {
            let response = try await apiService.fetchLatestGalleries(limit: 100)
            
            // Slug'a göre gallery bul
            if let gallery = response.data.first(where: { $0.slug == slug }) {
                return gallery.id
            }
            
            // Eğer bulunamazsa, URL'den ID çıkarmayı dene
            if let id = Int(slug) {
                return id
            }
            
        } catch {
            print("❌ NavigationManager - Error finding gallery by slug: \(error)")
        }
        
        return nil
    }
    
    /// Navigation'ı temizle
    func clearNavigation() {
        destination = nil
        shouldNavigate = false
    }
}
