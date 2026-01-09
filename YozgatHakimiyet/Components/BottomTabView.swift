import SwiftUI
import Combine

struct BottomTabView: View {
    @Binding var showSideMenu: Bool
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NewHomeView(showSideMenu: $showSideMenu)
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house.fill")
                }
                .tag(0)
            
            BreakingNewsView(showSideMenu: $showSideMenu)
                .tabItem {
                    Label("Son Dakika", systemImage: "exclamationmark.triangle.fill")
                }
                .tag(1)
            
            HeadlinesView(showSideMenu: $showSideMenu)
                .tabItem {
                    Label("Manşetler", systemImage: "newspaper.fill")
                }
                .tag(2)
            
            VideoListView(showSideMenu: $showSideMenu)
                .tabItem {
                    Label("Videolar", systemImage: "play.rectangle.fill")
                }
                .tag(3)
            
            GalleryListView(showSideMenu: $showSideMenu)
                .tabItem {
                    Label("Galeri", systemImage: "photo.on.rectangle")
                }
                .tag(4)
            
            SearchView(showSideMenu: $showSideMenu)
                .tabItem {
                    Label("Ara", systemImage: "magnifyingglass")
                }
                .tag(5)
        }
        .accentColor(.blue)
    }
}

struct BreakingNewsView: View {
    @Binding var showSideMenu: Bool
    @StateObject private var viewModel = BreakingNewsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.breakingNews) { news in
                        NavigationLink(destination: PostDetailView(postId: news.id)) {
                            BreakingNewsCard(post: news)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Son Dakika")
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
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadBreakingNews()
            }
        }
    }
}

@MainActor
class BreakingNewsViewModel: ObservableObject {
    @Published var breakingNews: [Post] = []
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    
    func loadBreakingNews() async {
        isLoading = true
        do {
            let response = try await apiService.fetchBreakingNews()
            breakingNews = response.data
        } catch {
            print("Error loading breaking news: \(error)")
        }
        isLoading = false
    }
    
    func refresh() async {
        await loadBreakingNews()
    }
}

struct HeadlinesView: View {
    @Binding var showSideMenu: Bool
    @StateObject private var viewModel = HeadlinesViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.headlines) { headline in
                        NavigationLink(destination: PostDetailView(postId: headline.id)) {
                            PostCard(post: headline)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Manşetler")
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
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadHeadlines()
            }
        }
    }
}

@MainActor
class HeadlinesViewModel: ObservableObject {
    @Published var headlines: [Post] = []
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    
    func loadHeadlines() async {
        isLoading = true
        do {
            let response = try await apiService.fetchHeadlines()
            headlines = response.data
        } catch {
            print("Error loading headlines: \(error)")
        }
        isLoading = false
    }
    
    func refresh() async {
        await loadHeadlines()
    }
}

struct SearchView: View {
    @Binding var showSideMenu: Bool
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Haber, galeri, video ara...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onChange(of: searchText) { newValue in
                            // Gerçek zamanlı arama (debounce ile)
                            viewModel.debounceSearch(query: newValue)
                        }
                        .onSubmit {
                            Task {
                                await viewModel.search(query: searchText)
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Results
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Text("Aranıyor...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                } else if !viewModel.searchResults.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.searchResults) { post in
                                NavigationLink(destination: PostDetailView(postId: post.id)) {
                                    PostCard(post: post)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                } else if searchText.isEmpty {
                    // Empty state - arama yapmadığında
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Haber Ara")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Arama yapmak için yukarıdaki alana kelime yazın")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    // No results
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Sonuç Bulunamadı")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("'\(searchText)' için sonuç bulunamadı")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Ara")
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
        }
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchResults: [Post] = []
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    private var searchTask: Task<Void, Never>?
    
    func search(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        // Önceki arama varsa iptal et
        searchTask?.cancel()
        
        isLoading = true
        
        do {
            let response = try await apiService.searchPosts(query: query)
            
            // Task iptal edilmediyse sonuçları göster
            if !Task.isCancelled {
                searchResults = response.data
            }
        } catch {
            if !Task.isCancelled {
                print("Error searching: \(error)")
                searchResults = []
            }
        }
        
        isLoading = false
    }
    
    // Debounce: Kullanıcı yazmayı bırakınca 0.5 saniye sonra ara
    func debounceSearch(query: String) {
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 saniye
            
            if !Task.isCancelled {
                await search(query: query)
            }
        }
    }
}

