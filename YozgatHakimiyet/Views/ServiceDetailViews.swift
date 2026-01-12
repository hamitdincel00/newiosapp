import SwiftUI
import Combine

// MARK: - Location Settings Helper
class LocationSettings: ObservableObject {
    static let shared = LocationSettings()
    
    @Published var selectedCity: String
    @Published var selectedDistrict: String?
    
    private let defaults = UserDefaults.standard
    
    private init() {
        self.selectedCity = defaults.string(forKey: "selectedCity") ?? "istanbul"
        self.selectedDistrict = defaults.string(forKey: "selectedDistrict")
    }
    
    func saveLocation(city: String, district: String?) {
        selectedCity = city.lowercased()
        selectedDistrict = district?.lowercased()
        
        defaults.set(selectedCity, forKey: "selectedCity")
        if let district = selectedDistrict {
            defaults.set(district, forKey: "selectedDistrict")
        } else {
            defaults.removeObject(forKey: "selectedDistrict")
        }
    }
}

// MARK: - Weather Detail View
struct WeatherDetailView: View {
    @Binding var showSideMenu: Bool
    @StateObject private var viewModel = WeatherDetailViewModel()
    @StateObject private var locationSettings = LocationSettings.shared
    @State private var showLocationPicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Location selector
                Button(action: { showLocationPicker = true }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text(locationSettings.selectedCity.capitalized)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Current weather
                if let current = viewModel.weather.first {
                    CurrentWeatherCard(weather: current)
                }
                
                // 7-day forecast
                ForEach(viewModel.weather) { weather in
                    WeatherForecastRow(weather: weather)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LogoView()
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(isPresented: $showLocationPicker, needsDistrict: false) {
                Task {
                    await viewModel.loadWeather()
                }
            }
        }
        .task {
            await viewModel.loadWeather()
        }
    }
}

