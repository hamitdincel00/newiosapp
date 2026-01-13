import Foundation

// MARK: - Author Response (List)
struct AuthorResponse: Codable {
    let data: [AuthorDetail]
    let error: Bool
    let message: String?
}

// MARK: - Author Detail Response (Single)
struct AuthorDetailResponse: Codable {
    let data: AuthorDetail
    let error: Bool
    let message: String?
}

// MARK: - Author Detail Model
struct AuthorDetail: Codable, Identifiable {
    let id: Int
    let name: String
    let image: PostImage?
    let slug: String?
    let description: String?
    let bio: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, image, slug, description, bio
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        slug = try container.decodeIfPresent(String.self, forKey: .slug)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        
        // image hem string hem de PostImage objesi olabilir
        if let imageString = try? container.decode(String.self, forKey: .image) {
            // String ise, basit bir PostImage oluştur
            image = PostImage(
                original: imageString,
                cropped: CroppedImages(
                    thumb: imageString,
                    medium: imageString,
                    large: imageString,
                    square: imageString,
                    vertical: imageString,
                    fives: imageString
                )
            )
        } else {
            image = try? container.decode(PostImage.self, forKey: .image)
        }
    }
    
    // Default görsel URL'i
    var imageURL: String {
        if let image = image, !image.cropped.large.isEmpty {
            return image.cropped.large
        }
        return "" // Placeholder URL yerine boş string döndür
    }
}

// MARK: - Author Articles Response
struct AuthorArticlesResponse: Codable {
    let data: [AuthorArticle]
    let error: Bool
    let message: String?
}

// MARK: - Author Article (List item - id, name ve görsel)
struct AuthorArticle: Codable, Identifiable {
    let id: Int
    let name: String
    let image: PostImage?
    
    enum CodingKeys: String, CodingKey {
        case id, name, image
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // image hem string hem de PostImage objesi olabilir
        if let imageString = try? container.decode(String.self, forKey: .image) {
            // String ise, basit bir PostImage oluştur
            image = PostImage(
                original: imageString,
                cropped: CroppedImages(
                    thumb: imageString,
                    medium: imageString,
                    large: imageString,
                    square: imageString,
                    vertical: imageString,
                    fives: imageString
                )
            )
        } else {
            image = try? container.decode(PostImage.self, forKey: .image)
        }
    }
    
    // Default görsel URL'i - boşsa nil döndür (placeholder kullanma)
    var imageURL: String? {
        if let image = image {
            return image.cropped.large
        }
        return nil
    }
}
