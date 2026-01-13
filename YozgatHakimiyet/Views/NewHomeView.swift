import SwiftUI
import Combine

struct NewHomeView: View {
    @Binding var showSideMenu: Bool
    @StateObject private var viewModel = NewHomeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.headlines.isEmpty && viewModel.latestPosts.isEmpty {
                    // İlk yükleme ekranı
                    VStack(spacing: 20) {
                        // Logo
                        LogoView()
                            .padding(.bottom, 20)
                        
                        // Loading Indicator
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.blue)
                        
                        Text("Yükleniyor...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Normal içerik
                    ScrollView {
                        VStack(spacing: 20) {
                            // Manşetler Slider
                            if !viewModel.headlines.isEmpty {
                                HeadlinesSliderView(headlines: viewModel.headlines)
                                    .frame(height: 380)
                                    .padding(.bottom, 10)
                            }
                            
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
                            
                            // Authors Section
                            if !viewModel.authors.isEmpty {
                                AuthorsSection(authors: viewModel.authors, showSideMenu: $showSideMenu)
                            }
                            
                            // Quick Access Widgets
                            QuickAccessSection()
                            
                            // Latest News
                            LatestNewsSection(posts: viewModel.latestPosts)
                            
                            // Popular Posts (Çok Okunanlar)
                            if !viewModel.popularPosts.isEmpty {
                                PopularPostsSection(posts: viewModel.popularPosts)
                            }
                            
                            // Footer
                            AppFooter()
                                .padding(.top, 20)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    LogoView()
                }
                
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

// MARK: - Headlines Slider View
struct HeadlinesSliderView: View {
    let headlines: [Post]
    @State private var currentIndex = 0
    @State private var timer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                TabView(selection: $currentIndex) {
                    ForEach(Array(headlines.prefix(10).enumerated()), id: \.element.id) { index, headline in
                        NavigationLink(destination: PostDetailView(postId: headline.id)) {
                            ZStack(alignment: .bottomLeading) {
                                AsyncImage(url: URL(string: headline.image.cropped.large)) { phase in
                                    switch phase {
                                    case .empty:
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .overlay(ProgressView().tint(.white))
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure:
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.gray)
                                            )
                                    @unknown default:
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                }
                                .frame(width: geometry.size.width, height: 380)
                                .clipped()
                                
                                // Gradient Overlay - Daha dramatik
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.black.opacity(0.3),
                                        Color.black.opacity(0.7),
                                        Color.black.opacity(0.9)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                
                                // Content
                                VStack(alignment: .leading, spacing: 12) {
                                    // Badge
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .font(.caption2)
                                        Text("MANŞET")
                                            .font(.system(size: 11, weight: .bold))
                                            .tracking(1)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.red, Color.orange],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: Color.red.opacity(0.5), radius: 8, x: 0, y: 4)
                                    )
                                    
                                    // Title
                                    Text(headline.name)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(3)
                                        .multilineTextAlignment(.leading)
                                        .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 2)
                                    
                                    // Meta Info
                                    HStack(spacing: 16) {
                                        if let author = headline.author {
                                            HStack(spacing: 4) {
                                                Image(systemName: "person.fill")
                                                    .font(.caption2)
                                                Text(author.name)
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.white.opacity(0.9))
                                        }
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "calendar")
                                                .font(.caption2)
                                            Text(headline.createdAt.prefix(10))
                                                .font(.caption)
                                        }
                                        .foregroundColor(.white.opacity(0.9))
                                        
                                        Spacer()
                                    }
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .cornerRadius(0)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                .onAppear {
                    startTimer()
                }
                .onDisappear {
                    stopTimer()
                }
                .onChange(of: currentIndex) { _ in
                    resetTimer()
                }
                
                // Custom Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<min(headlines.count, 10), id: \.self) { index in
                        Circle()
                            .fill(currentIndex == index ? Color.white : Color.white.opacity(0.4))
                            .frame(width: currentIndex == index ? 8 : 6, height: currentIndex == index ? 8 : 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
                .padding(.bottom, 20)
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentIndex = (currentIndex + 1) % min(headlines.count, 10)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        startTimer()
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
                Text("Videolar")
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
                Text("Foto Galeri")
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

// MARK: - Authors Section
struct AuthorsSection: View {
    let authors: [AuthorDetail]
    @Binding var showSideMenu: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.purple)
                Text("Yazarlar")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink(destination: AuthorsListView(showSideMenu: $showSideMenu)) {
                    Text("Tümü")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(authors.prefix(6)) { author in
                        NavigationLink(destination: AuthorDetailView(authorId: author.id, showSideMenu: $showSideMenu)) {
                            AuthorHomeCard(author: author)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct AuthorHomeCard: View {
    let author: AuthorDetail
    
    var body: some View {
        VStack(spacing: 8) {
            // Author Image
            AsyncImage(url: URL(string: author.imageURL)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        Text(author.name.prefix(1))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                    }
                @unknown default:
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 80)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.purple.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Author Name
            Text(author.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 100)
        }
    }
}

// MARK: - Popular Posts Section
struct PopularPostsSection: View {
    let posts: [Post]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Çok Okunanlar")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 16) {
                ForEach(posts) { post in
                    NavigationLink(destination: PostDetailView(postId: post.id)) {
                        PopularPostCard(post: post)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

struct PopularPostCard: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 12) {
            // Post Image
            AsyncImage(url: URL(string: post.image.cropped.medium)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
            .frame(width: 120, height: 100)
            .cornerRadius(10)
            .clipped()
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(post.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Meta Info
                HStack(spacing: 12) {
                    if let author = post.author {
                        Label(author.name, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !post.createdAt.isEmpty {
                        Label(String(post.createdAt.prefix(10)), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - ViewModel
@MainActor
class NewHomeViewModel: ObservableObject {
    @Published var headlines: [Post] = []
    @Published var featuredPosts: [Post] = []
    @Published var latestVideos: [Video] = []
    @Published var latestGalleries: [Gallery] = []
    @Published var latestPosts: [Post] = []
    @Published var popularPosts: [Post] = []
    @Published var authors: [AuthorDetail] = []
    @Published var isLoading = false
    @Published var appLogo: String?
    
    private let apiService = APIService.shared
    
    func loadAllContent() async {
        isLoading = true
        
        async let headlinesTask = try? apiService.fetchHeadlines()
        async let featured = try? apiService.fetchFeaturedPosts()
        async let videos = try? apiService.fetchLatestVideos(limit: 5)
        async let galleries = try? apiService.fetchLatestGalleries(limit: 5)
        async let posts = try? apiService.fetchLatestPosts(limit: 10)
        async let popularTask = try? apiService.fetchPopularPosts()
        async let authorsTask = try? apiService.fetchAuthors(perPage: 6)
        async let settings = try? apiService.fetchSettings()
        
        let (headlinesResult, featuredResult, videosResult, galleriesResult, postsResult, popularResult, authorsResult, settingsResult) = await (headlinesTask, featured, videos, galleries, posts, popularTask, authorsTask, settings)
        
        if let headlinesResult = headlinesResult {
            headlines = headlinesResult.data
        }
        
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
        
        if let popularResult = popularResult {
            popularPosts = popularResult.data
        }
        
        if let authorsResult = authorsResult {
            authors = authorsResult.data
        }
        
        if let settingsResult = settingsResult {
            appLogo = settingsResult.data.logoMobil
        }
        
        isLoading = false
    }
}

// MARK: - App Footer
struct AppFooter: View {
    var body: some View {
        VStack(spacing: 0) {
            // Top Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
            
            VStack(spacing: 16) {
                // Copyright Text
                VStack(spacing: 8) {
                    Text("© 2025 Yozgat Hakimiyet")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Tüm hakları saklıdır. İçerikler kaynak gösterilme kopyalanamaz.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Developer Info
                HStack(spacing: 4) {
                    Text("Haber Yazılımı:")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("TE Bilişim")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            Color(.systemBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
        )
    }
}
