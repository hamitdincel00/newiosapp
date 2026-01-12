import SwiftUI
import UIKit

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        print("📋 ShareSheet - makeUIViewController called with \(items.count) items")
        for (index, item) in items.enumerated() {
            if let string = item as? String {
                print("📋 ShareSheet - Item \(index): String - \(string.prefix(100))")
            } else if let url = item as? URL {
                print("📋 ShareSheet - Item \(index): URL - \(url)")
            } else if item is UIImage {
                print("📋 ShareSheet - Item \(index): UIImage")
            } else {
                print("📋 ShareSheet - Item \(index): \(type(of: item))")
            }
        }
        
        // Boş items kontrolü - "Yozgat Hakimiyet" string'ini filtreleme, sadece boş string'leri filtrele
        let validItems = items.filter { item in
            if let string = item as? String {
                // Sadece boş string'leri filtrele, "Yozgat Hakimiyet" geçerli bir paylaşım içeriği olabilir
                let isValid = !string.isEmpty
                if !isValid {
                    print("📋 ShareSheet - Filtered out empty string")
                }
                return isValid
            }
            if let url = item as? URL {
                return !url.absoluteString.isEmpty
            }
            return true
        }
        
        print("📋 ShareSheet - After filtering: \(validItems.count) valid items")
        
        // Eğer items boşsa, hata ver
        guard !validItems.isEmpty else {
            print("❌ ShareSheet - No valid items to share!")
            // En azından bir placeholder ekle
            let placeholderItems: [Any] = ["Yozgat Hakimiyet"]
            let controller = UIActivityViewController(
                activityItems: placeholderItems,
                applicationActivities: nil
            )
            return controller
        }
        
        let controller = UIActivityViewController(
            activityItems: validItems,
            applicationActivities: nil
        )
        
        // iPad için popover desteği
        if let popover = controller.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        
        // Completion handler - sheet'i kapat
        controller.completionWithItemsHandler = { _, _, _, _ in
            DispatchQueue.main.async {
                isPresented = false
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        print("📋 ShareSheet - updateUIViewController called with \(items.count) items")
    }
}

// MARK: - Share Helper
struct ShareHelper {
    
    /// Haber paylaşma fonksiyonu - iOS native paylaşım sistemi (doğrudan paylaşım açar)
    static func sharePost(title: String, url: String, imageUrl: String?, onViewController: UIViewController? = nil, completion: @escaping ([Any]) -> Void) {
        // URL'yi tam URL'ye çevir (eğer relative ise)
        let fullURL: String
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            fullURL = url
        } else {
            // Base URL ile birleştir
            let baseURL = Config.shared.baseURL
            fullURL = url.hasPrefix("/") ? "\(baseURL)\(url)" : "\(baseURL)/\(url)"
        }
        
        print("🔗 ShareHelper - Title: \(title)")
        print("🔗 ShareHelper - URL: \(fullURL)")
        print("🔗 ShareHelper - ImageURL: \(imageUrl ?? "nil")")
        
        // Görseli indirip ekle (opsiyonel, async)
        if let imageUrl = imageUrl, !imageUrl.isEmpty, let imageURL = URL(string: imageUrl) {
            print("🔗 ShareHelper - Downloading image...")
            downloadImage(from: imageURL) { image in
                var itemsToShare: [Any] = []
                
                // Görsel varsa ekle
                if let image = image {
                    print("🔗 ShareHelper - Image downloaded successfully")
                    itemsToShare.append(image)
                } else {
                    print("🔗 ShareHelper - Image download failed")
                }
                
                // Başlık ve URL kombinasyonu
                let shareText = "\(title)\n\n\(fullURL)"
                itemsToShare.append(shareText)
                print("🔗 ShareHelper - Added text: \(shareText)")
                
                // URL'yi ayrı olarak da ekle (bazı uygulamalar için)
                if let shareURL = URL(string: fullURL) {
                    itemsToShare.append(shareURL)
                    print("🔗 ShareHelper - Added URL: \(shareURL)")
                }
                
                print("🔗 ShareHelper - Total items: \(itemsToShare.count)")
                
                // Doğrudan paylaşım aç
                DispatchQueue.main.async {
                    presentShareSheet(items: itemsToShare, onViewController: onViewController)
                }
                
                completion(itemsToShare)
            }
        } else {
            // Görsel yoksa sadece metin ve URL
            var itemsToShare: [Any] = []
            
            // Başlık ve URL kombinasyonu
            let shareText = "\(title)\n\n\(fullURL)"
            itemsToShare.append(shareText)
            print("🔗 ShareHelper - Added text (no image): \(shareText)")
            
            // URL'yi ayrı olarak da ekle
            if let shareURL = URL(string: fullURL) {
                itemsToShare.append(shareURL)
                print("🔗 ShareHelper - Added URL (no image): \(shareURL)")
            }
            
            print("🔗 ShareHelper - Total items (no image): \(itemsToShare.count)")
            
            // Doğrudan paylaşım aç
            DispatchQueue.main.async {
                presentShareSheet(items: itemsToShare, onViewController: onViewController)
            }
            
            completion(itemsToShare)
        }
    }
    
    /// Paylaşım sheet'ini doğrudan açar
    private static func presentShareSheet(items: [Any], onViewController: UIViewController?) {
        guard !items.isEmpty else {
            print("❌ ShareHelper - Cannot present share sheet: items is empty")
            return
        }
        
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // iPad için popover desteği
        if let popover = controller.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        
        // ViewController bul ve present et
        if let viewController = onViewController {
            viewController.present(controller, animated: true)
        } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController {
            // En üstteki view controller'ı bul
            var topViewController = rootViewController
            while let presented = topViewController.presentedViewController {
                topViewController = presented
            }
            topViewController.present(controller, animated: true)
        }
    }
    
    /// Galeri paylaşma fonksiyonu
    static func shareGallery(title: String, url: String, imageUrl: String?, completion: @escaping ([Any]) -> Void) {
        sharePost(title: title, url: url, imageUrl: imageUrl, completion: completion)
    }
    
    /// Görsel indirme fonksiyonu
    private static func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, 
                  error == nil, 
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
