import SwiftUI
import Combine

struct BottomTabView: View {
    @Binding var showSideMenu: Bool
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack {
            // Ana içerik
            Group {
                switch selectedTab {
                case 0:
                    NewHomeView(showSideMenu: $showSideMenu)
                case 1:
                    BreakingNewsView(showSideMenu: $showSideMenu)
                case 2:
                    HeadlinesView(showSideMenu: $showSideMenu)
                case 3:
                    VideoListView(showSideMenu: $showSideMenu)
                case 4:
                    GalleryListView(showSideMenu: $showSideMenu)
                case 5:
                    SearchView(showSideMenu: $showSideMenu)
                case 6:
                    NavigationView {
                        StandingsDetailView(showSideMenu: $showSideMenu, selectedTab: $selectedTab)
                    }
                case 7:
                    AuthorsListView(showSideMenu: $showSideMenu)
                default:
                    NewHomeView(showSideMenu: $showSideMenu)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, (selectedTab == 6 || selectedTab == 7) ? 0 : 90)
            
            // Özel Bottom Tab Bar - Standings ve Authors sayfalarında gösterilmez
            if selectedTab != 6 && selectedTab != 7 {
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $selectedTab)
                        .padding(.bottom, 8)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var animation
    
    private let tabs: [(icon: String, title: String)] = [
        ("house.fill", "Ana Sayfa"),
        ("bolt.fill", "Son Dakika"),
        ("newspaper.fill", "Manşetler"),
        ("play.rectangle.fill", "Videolar"),
        ("photo.on.rectangle", "Galeri"),
        ("magnifyingglass", "Ara")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                TabBarButton(
                    icon: tab.icon,
                    title: tab.title,
                    isSelected: selectedTab == index,
                    animation: animation
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Profesyonel arka plan - tam genişlik, köşeler yuvarlak değil
                Rectangle()
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
                
                // Üst border - ince çizgi
                VStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 0.5)
                    Spacer()
                }
            }
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var animation: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Icon Container - Minimal ve profesyonel
                ZStack {
                    if isSelected {
                        // Seçili durum için minimal arka plan
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 44, height: 44)
                            .matchedGeometryEffect(id: "selectedTab", in: animation)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 22 : 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .blue : Color(.systemGray))
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .frame(height: 44)

                // Başlık - Her zaman göster ama seçili olan daha belirgin
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : Color(.systemGray))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
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

