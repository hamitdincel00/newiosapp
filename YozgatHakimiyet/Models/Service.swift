import Foundation

// MARK: - Weather Service
struct WeatherResponse: Codable {
    let data: [WeatherData]
    let error: Bool
    let message: String?
}

struct WeatherData: Codable, Identifiable {
    let dt: String
    let degree: Int
    let desc: String
    let pressure: String
    let humidity: Int
    let image: String
    let icon: String
    let wind: String
    let country: String
    let city: String
    let location: String
    let low: Int
    let high: Int
    
    var id: String { dt }
}

// MARK: - Prayer Times Service
struct PrayerTimesResponse: Codable {
    let data: PrayerTimesData
    let error: Bool
    let message: String?
}

struct PrayerTimesData: Codable {
    let tarih: String
    let tarihUzun: String
    let hicriTarih: String
    let imsak: String
    let gunes: String
    let ogle: String
    let ikindi: String
    let aksam: String
    let yatsi: String
    
    enum CodingKeys: String, CodingKey {
        case tarih
        case tarihUzun = "tarih_uzun"
        case hicriTarih = "hicri_tarih"
        case imsak, gunes, ogle, ikindi, aksam, yatsi
    }
}

// MARK: - Currency Service
struct CurrencyResponse: Codable {
    let data: [CurrencyData]
    let error: Bool
    let message: String?
}

struct CurrencyData: Codable, Identifiable {
    let name: String
    let code: String
    let buying: Double
    let buyingstr: String
    let selling: Double
    let sellingstr: String
    let rate: Double
    let time: String
    let date: String
    let datetime: String
    let calculated: Double
    
    var id: String { code }
    
    var changeDirection: ChangeDirection {
        if rate > 0 {
            return .up
        } else if rate < 0 {
            return .down
        } else {
            return .stable
        }
    }
    
    enum ChangeDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "minus"
            }
        }
        
        var color: String {
            switch self {
            case .up: return "green"
            case .down: return "red"
            case .stable: return "gray"
            }
        }
    }
}

// MARK: - Sports Service (Standings)
struct StandingsResponse: Codable {
    let data: StandingsData
    let error: Bool
    let message: String?
}

// MARK: - Leagues List Response
struct LeaguesListResponse: Codable {
    let data: [String: StandingsData]
    let error: Bool
    let message: String?
    let errors: String?
}

struct LeagueItem: Codable, Identifiable {
    let league: LeagueInfo
    let slug: String
    
    var id: String { slug }
    
    init(league: LeagueInfo, slug: String) {
        self.league = league
        self.slug = slug
    }
    
    // Slug'ı league name'den oluştur (küçük harf, tire ile)
    static func slugFromName(_ name: String) -> String {
        return name.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "ç", with: "c")
    }
}

struct StandingsData: Codable {
    let league: LeagueInfo
    let standings: [TeamStanding]
}

struct LeagueInfo: Codable {
    let name: String
    let country: String
    let logo: String?
    let flag: String?
}

struct TeamStanding: Codable, Identifiable {
    let rank: Int
    let team: String
    let logo: String?
    let form: String?
    let played: Int
    let won: Int
    let drawn: Int
    let lost: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let goalDifference: Int
    let points: Int
    let description: String?
    
    var id: String {
        "\(rank)-\(team)"
    }
    
    enum CodingKeys: String, CodingKey {
        case rank, team, logo, form, played
        case won = "win"
        case drawn = "draw"
        case lost = "lose"
        case goalsFor = "goalsFor"
        case goalsAgainst = "goalsagainst"
        case goalDifference = "goalsDiff"
        case points, description
    }
}

// MARK: - Fixture Service
struct FixtureResponse: Codable {
    let data: [MatchFixture]
    let error: Bool
    let message: String?
}

struct MatchFixture: Codable, Identifiable {
    let id: Int
    let date: String
    let time: String
    let homeTeam: String
    let awayTeam: String
    let homeScore: Int?
    let awayScore: Int?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id, date, time, status
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case homeScore = "home_score"
        case awayScore = "away_score"
    }
}

// MARK: - Pharmacy Service
struct PharmacyResponse: Codable {
    let data: [PharmacyData]
    let error: Bool
    let message: String?
}

struct PharmacyData: Codable, Identifiable {
    let name: String
    let dist: String?
    let address: String
    let phone: String
    let loc: String?
    
    var id: String { name + (dist ?? "") }
    
    var district: String? { dist }
    
    var coordinates: (latitude: Double, longitude: Double)? {
        guard let loc = loc else { return nil }
        let parts = loc.split(separator: ",")
        guard parts.count == 2,
              let lat = Double(parts[0]),
              let lon = Double(parts[1]) else {
            return nil
        }
        return (lat, lon)
    }
}

// MARK: - Settings Service
struct SettingsResponse: Codable {
    let data: SettingsData
    let error: Bool
    let message: String?
}

struct SettingsData: Codable {
    let logoMobil: String?
    
    enum CodingKeys: String, CodingKey {
        case logoMobil = "logo_mobil"
    }
}
