import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @State private var selectedMenu: MenuItem = .home
    
    var body: some View {
        ZStack {
            if isShowing {
                // Background overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                        }
                    }
                
                // Side menu
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack {
                            Image(systemName: "newspaper.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            
                            Text("Yozgat Hakimiyet")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                        
                        // Menu Items
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(MenuItem.allCases, id: \.self) { item in
                                    MenuRow(item: item, isSelected: selectedMenu == item) {
                                        selectedMenu = item
                                        isShowing = false
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Divider()
                        
                        // Footer
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Versiyon 1.0.0")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        .padding()
                    }
                    .frame(width: 280)
                    .background(Color(.systemBackground))
                    .shadow(radius: 10)
                    
                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut, value: isShowing)
    }
}

enum MenuItem: String, CaseIterable {
    case home = "Ana Sayfa"
    case breaking = "Son Dakika"
    case headlines = "Manşetler"
    case galleries = "Foto Galeri"
    case videos = "Videolar"
    case search = "Ara"
    case categories = "Kategoriler"
    case authors = "Yazarlar"
    case settings = "Ayarlar"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .breaking: return "exclamationmark.triangle.fill"
        case .headlines: return "newspaper.fill"
        case .galleries: return "photo.on.rectangle"
        case .videos: return "play.rectangle.fill"
        case .search: return "magnifyingglass"
        case .categories: return "square.grid.2x2"
        case .authors: return "person.2.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MenuRow: View {
    let item: MenuItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: item.icon)
                    .font(.title3)
                    .frame(width: 24)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Text(item.rawValue)
                    .font(.body)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

