import SwiftUI
import Combine
import WebKit
import SafariServices

// MARK: - Video List View
struct VideoListView: View {
    @Binding var showSideMenu: Bool
    @StateObject private var viewModel = VideoListViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.videos) { video in
                        NavigationLink(destination: VideoDetailView(videoId: video.id)) {
                            VideoCard(video: video)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
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
                await viewModel.loadVideos()
            }
            .task {
                await viewModel.loadVideos()
            }
        }
    }
}

// MARK: - Video List ViewModel
@MainActor
class VideoListViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    
    func loadVideos() async {
        isLoading = true
        do {
            let response = try await apiService.fetchLatestVideos()
            videos = response.data
        } catch {
            print("Error loading videos: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Video Detail View
struct VideoDetailView: View {
    let videoId: Int
    @StateObject private var viewModel = VideoDetailViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let video = viewModel.video {
                        // YouTube Player - Video ID'yi çıkar
                        if let videoId = extractVideoId(from: video) {
                            // YouTube'un kendi player'ı ile direkt aç
                            YouTubeEmbedView(videoId: videoId)
                                .frame(width: geometry.size.width)
                                .frame(height: geometry.size.width * 9/16)
                        } else {
                            // Video oynatıcı yoksa placeholder göster
                            VStack(spacing: 16) {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                
                                Text("Video Oynatıcı Bulunamadı")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if !video.url.isEmpty {
                                    Link(destination: URL(string: video.url) ?? URL(string: "https://www.youtube.com")!) {
                                        HStack {
                                            Image(systemName: "arrow.up.right.square")
                                            Text("Videoyu YouTube'da İzleyin")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .frame(width: geometry.size.width)
                            .frame(height: geometry.size.width * 9/16)
                            .background(Color(.systemGray6))
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            // Title
                            Text(video.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Meta Info
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    // Author
                                    if let author = video.author {
                                        Label(author.name, systemImage: "person.fill")
                                    }
                                    
                                    Spacer()
                                    
                                    // Views
                                    Label("\(video.hit) görüntülenme", systemImage: "eye")
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                
                                // Date and Source
                                HStack {
                                    Label(video.createdAt.prefix(10), systemImage: "calendar")
                                    
                                    if let source = video.source {
                                        Spacer()
                                        Text(source)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(8)
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            
                            // Categories
                            if !video.categories.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(video.categories.values), id: \.self) { category in
                                            Text(category)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .cornerRadius(16)
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Description
                            if let description = video.description, !description.isEmpty {
                                Text(description)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Divider()
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                            // HTML Content if available
                            if let content = video.content, !content.isEmpty {
                                HTMLContentView(htmlContent: content, width: geometry.size.width)
                                    .frame(width: geometry.size.width)
                            }
                            
                            // Comments Section
                            CommentsView(referenceId: video.id, referenceType: "video")
                                .padding(.top, 20)
                        
                    } else if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.errorMessage {
                        Text("Hata: \(error)")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LogoView()
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.video != nil {
                    Button(action: {
                        if let video = viewModel.video {
                            ShareHelper.sharePost(
                                title: video.name,
                                url: video.url,
                                imageUrl: video.image.cropped.large
                            ) { items in
                                // Items'ın boş olmadığından emin ol
                                if !items.isEmpty {
                                    shareItems = items
                                    showShareSheet = true
                                }
                            }
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems, isPresented: $showShareSheet)
        }
        .task {
            await viewModel.loadVideo(id: videoId)
        }
    }
    
    // Video'dan YouTube video ID çıkar
    private func extractVideoId(from video: VideoDetail) -> String? {
        // Önce embed code'dan çıkar
        if let embed = video.embed, !embed.isEmpty {
            print("📹 VideoDetailView - Embed code: \(embed.prefix(200))")
            
            // iframe'den video ID çıkar
            if let videoId = extractYouTubeVideoId(from: embed) {
                print("✅ VideoDetailView - Found video ID from embed: \(videoId)")
                return videoId
            }
        }
        
        // Embed yoksa URL'den çıkar
        if !video.url.isEmpty {
            print("📹 VideoDetailView - Video URL: \(video.url)")
            if let videoId = extractYouTubeVideoId(from: video.url) {
                print("✅ VideoDetailView - Found video ID from URL: \(videoId)")
                return videoId
            }
        }
        
        print("❌ VideoDetailView - Could not extract video ID")
        return nil
    }
    
    // YouTube video ID çıkar (embed veya URL'den)
    private func extractYouTubeVideoId(from text: String) -> String? {
        // youtube.com/embed/VIDEO_ID
        if let regex = try? NSRegularExpression(pattern: #"youtube\.com/embed/([a-zA-Z0-9_-]+)"#, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            let videoId = String(text[range])
            return videoId.components(separatedBy: "?").first
        }
        
        // youtube.com/watch?v=VIDEO_ID
        if let regex = try? NSRegularExpression(pattern: #"youtube\.com/watch\?v=([a-zA-Z0-9_-]+)"#, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            let videoId = String(text[range])
            return videoId.components(separatedBy: "&").first
        }
        
        // youtu.be/VIDEO_ID
        if let regex = try? NSRegularExpression(pattern: #"youtu\.be/([a-zA-Z0-9_-]+)"#, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            let videoId = String(text[range])
            return videoId.components(separatedBy: "?").first
        }
        
        return nil
    }
}

// MARK: - YouTube Embed View (Direkt YouTube Player)
struct YouTubeEmbedView: UIViewRepresentable {
    let videoId: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences
        
        // User agent ayarla (mobil Safari)
        config.applicationNameForUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // YouTube mobil web player URL'si - iOS'ta daha iyi çalışır
        let watchURL = "https://m.youtube.com/watch?v=\(videoId)"
        
        print("📹 YouTubeEmbedView - Loading video: \(videoId)")
        print("📹 YouTubeEmbedView - Watch URL: \(watchURL)")
        
        // YouTube mobil sayfasını yükle
        if let url = URL(string: watchURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("📹 YouTube Embed - Started loading")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ YouTube Embed - Finished loading")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ YouTube Embed - Error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Safari View (Uygulama içinde YouTube açmak için)
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = .red
        safariVC.preferredBarTintColor = .white
        safariVC.dismissButtonStyle = .close
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // Güncelleme gerekmiyor
    }
}

// MARK: - Video Detail ViewModel
@MainActor
class VideoDetailViewModel: ObservableObject {
    @Published var video: VideoDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadVideo(id: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchVideoDetail(id: id)
            video = response.data
        } catch {
            errorMessage = "Video yüklenirken bir hata oluştu: \(error.localizedDescription)"
            print("Error loading video: \(error)")
        }
        
        isLoading = false
    }
}

