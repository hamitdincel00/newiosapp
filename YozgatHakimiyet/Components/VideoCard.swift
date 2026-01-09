import SwiftUI

struct VideoCard: View {
    let video: Video
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail with play button overlay
            ZStack {
                AsyncImage(url: URL(string: video.image.cropped.medium)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(ProgressView())
                }
                .frame(width: 120, height: 100)
                .cornerRadius(10)
                .clipped()
                
                // Play button overlay
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(video.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                
                // Description if available
                if let description = video.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                HStack {
                    // Category
                    if let firstCategory = video.categories.values.first {
                        Text(firstCategory)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Date
                    Text(video.createdAt.prefix(10))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
