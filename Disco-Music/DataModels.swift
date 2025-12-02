import SwiftUI
import Combine

// MARK: - Data Models

struct Country: Identifiable, Codable {
    let id: UUID
    let name: String
    let capital: String
    let latitude: Double
    let longitude: Double
    let population: Int
    let flagEmoji: String
    let region: String
    let currency: String?
    let genres: [String]
    
    init(id: UUID = UUID(), name: String, capital: String, latitude: Double, longitude: Double, population: Int, flagEmoji: String, region: String, currency: String? = nil, genres: [String]) {
        self.id = id
        self.name = name
        self.capital = capital
        self.latitude = latitude
        self.longitude = longitude
        self.population = population
        self.flagEmoji = flagEmoji
        self.region = region
        self.currency = currency
        self.genres = genres
    }
}

// MARK: - MusicBrainz API Response Models

struct MusicBrainzResponse: Codable {
    let artists: [MusicBrainzArtist]
}


struct MusicBrainzArtist: Codable {
    let id: String
    let name: String
    let type: String?
    let country: String?
    let disambiguation: String?
    let lifeSpan: LifeSpan?
    let relations: [Relation]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, country, disambiguation, relations
        case lifeSpan = "life-span"
    }
    
    func toArtist() -> Artist {
        var displayInfo = ""
        
        if let type = type {
            displayInfo = type.capitalized
        }
        
        if let country = country {
            if !displayInfo.isEmpty {
                displayInfo += " • "
            }
            displayInfo += country
        }
        
        if let disambiguation = disambiguation, !disambiguation.isEmpty {
            if !displayInfo.isEmpty {
                displayInfo += " • "
            }
            displayInfo += disambiguation
        }
        
        return Artist(
            id: id,
            spotifyID: nil, // Will be populated separately
            name: name,
            displayInfo: displayInfo.isEmpty ? "Artist" : displayInfo,
            type: type,
            country: country,
        )
    }
}

struct LifeSpan: Codable {
    let begin: String?
    let end: String?
}

struct Relation: Codable {
    let type: String
    let url: RelationURL?
}

struct RelationURL: Codable {
    let resource: String
}

// MARK: - Sample Data Provider

class CountriesDataProvider: NSObject, ObservableObject {
    @Published var countries: [Country] = []
    
    override init() {
        super.init()
        loadCountries()
    }
    
    func loadCountries() {
        countries = [
            Country(name: "United States", capital: "Washington, D.C.", latitude: 38.9072, longitude: -77.0369, population: 331002651, flagEmoji: "🇺🇸", region: "North America", currency: "USD", genres: ["Jazz", "Hip Hop", "Country"]),
            Country(name: "United Kingdom", capital: "London", latitude: 51.5074, longitude: -0.1278, population: 67886011, flagEmoji: "🇬🇧", region: "Europe", currency: "GBP", genres: ["Rock", "Electronic", "Punk"]),
            Country(name: "France", capital: "Paris", latitude: 48.8566, longitude: 2.3522, population: 65273511, flagEmoji: "🇫🇷", region: "Europe", currency: "EUR", genres: ["Chanson", "Electronic", "Pop"]),
            Country(name: "Germany", capital: "Berlin", latitude: 52.5200, longitude: 13.4050, population: 83783942, flagEmoji: "🇩🇪", region: "Europe", currency: "EUR", genres: ["Electronic", "Industrial", "Techno"]),
            Country(name: "Japan", capital: "Tokyo", latitude: 35.6762, longitude: 139.6503, population: 126476461, flagEmoji: "🇯🇵", region: "Asia", currency: "JPY", genres: ["J-Pop", "Enka", "City Pop"]),
            Country(name: "China", capital: "Beijing", latitude: 39.9042, longitude: 116.4074, population: 1439323776, flagEmoji: "🇨🇳", region: "Asia", currency: "CNY", genres: ["C-Pop", "Folk", "Opera"]),
            Country(name: "India", capital: "New Delhi", latitude: 28.6139, longitude: 77.2090, population: 1380004385, flagEmoji: "🇮🇳", region: "Asia", currency: "INR", genres: ["Bollywood", "Classical", "Bhangra"]),
            Country(name: "Brazil", capital: "Brasília", latitude: -15.8267, longitude: -47.9218, population: 212559417, flagEmoji: "🇧🇷", region: "South America", currency: "BRL", genres: ["Samba", "Bossa Nova", "Forró"]),
            Country(name: "Australia", capital: "Canberra", latitude: -35.2809, longitude: 149.1300, population: 25499884, flagEmoji: "🇦🇺", region: "Oceania", currency: "AUD", genres: ["Rock", "Indie", "Folk"]),
            Country(name: "Canada", capital: "Ottawa", latitude: 45.4215, longitude: -75.6972, population: 37742154, flagEmoji: "🇨🇦", region: "North America", currency: "CAD", genres: ["Indie", "Folk", "Hip Hop"]),
            Country(name: "Russia", capital: "Moscow", latitude: 55.7558, longitude: 37.6173, population: 145934462, flagEmoji: "🇷🇺", region: "Europe/Asia", currency: "RUB", genres: ["Classical", "Folk", "Pop"]),
            Country(name: "South Africa", capital: "Pretoria", latitude: -25.7479, longitude: 28.2293, population: 59308690, flagEmoji: "🇿🇦", region: "Africa", currency: "ZAR", genres: ["Amapiano", "Kwaito", "Jazz"]),
            Country(name: "Egypt", capital: "Cairo", latitude: 30.0444, longitude: 31.2357, population: 102334404, flagEmoji: "🇪🇬", region: "Africa", currency: "EGP", genres: ["Shaabi", "Classical", "Pop"]),
            Country(name: "Mexico", capital: "Mexico City", latitude: 19.4326, longitude: -99.1332, population: 128932753, flagEmoji: "🇲🇽", region: "North America", currency: "MXN", genres: ["Mariachi", "Ranchera", "Regional Mexican"]),
            Country(name: "Italy", capital: "Rome", latitude: 41.9028, longitude: 12.4964, population: 60461826, flagEmoji: "🇮🇹", region: "Europe", currency: "EUR", genres: ["Opera", "Pop", "Folk"]),
            Country(name: "Spain", capital: "Madrid", latitude: 40.4168, longitude: -3.7038, population: 46754778, flagEmoji: "🇪🇸", region: "Europe", currency: "EUR", genres: ["Flamenco", "Latin Pop", "Reggaeton"]),
            Country(name: "Argentina", capital: "Buenos Aires", latitude: -34.6037, longitude: -58.3816, population: 45195774, flagEmoji: "🇦🇷", region: "South America", currency: "ARS", genres: ["Tango", "Folk", "Rock"]),
            Country(name: "South Korea", capital: "Seoul", latitude: 37.5665, longitude: 126.9780, population: 51269185, flagEmoji: "🇰🇷", region: "Asia", currency: "KRW", genres: ["K-Pop", "Trot", "Hip Hop"]),
            Country(name: "Turkey", capital: "Ankara", latitude: 39.9334, longitude: 32.8597, population: 84339067, flagEmoji: "🇹🇷", region: "Europe/Asia", currency: "TRY", genres: ["Arabesque", "Folk", "Pop"]),
            Country(name: "Saudi Arabia", capital: "Riyadh", latitude: 24.7136, longitude: 46.6753, population: 34813871, flagEmoji: "🇸🇦", region: "Asia", currency: "SAR", genres: ["Arabic Pop", "Traditional", "Khaleeji"])
        ]
    }
    
