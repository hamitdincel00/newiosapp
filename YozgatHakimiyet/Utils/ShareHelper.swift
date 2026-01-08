import SwiftUI
import UIKit

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Share Helper
struct ShareHelper {
    
    /// Haber paylaşma fonksiyonu
    static func sharePost(title: String, url: String, imageUrl: String?, completion: @escaping ([Any]) -> Void) {
        var itemsToShare: [Any] = [title, URL(string: url)].compactMap { $0 }
        
        // Görseli indirip ekle
        if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            downloadImage(from: url) { image in
                if let image = image {
                    itemsToShare.insert(image, at: 0)
                }
                completion(itemsToShare)
            }
        } else {
            completion(itemsToShare)
        }
    }
    
    /// Galeri paylaşma fonksiyonu
    static func shareGallery(title: String, url: String, imageUrl: String?, completion: @escaping ([Any]) -> Void) {
        sharePost(title: title, url: url, imageUrl: imageUrl, completion: completion)
    }
    
    /// Görsel indirme fonksiyonu
    private static func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
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
