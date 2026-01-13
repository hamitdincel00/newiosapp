import SwiftUI
import Combine

// MARK: - Authors List View
struct AuthorsListView: View {
    @Binding var showSideMenu: Bool
    @StateObject private var viewModel = AuthorsListViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText, onSearchButtonClicked: {
                    Task {
                        if searchText.isEmpty {
                            await viewModel.loadAuthors()
                        } else {
                            await viewModel.searchAuthors(query: searchText)
                        }
                    }
                })
                .padding(.horizontal)
                .padding(.top, 8)
                
                if viewModel.isLoading && viewModel.authors.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.authors.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Yazar bulunamadı")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 20) {
                            ForEach(viewModel.authors) { author in
                                NavigationLink(destination: AuthorDetailView(authorId: author.id, showSideMenu: $showSideMenu)) {
                                    AuthorCard(author: author)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .onAppear {
                                    // Son elemana yaklaşıldığında bir sonraki sayfayı yükle
                                    if author.id == viewModel.authors.last?.id && viewModel.hasMorePages && !viewModel.isLoadingMore {
                                        Task {
                                            await viewModel.loadMoreAuthors()
                                        }
                                    }
                                }
                            }
                            
                            // Loading indicator (daha fazla yüklenirken)
                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .padding()
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
                await viewModel.loadAuthors()
            }
            .task {
                await viewModel.loadAuthors()
            }
        }
    }
}

// MARK: - Author Card
struct AuthorCard: View {
    let author: AuthorDetail
    
    var body: some View {
        VStack(spacing: 12) {
            // Author Image
            AsyncImage(url: URL(string: author.imageURL)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 100, height: 100)
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
                                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        Text(author.name.prefix(1))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.primary)
                    }
                @unknown default:
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // Author Name
            Text(author.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Author Description (if available)
            if let description = author.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("Yazar ara...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            Button(action: onSearchButtonClicked) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
    }
}

// MARK: - Authors List ViewModel
@MainActor
class AuthorsListViewModel: ObservableObject {
    @Published var authors: [AuthorDetail] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasMorePages = true
    
    private let apiService = APIService.shared
    private var currentPage = 1
    private var isSearchMode = false
    private var currentSearchQuery: String?
    
    func loadAuthors() async {
        // Reset pagination
        currentPage = 1
        hasMorePages = true
        isSearchMode = false
        currentSearchQuery = nil
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchAuthors(page: currentPage, perPage: 12)
            authors = response.data
            
            // Eğer boş data gelirse veya beklenenden az gelirse, daha fazla sayfa yok
            if response.data.isEmpty {
                hasMorePages = false
            }
        } catch {
            errorMessage = "Yazarlar yüklenirken bir hata oluştu: \(error.localizedDescription)"
            print("Error loading authors: \(error)")
            hasMorePages = false
        }
        
        isLoading = false
    }
    
    func loadMoreAuthors() async {
        // Daha fazla sayfa yoksa veya zaten yükleniyorsa çık
        guard hasMorePages && !isLoadingMore else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            let response: AuthorResponse
            if isSearchMode, let query = currentSearchQuery {
                response = try await apiService.fetchAuthors(page: currentPage, perPage: 12, search: query)
            } else {
                response = try await apiService.fetchAuthors(page: currentPage, perPage: 12)
            }
            
            // Yeni data varsa ekle
            if !response.data.isEmpty {
                authors.append(contentsOf: response.data)
            } else {
                // Boş data gelirse daha fazla sayfa yok
                hasMorePages = false
            }
            
            // Eğer gelen data sayısı perPage'den azsa, daha fazla sayfa yok
            if response.data.count < 12 {
                hasMorePages = false
            }
        } catch {
            print("Error loading more authors: \(error)")
            // Hata durumunda sayfayı geri al ve daha fazla sayfa yok olarak işaretle
            currentPage -= 1
            hasMorePages = false
        }
        
        isLoadingMore = false
    }
    
    func searchAuthors(query: String) async {
        // Reset pagination
        currentPage = 1
        hasMorePages = true
        isSearchMode = true
        currentSearchQuery = query
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchAuthors(page: currentPage, perPage: 12, search: query)
            authors = response.data
            
            // Eğer boş data gelirse, daha fazla sayfa yok
            if response.data.isEmpty {
                hasMorePages = false
            }
        } catch {
            errorMessage = "Arama yapılırken bir hata oluştu: \(error.localizedDescription)"
            print("Error searching authors: \(error)")
            hasMorePages = false
        }
        
        isLoading = false
    }
}
