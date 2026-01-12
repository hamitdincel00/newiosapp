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
                if viewModel.authors.isEmpty && !viewModel.isLoading {
                    SearchBar(text: $searchText, onSearchButtonClicked: {
                        Task {
                            await viewModel.searchAuthors(query: searchText)
                        }
                    })
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
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
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadAuthors() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchAuthors()
            authors = response.data
        } catch {
            errorMessage = "Yazarlar yüklenirken bir hata oluştu: \(error.localizedDescription)"
            print("Error loading authors: \(error)")
        }
        
        isLoading = false
    }
    
    func searchAuthors(query: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchAuthors(search: query)
            authors = response.data
        } catch {
            errorMessage = "Arama yapılırken bir hata oluştu: \(error.localizedDescription)"
            print("Error searching authors: \(error)")
        }
        
        isLoading = false
    }
}