struct CurrentWeatherCard: View {
    let weather: WeatherData
    
    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: weather.image)) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 120, height: 120)
            
            Text("\(weather.degree)°C")
                .font(.system(size: 60, weight: .bold))
            
            Text(weather.desc)
                .font(.title3)
            
            HStack(spacing: 40) {
                VStack {
                    Text("↑ \(weather.high)°")
                        .font(.title2)
                    Text("Max")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("↓ \(weather.low)°")
                        .font(.title2)
                    Text("Min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            HStack(spacing: 40) {
                VStack {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                        Text("\(weather.humidity)%")
                    }
                    Text("Nem")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    HStack {
                        Image(systemName: "wind")
                        Text(weather.wind)
                    }
                    Text("Rüzgar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text(weather.pressure)
                    Text("Basınç")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct WeatherForecastRow: View {
    let weather: WeatherData
    
    var body: some View {
        HStack {
            Text(weather.dt.prefix(10))
                .font(.subheadline)
            
            Spacer()
            
            AsyncImage(url: URL(string: weather.image)) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 40, height: 40)
            
            Text(weather.desc)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .trailing)
            
            Text("\(weather.high)° / \(weather.low)°")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 80, alignment: .trailing)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

@MainActor
class WeatherDetailViewModel: ObservableObject {
    @Published var weather: [WeatherData] = []
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    private let locationSettings = LocationSettings.shared
    
    func loadWeather() async {
        isLoading = true
        do {
            let normalizedCity = TurkishCities.normalize(locationSettings.selectedCity)
            let response = try await apiService.fetchWeather(city: normalizedCity)
            weather = response.data
        } catch {
            print("Error loading weather: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Prayer Times Detail View
struct PrayerTimesDetailView: View {
    @Binding var showSideMenu: Bool
    @StateObject private var viewModel = PrayerTimesDetailViewModel()
    @StateObject private var locationSettings = LocationSettings.shared
    @State private var showLocationPicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Location selector
                Button(action: { showLocationPicker = true }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text(locationSettings.selectedCity.capitalized)
                        if let district = locationSettings.selectedDistrict {
                            Text("/ \(district.capitalized)")
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                if let prayerTimes = viewModel.prayerTimes {
                    VStack(spacing: 16) {
                        Text(prayerTimes.tarihUzun)
                            .font(.headline)
                        
                        Text(prayerTimes.hicriTarih)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        PrayerTimeDetailRow(name: "İmsak", time: prayerTimes.imsak, icon: "moon.stars")
                        PrayerTimeDetailRow(name: "Güneş", time: prayerTimes.gunes, icon: "sunrise")
                        PrayerTimeDetailRow(name: "Öğle", time: prayerTimes.ogle, icon: "sun.max")
                        PrayerTimeDetailRow(name: "İkindi", time: prayerTimes.ikindi, icon: "sun.min")
                        PrayerTimeDetailRow(name: "Akşam", time: prayerTimes.aksam, icon: "sunset")
                        PrayerTimeDetailRow(name: "Yatsı", time: prayerTimes.yatsi, icon: "moon")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LogoView()
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(isPresented: $showLocationPicker, needsDistrict: true) {
                Task {
                    await viewModel.loadPrayerTimes()
                }
            }
        }
        .task {
            await viewModel.loadPrayerTimes()
        }
    }
}

struct PrayerTimeDetailRow: View {
    let name: String
    let time: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 30)
            Text(name)
                .font(.headline)
            Spacer()
            Text(time)
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

@MainActor
class PrayerTimesDetailViewModel: ObservableObject {
    @Published var prayerTimes: PrayerTimesData?
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    private let locationSettings = LocationSettings.shared
    
    func loadPrayerTimes() async {
        isLoading = true
        do {
            let normalizedCity = TurkishCities.normalize(locationSettings.selectedCity)
            let normalizedDistrict = locationSettings.selectedDistrict != nil ? TurkishCities.normalize(locationSettings.selectedDistrict!) : nil
            
            let response = try await apiService.fetchPrayerTimes(city: normalizedCity, district: normalizedDistrict)
            prayerTimes = response.data
        } catch {
            print("Error loading prayer times: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Currency Detail View
struct CurrencyDetailView: View {
    @Binding var showSideMenu: Bool
    @StateObject private var viewModel = CurrencyDetailViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.currencies) { currency in
                CurrencyDetailRow(currency: currency)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LogoView()
            }
        }
        .refreshable {
            await viewModel.loadCurrencies()
        }
        .task {
            await viewModel.loadCurrencies()
        }
    }
}

struct CurrencyDetailRow: View {
    let currency: CurrencyData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(currency.code)
                    .font(.headline)
                Text(currency.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.4f ₺", currency.calculated))
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: currency.changeDirection.icon)
                        .font(.caption2)
                    Text(String(format: "%.2f%%", abs(currency.rate)))
                        .font(.caption)
                }
                .foregroundColor(currency.changeDirection == .up ? .green : (currency.changeDirection == .down ? .red : .gray))
            }
        }
        .padding(.vertical, 4)
    }
}

@MainActor
class CurrencyDetailViewModel: ObservableObject {
    @Published var currencies: [CurrencyData] = []
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    
    func loadCurrencies() async {
        isLoading = true
        do {
            let response = try await apiService.fetchCurrency()
            currencies = response.data
        } catch {
            print("Error loading currencies: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Pharmacy Detail View
struct PharmacyDetailView: View {
    @Binding var showSideMenu: Bool
    @StateObject private var viewModel = PharmacyDetailViewModel()
    @StateObject private var locationSettings = LocationSettings.shared
    @State private var showLocationPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Location selector
            Button(action: { showLocationPicker = true }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text(locationSettings.selectedCity.capitalized)
                    if let district = locationSettings.selectedDistrict {
                        Text("/ \(district.capitalized)")
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .buttonStyle(PlainButtonStyle())
            
            List(viewModel.pharmacies) { pharmacy in
                PharmacyRow(pharmacy: pharmacy)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LogoView()
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(isPresented: $showLocationPicker, needsDistrict: true) {
                Task {
                    await viewModel.loadPharmacies()
                }
            }
        }
        .task {
            await viewModel.loadPharmacies()
        }
    }
}

struct PharmacyRow: View {
    let pharmacy: PharmacyData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(pharmacy.name)
                .font(.headline)
            
            Text(pharmacy.address)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let district = pharmacy.district {
                Text(district)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if !pharmacy.phone.isEmpty {
                Link(destination: URL(string: "tel://\(pharmacy.phone)")!) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text(pharmacy.phone)
                    }
                    .font(.subheadline)
                    .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

@MainActor
class PharmacyDetailViewModel: ObservableObject {
    @Published var pharmacies: [PharmacyData] = []
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    private let locationSettings = LocationSettings.shared
    
    func loadPharmacies() async {
        isLoading = true
        do {
            let normalizedCity = TurkishCities.normalize(locationSettings.selectedCity)
            let normalizedDistrict = locationSettings.selectedDistrict != nil ? TurkishCities.normalize(locationSettings.selectedDistrict!) : nil
            
            let response = try await apiService.fetchPharmacy(
                city: normalizedCity,
                district: normalizedDistrict
            )
            pharmacies = response.data
        } catch {
            print("Error loading pharmacies: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Standings Detail View
struct StandingsDetailView: View {
    @Binding var showSideMenu: Bool
    @Binding var selectedTab: Int
    @StateObject private var viewModel = StandingsDetailViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // League Selector - Modern Design
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("Lig Seçimi")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    // Custom Picker Button
                    Menu {
                        ForEach(viewModel.availableLeagues) { league in
                            Button(action: {
                                viewModel.selectedLeague = league.slug
                                Task {
                                    await viewModel.loadStandings(league: league.slug)
                                }
                            }) {
                                HStack {
                                    Text(league.league.name)
                                    if viewModel.selectedLeague == league.slug {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.currentLeagueName)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(viewModel.selectedLeague.isEmpty ? 0 : 0))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.blue.opacity(0.3),
                                                    Color.purple.opacity(0.2)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .shadow(color: Color.blue.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color(.systemGray6).opacity(0.5),
                            Color(.systemBackground)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Divider
                Divider()
                    .background(Color(.systemGray4))
                
                // Table Header
                HStack(spacing: 8) {
                    Text("Sıra")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 35)
                    
                    Text("Takım")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("O")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 25)
                    Text("G")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 25)
                    Text("B")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 25)
                    Text("M")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 25)
                    Text("A")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 30)
                    Text("Y")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 30)
                    Text("P")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 35)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                
                // Teams
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if viewModel.standings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Puan durumu verisi bulunamadı")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(viewModel.standings) { team in
                        StandingsDetailRow(team: team, totalTeams: viewModel.standings.count)
                    }
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
                        selectedTab = 0
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Geri")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .refreshable {
            await viewModel.loadStandings(league: viewModel.selectedLeague)
        }
        .task {
            await viewModel.loadAvailableLeagues()
            await viewModel.loadStandings(league: viewModel.selectedLeague)
        }
    }
}

struct StandingsDetailRow: View {
    let team: TeamStanding
    let totalTeams: Int
    
    var body: some View {
        HStack(spacing: 8) {
            // Rank
            Text("\(team.rank)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 35)
            
            // Team Logo
            if let logoURL = team.logo, let url = URL(string: logoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .frame(width: 24, height: 24)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    case .failure:
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .frame(width: 24, height: 24)
                    @unknown default:
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .frame(width: 24, height: 24)
                    }
                }
                .frame(width: 24, height: 24)
            } else {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
            }
            
            // Team Name
            Text(team.team)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            
            // Matches Played
            Text("\(team.played)")
                .font(.subheadline)
                .frame(width: 25)
            
            // Won
            Text("\(team.won)")
                .font(.subheadline)
                .foregroundColor(.green)
                .frame(width: 25)
            
            // Drawn
            Text("\(team.drawn)")
                .font(.subheadline)
                .foregroundColor(.orange)
                .frame(width: 25)
            
            // Lost
            Text("\(team.lost)")
                .font(.subheadline)
                .foregroundColor(.red)
                .frame(width: 25)
            
            // Goals For
            Text("\(team.goalsFor)")
                .font(.subheadline)
                .frame(width: 30)
            
            // Goal Difference
            Text("\(team.goalDifference >= 0 ? "+" : "")\(team.goalDifference)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(team.goalDifference >= 0 ? .green : .red)
                .frame(width: 30)
            
            // Points
            Text("\(team.points)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(width: 35)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            team.rank <= 4 ? Color.blue.opacity(0.1) :
            team.rank <= 6 ? Color.orange.opacity(0.1) :
            team.rank >= totalTeams - 3 ? Color.red.opacity(0.1) :
            Color(.systemBackground)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .bottom
        )
    }
}

@MainActor
class StandingsDetailViewModel: ObservableObject {
    @Published var standings: [TeamStanding] = []
    @Published var availableLeagues: [LeagueItem] = []
    @Published var selectedLeague: String = "super-lig"
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var currentLeagueName: String {
        availableLeagues.first(where: { $0.slug == selectedLeague })?.league.name ?? "Süper Lig"
    }
    
    private let apiService = APIService.shared
    
    func loadAvailableLeagues() async {
        do {
            let response = try await apiService.fetchAvailableLeagues()
            
            // Response'dan sadece lig bilgilerini çıkar
            // data dictionary'sinin key'leri lig slug'ları, value'ları StandingsData
            availableLeagues = response.data.map { (slug, standingsData) in
                LeagueItem(league: standingsData.league, slug: slug)
            }
            .sorted { $0.league.name < $1.league.name }
            
            // Süper Lig'i en başa taşı
            if let superLigIndex = availableLeagues.firstIndex(where: { $0.slug == "super-lig" }) {
                let superLig = availableLeagues.remove(at: superLigIndex)
                availableLeagues.insert(superLig, at: 0)
            }
            
            // Süper Lig'i default olarak seç
            if selectedLeague.isEmpty || !availableLeagues.contains(where: { $0.slug == selectedLeague }) {
                selectedLeague = "super-lig"
            }
        } catch {
            print("Error loading available leagues: \(error)")
            // Hata durumunda en azından Süper Lig'i ekle
            let superLig = LeagueItem(
                league: LeagueInfo(name: "Süper Lig", country: "Turkey", logo: nil, flag: nil),
                slug: "super-lig"
            )
            availableLeagues = [superLig]
            selectedLeague = "super-lig"
        }
    }
    
    func loadStandings(league: String = "super-lig") async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchStandings(league: league)
            standings = response.data.standings
            print("Standings loaded: \(standings.count) teams for league: \(league)")
            if standings.isEmpty {
                errorMessage = "Puan durumu verisi bulunamadı"
            }
        } catch {
            errorMessage = "Puan durumu yüklenirken bir hata oluştu"
            print("Error loading standings: \(error)")
            print("Error details: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("Decoding error: \(decodingError)")
            }
        }
        isLoading = false
    }
}

// MARK: - Location Picker View
struct LocationPickerView: View {
    @Binding var isPresented: Bool
    let needsDistrict: Bool
    @StateObject private var locationSettings = LocationSettings.shared
    @State private var selectedCity = "istanbul"
    @State private var selectedDistrict: String? = nil
    
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("İl Seçin")) {
                    Picker("İl", selection: $selectedCity) {
                        ForEach(TurkishCities.cityNames, id: \.self) { city in
                            Text(city.capitalized).tag(city)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                if needsDistrict, let cityDistricts = TurkishCities.cities[selectedCity], !cityDistricts.isEmpty {
                    Section(header: Text("İlçe Seçin (Opsiyonel)")) {
                        Picker("İlçe", selection: Binding(
                            get: { selectedDistrict ?? "" },
                            set: { selectedDistrict = $0.isEmpty ? nil : $0 }
                        )) {
                            Text("Tümü").tag("")
                            ForEach(cityDistricts, id: \.self) { district in
                                Text(district.capitalized).tag(district)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section {
                    Button("Kaydet") {
                        locationSettings.saveLocation(city: selectedCity, district: needsDistrict ? selectedDistrict : nil)
                        isPresented = false
                        onSave()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Konum Seçimi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("İptal") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            selectedCity = locationSettings.selectedCity
            selectedDistrict = locationSettings.selectedDistrict
        }
    }
}