    func loadFromJSON(filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Country].self, from: data) else {
            return
        }
        countries = decoded
    }
}


//MARK: - Spotify Data Models

struct SpotifyArtistsResponse: Codable {
    let artists: [SpotifyArtist]
}

struct SpotifyArtist: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]
    
    enum CodingKeys: String, CodingKey {
        case id, name, images
    }
}


struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

struct SearchResponse: Codable {
    let tracks: TracksObject
}

struct TracksObject: Codable {
    let tracks: [Track]
}

struct Track: Codable {
    let id: String
    let name: String
    let uri: String
    let artists: [Artist]
    let album: Album
}

struct Artist: Codable, Identifiable {
    let id: String
    let spotifyID: String?
    let name: String
    let displayInfo: String?
    let type: String?
    let country: String?
    
    static func == (lhs: Artist, rhs: Artist) -> Bool {
        lhs.id == rhs.id
    }
    
    
}

struct Album: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]
}

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}

struct ArtistSearchResponse: Codable {
    let artists: ArtistsObject
}

struct ArtistsObject: Codable {
    let items: [ArtistDetail]
}

struct ArtistDetail: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]
}

//MARK: - Playlist Data Models

struct SpotifyPlaylist: Decodable, Identifiable {
    let id: String
    let name: String
    let uri: String?
    let description: String?
    let images: [SpotifyImage]?
    let tracks: SpotifyPlaylistTracks?
    
    enum CodingKeys: String, CodingKey {
        case id, name, uri, description, images, tracks
    }
}

struct SpotifyPlaylistTracks: Decodable {
    let items: [SpotifyPlaylistTrackItem]
}

struct SpotifyPlaylistTrackItem: Decodable {
    let track: SpotifyTrack?
}

struct SpotifyTrack: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let uri: String
    let artists: [SpotifyTrackArtist]
    let album: SpotifyTrackAlbum
    let durationMs: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, uri, artists, album
        case durationMs = "duration_ms"
    }
    
    static func == (lhs: SpotifyTrack, rhs: SpotifyTrack) -> Bool {
        lhs.id == rhs.id
    }
}

struct SpotifyTrackArtist: Decodable {
    let id: String
    let name: String
}

struct SpotifyTrackAlbum: Decodable {
    let id: String
    let name: String
    let images: [SpotifyImage]
}

struct UserProfile: Codable {
    let id: String
    let displayName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }
}

// MARK: - Errors

enum SpotifyError: Error {
    case notAuthenticated
    case noData
    case requestFailed
    case noAccessToken
}

enum SpotifyServiceError: Error {
    case noAccessToken
    case invalidURL
    case badResponse(status: Int, message: String)
    case noTracksFound
}
