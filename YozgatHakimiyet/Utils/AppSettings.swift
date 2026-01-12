import SwiftUI
import Combine

// MARK: - App Settings Manager (Merkezi Logo Yönetimi)
@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var appLogo: String?
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    
    private init() {
        Task {
            await loadSettings()
        }
    }
    
    func loadSettings() async {
        isLoading = true
        do {
            let response = try await apiService.fetchSettings()
            appLogo = response.data.logoMobil
        } catch {
            print("Error loading settings: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Logo View Component
struct LogoView: View {
    @StateObject private var appSettings = AppSettings.shared
    
    var body: some View {
        if let logoURL = appSettings.appLogo, let url = URL(string: logoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(.white)
                        .frame(width: 140, height: 36)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 160, maxHeight: 36)
                        .clipped()
                case .failure:
                    Text("Yozgat Hakimiyet")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                @unknown default:
                    Text("Yozgat Hakimiyet")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: 160, maxHeight: 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        } else {
            Text("Yozgat Hakimiyet")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                )
        }
    }
}
