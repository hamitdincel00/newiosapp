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
        .navigationTitle("Hava Durumu")
        .navigationBarTitleDisplayMode(.inline)
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
        .navigationTitle("Namaz Vakitleri")
        .navigationBarTitleDisplayMode(.inline)
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
        .navigationTitle("Döviz Kurları")
        .navigationBarTitleDisplayMode(.inline)
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
        .navigationTitle("Nöbetçi Eczane")
        .navigationBarTitleDisplayMode(.inline)
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
