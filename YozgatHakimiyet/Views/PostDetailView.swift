import SwiftUI
import Combine
import WebKit

struct PostDetailView: View {
    let postId: Int
    @StateObject private var viewModel = PostDetailViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let post = viewModel.post {
                        // Hero Image
                        AsyncImage(url: URL(string: post.image.cropped.large)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(ProgressView())
                        }
                        .frame(width: geometry.size.width)
                        .frame(height: 300)
                        .clipped()
                        
                        VStack(alignment: .leading, spacing: 16) {
                            // Title
                            Text(post.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Meta Info
                            VStack(alignment: .leading, spacing: 8) {
                                if let author = post.author {
                                    Label(author.name, systemImage: "person.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                HStack {
                                    Label(post.createdAt.prefix(10), systemImage: "calendar")
                                    Spacer()
                                    Label("\(post.hit) görüntülenme", systemImage: "eye")
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            
                            // Categories
                            if !post.categories.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(post.categories.values), id: \.self) { category in
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
                            if let description = post.description, !description.isEmpty {
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
                        
                        // HTML Content
                        HTMLContentView(htmlContent: post.content, width: geometry.size.width)
                            .frame(width: geometry.size.width)
                        
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
                if viewModel.post != nil {
                    Button(action: {
                        if let post = viewModel.post {
                            ShareHelper.sharePost(
                                title: post.name,
                                url: post.url,
                                imageUrl: post.image.cropped.large
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
            await viewModel.loadPost(id: postId)
        }
    }
}

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var post: PostDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadPost(id: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchPostDetail(id: id)
            post = response.data
        } catch {
            errorMessage = "Haber yüklenirken bir hata oluştu: \(error.localizedDescription)"
            print("Error loading post: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - HTML Content View
struct HTMLContentView: UIViewRepresentable {
    let htmlContent: String
    let width: CGFloat
    @State private var contentHeight: CGFloat = 400
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "heightChanged")
        config.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * {
                    -webkit-user-select: text;
                    -webkit-touch-callout: default;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    padding: 16px;
                    margin: 0;
                    font-size: 16px;
                    line-height: 1.6;
                    color: #000;
                    background: transparent;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    display: block;
                    margin: 16px 0;
                    border-radius: 8px;
                }
                p {
                    margin: 12px 0;
                }
                h1, h2, h3, h4, h5, h6 {
                    margin: 20px 0 12px 0;
                    font-weight: 600;
                }
                a {
                    color: #007AFF;
                    text-decoration: none;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #FFF;
                    }
                }
            </style>
            <script>
                window.addEventListener('load', function() {
                    setTimeout(function() {
                        var height = document.body.scrollHeight;
                        window.webkit.messageHandlers.heightChanged.postMessage(height);
                    }, 100);
                });
            </script>
        </head>
        <body>
            \(htmlContent)
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlString, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: HTMLContentView
        
        init(parent: HTMLContentView) {
            self.parent = parent
            super.init()
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "heightChanged", let height = message.body as? Double {
                DispatchQueue.main.async {
                    self.parent.contentHeight = CGFloat(height)
                }
            }
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: WKWebView, context: Context) -> CGSize? {
        return CGSize(width: width, height: contentHeight)
    }
}

