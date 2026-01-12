import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var selectedTab: Int
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
                        // Header with Logo
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "newspaper.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Yozgat Hakimiyet")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Text("Haber Portalı")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            Rectangle()
                                .fill(.ultraThinMaterial)
                        )
                        
                        Divider()
                            .background(Color(.systemGray4))
                        
                        // Menu Items
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(MenuItem.allCases, id: \.self) { item in
                                    MenuRow(item: item, isSelected: selectedMenu == item) {
                                        selectedMenu = item
                                        isShowing = false
                                        
                                        // Tab yönlendirmeleri
                                        switch item {
                                        case .home:
                                            selectedTab = 0
                                        case .breaking:
                                            selectedTab = 1
                                        case .headlines:
                                            selectedTab = 2
                                        case .videos:
                                            selectedTab = 3
                                        case .galleries:
                                            selectedTab = 4
                                        case .search:
                                            selectedTab = 5
                                        case .standings:
                                            selectedTab = 6
                                        case .authors:
                                            // Authors için tab 7'yi kullanacağız
                                            selectedTab = 7
                                        case .categories, .settings:
                                            // Bu öğeler için henüz view yok
                                            break
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        Spacer()
                        
                        Divider()
                            .background(Color(.systemGray4))
                        
                        // Footer
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 12))
                            Text("Versiyon 1.0.0")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .frame(width: 300)
                    .background(
                        ZStack {
                            Color(.systemBackground)
                            
                            // Subtle gradient
                            LinearGradient(
                                colors: [
                                    Color(.systemBackground),
                                    Color(.systemGray6).opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 5, y: 0)
                    
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
    case standings = "Puan Durumu"
    case categories = "Kategoriler"
    case authors = "Yazarlar"
    case settings = "Ayarlar"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .breaking: return "bolt.fill"
        case .headlines: return "newspaper.fill"
        case .galleries: return "photo.on.rectangle"
        case .videos: return "play.rectangle.fill"
        case .search: return "magnifyingglass"
        case .standings: return "sportscourt.fill"
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
                // Icon Container
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 40, height: 40)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                            .frame(width: 40, height: 40)
                    }
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .blue : .primary)
                }
                
                Text(item.rawValue)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.blue.opacity(0.08))
                            .overlay(
                                Rectangle()
                                    .frame(width: 4)
                                    .foregroundColor(.blue),
                                alignment: .leading
                            )
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

