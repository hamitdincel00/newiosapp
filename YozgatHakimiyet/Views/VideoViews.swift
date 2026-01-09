import SwiftUI
import Combine
import WebKit

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
            .navigationTitle("Videolar")
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
                        // YouTube Player
                        if let embed = video.embed {
                            YouTubePlayerView(embedCode: embed)
                                .frame(width: geometry.size.width)
                                .frame(height: geometry.size.width * 9/16) // 16:9 aspect ratio
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
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.video != nil {
                    Button(action: {
                        if let video = viewModel.video {
                            ShareHelper.sharePost(
                                title: video.name,
                                url: video.url,
                                imageUrl: video.image.cropped.large
                            ) { items in
                                shareItems = items
                                showShareSheet = true
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
            ShareSheet(items: shareItems)
        }
        .task {
            await viewModel.loadVideo(id: videoId)
        }
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

// MARK: - YouTube Player View
struct YouTubePlayerView: UIViewRepresentable {
    let embedCode: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Embed code'u responsive yap
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                }
                body {
                    background: #000;
                    overflow: hidden;
                }
                .video-container {
                    position: relative;
                    width: 100%;
                    padding-bottom: 56.25%; /* 16:9 aspect ratio */
                    height: 0;
                    overflow: hidden;
                }
                .video-container iframe {
                    position: absolute;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    border: 0;
                }
            </style>
        </head>
        <body>
            <div class="video-container">
                \(embedCode)
            </div>
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
    }
}
