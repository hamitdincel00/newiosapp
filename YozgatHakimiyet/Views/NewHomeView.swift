import SwiftUI
import Combine

struct NewHomeView: View {
    @Binding var showSideMenu: Bool
    @StateObject private var viewModel = NewHomeViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Featured Post
                    if let featuredPost = viewModel.featuredPosts.first {
                        FeaturedPostSection(post: featuredPost)
                    }
                    
                    // Latest Videos Carousel
                    if !viewModel.latestVideos.isEmpty {
                        VideoCarouselSection(videos: viewModel.latestVideos)
                    }
                    
                    // Latest Galleries Carousel
                    if !viewModel.latestGalleries.isEmpty {
                        GalleryCarouselSection(galleries: viewModel.latestGalleries)
                    }
                    
                    // Quick Access Widgets
                    QuickAccessSection()
                    
                    // Latest News
                    LatestNewsSection(posts: viewModel.latestPosts)
                }
            }
            .navigationTitle("Ana Sayfa")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation {
                            showSideMenu.toggle()
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
            }
            .refreshable {
                await viewModel.loadAllContent()
            }
            .task {
                await viewModel.loadAllContent()
            }
        }
    }
}

// MARK: - Featured Post Section
struct FeaturedPostSection: View {
    let post: Post
    
    var body: some View {
        NavigationLink(destination: PostDetailView(postId: post.id)) {
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: post.image.cropped.large)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(ProgressView())
                    }
                    .frame(width: geometry.size.width, height: 250)
                    .clipped()
                    
                    // Gradient overlay
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ÖNE ÇIKAN")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(4)
                        
                        Text(post.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(3)
                    }
                    .padding()
                }
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
            .frame(height: 250)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

// MARK: - Video Carousel Section
struct VideoCarouselSection: View {
    let videos: [Video]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .foregroundColor(.red)
                Text("Son Videolar")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink(destination: VideoListView(showSideMenu: .constant(false))) {
                    Text("Tümü")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(videos.prefix(5)) { video in
                        NavigationLink(destination: VideoDetailView(videoId: video.id)) {
                            VideoCarouselCard(video: video)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct VideoCarouselCard: View {
    let video: Video
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                .frame(width: 200, height: 120)
                .cornerRadius(10)
                .clipped()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 3)
            }
            
            Text(video.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(width: 200, alignment: .leading)
        }
    }
}

// MARK: - Gallery Carousel Section
struct GalleryCarouselSection: View {
    let galleries: [Gallery]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.on.rectangle")
                    .foregroundColor(.blue)
                Text("Foto Galeriler")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink(destination: GalleryListView(showSideMenu: .constant(false))) {
                    Text("Tümü")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(galleries.prefix(5)) { gallery in
                        NavigationLink(destination: GalleryDetailView(galleryId: gallery.id)) {
                            GalleryCarouselCard(gallery: gallery)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct GalleryCarouselCard: View {
    let gallery: Gallery
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: gallery.image.cropped.medium)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(ProgressView())
            }
            .frame(width: 200, height: 120)
            .cornerRadius(10)
            .clipped()
            
            Text(gallery.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(width: 200, alignment: .leading)
        }
    }
}

// MARK: - Quick Access Section
struct QuickAccessSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.orange)
                Text("Hızlı Erişim")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            
            HStack(spacing: 12) {
                NavigationLink(destination: WeatherDetailView(showSideMenu: .constant(false))) {
                    QuickAccessButtonContent(icon: "cloud.sun.fill", title: "Hava", color: .blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: PrayerTimesDetailView(showSideMenu: .constant(false))) {
                    QuickAccessButtonContent(icon: "moon.stars.fill", title: "Namaz", color: .purple)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: CurrencyDetailView(showSideMenu: .constant(false))) {
                    QuickAccessButtonContent(icon: "dollarsign.circle.fill", title: "Döviz", color: .green)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: PharmacyDetailView(showSideMenu: .constant(false))) {
                    QuickAccessButtonContent(icon: "cross.case.fill", title: "Eczane", color: .red)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
        }
    }
}

struct QuickAccessButtonContent: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Latest News Section
struct LatestNewsSection: View {
    let posts: [Post]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "newspaper.fill")
                    .foregroundColor(.red)
                Text("Son Haberler")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 16) {
                ForEach(posts) { post in
                    NavigationLink(destination: PostDetailView(postId: post.id)) {
                        PostCard(post: post)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - ViewModel
@MainActor
class NewHomeViewModel: ObservableObject {
    @Published var featuredPosts: [Post] = []
    @Published var latestVideos: [Video] = []
    @Published var latestGalleries: [Gallery] = []
    @Published var latestPosts: [Post] = []
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    
    func loadAllContent() async {
        isLoading = true
        
        async let featured = try? apiService.fetchFeaturedPosts()
        async let videos = try? apiService.fetchLatestVideos(limit: 5)
        async let galleries = try? apiService.fetchLatestGalleries(limit: 5)
        async let posts = try? apiService.fetchLatestPosts(limit: 10)
        
        let (featuredResult, videosResult, galleriesResult, postsResult) = await (featured, videos, galleries, posts)
        
        if let featuredResult = featuredResult {
            featuredPosts = featuredResult.data
        }
        
        if let videosResult = videosResult {
            latestVideos = videosResult.data
        }
        
        if let galleriesResult = galleriesResult {
            latestGalleries = galleriesResult.data
        }
        
        if let postsResult = postsResult {
            latestPosts = postsResult.data
        }
        
        isLoading = false
    }
}
