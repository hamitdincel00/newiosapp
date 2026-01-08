import Foundation

class APIService {
    static let shared = APIService()
    private let config = Config.shared
    
    private init() {}
    
    private func buildURL(endpoint: String) -> URL? {
        let urlString = "\(config.baseURL)/api/v2/\(endpoint)?apiKey=\(config.apiKey)"
        return URL(string: urlString)
    }
    
    private func performRequest<T: Decodable>(url: URL, responseType: T.Type) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // HTTP status kontrolü
        if let httpResponse = response as? HTTPURLResponse {
            // Content-Type kontrolü
            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? ""
            let isHTML = contentType.contains("text/html") || contentType.contains("text/plain")
            
            // HTML yanıt kontrolü (hem status hem de content-type)
            if httpResponse.statusCode >= 400 || isHTML {
                let responseString = String(data: data, encoding: .utf8) ?? ""
                if responseString.trimmingCharacters(in: .whitespaces).hasPrefix("<") || isHTML {
                    print("API Error - HTML response received. Status: \(httpResponse.statusCode), URL: \(url.absoluteString)")
                    throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned HTML instead of JSON"])
                }
                
                // JSON error response kontrolü
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let message = errorJson["message"] as? String {
                        print("API Error - Status: \(httpResponse.statusCode), Message: \(message)")
                    }
                } else if !responseString.isEmpty {
                    print("API Error - Status: \(httpResponse.statusCode), Response: \(responseString.prefix(300))")
                }
                
                throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
            }
        }
        
        // JSON decode
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Decoding Error - Response: \(jsonString.prefix(500))")
            }
            throw error
        }
    }
    
    // MARK: - Posts
    
    func fetchPosts() async throws -> PostResponse {
        guard let url = buildURL(endpoint: "posts") else {
            throw URLError(.badURL)
        }
        return try await performRequest(url: url, responseType: PostResponse.self)
    }
    
    func fetchHeadlines() async throws -> PostResponse {
        guard let url = buildURL(endpoint: "posts/headlines") else {
            throw URLError(.badURL)
        }
        return try await performRequest(url: url, responseType: PostResponse.self)
    }
    
    func fetchTopHeadlines() async throws -> PostResponse {
        guard let url = buildURL(endpoint: "posts/topheadlines") else {
            throw URLError(.badURL)
        }
        return try await performRequest(url: url, responseType: PostResponse.self)
    }
    
    func fetchBreakingNews() async throws -> PostResponse {
        guard let url = buildURL(endpoint: "posts/breaking") else {
            throw URLError(.badURL)
        }
        return try await performRequest(url: url, responseType: PostResponse.self)
    }
    
    func fetchLatestPosts(limit: Int? = nil) async throws -> PostResponse {
        let endpoint = limit != nil ? "posts/latest/\(limit!)" : "posts/latest"
        guard let url = buildURL(endpoint: endpoint) else {
            throw URLError(.badURL)
        }
        return try await performRequest(url: url, responseType: PostResponse.self)
    }
    
    func fetchFeaturedPosts() async throws -> PostResponse {
        guard let url = buildURL(endpoint: "posts/featured") else {
            throw URLError(.badURL)
        }
        return try await performRequest(url: url, responseType: PostResponse.self)
    }
    
    func fetchPostDetail(id: Int) async throws -> PostDetailResponse {
        guard let url = buildURL(endpoint: "posts/\(id)") else {
            throw URLError(.badURL)
        }
        return try await performRequest(url: url, responseType: PostDetailResponse.self)
    }
    
    func searchPosts(query: String) async throws -> PostResponse {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = buildURL(endpoint: "posts/search/\(encodedQuery)") else {
            throw URLError(.badURL)
        }
        return try await performRequest(url: url, responseType: PostResponse.self)
    }
    
    // MARK: - Galleries
    
    func fetchGalleries() async throws -> GalleryResponse {
        guard let url = buildURL(endpoint: "galleries") else {
            throw URLError(.badURL)
        }
        return try await performRequest(url: url, responseType: GalleryResponse.self)
    }
    
    func fetchLatestGalleries(limit: Int? = nil) async throws -> GalleryResponse {
        let endpoint = limit != nil ? "galleries/latest/\(limit!)" : "galleries/latest"
        guard let url = buildURL(endpoint: endpoint) else {
            throw URLError(.badURL)
        }
        return try await performRequest(url: url, responseType: GalleryResponse.self)
    }
    
    func fetchFeaturedGalleries() async throws -> GalleryResponse {
        guard let url = buildURL(endpoint: "galleries/featured") else {
            throw URLError(.badURL)
        }
        return try await performRequest(url: url, responseType: GalleryResponse.self)
    }
    
    func fetchGalleryDetail(id: Int) async throws -> GalleryDetailResponse {
        guard let url = buildURL(endpoint: "galleries/\(id)") else {
            throw URLError(.badURL)
        }
        return try await performRequest(url: url, responseType: GalleryDetailResponse.self)
    }
}

