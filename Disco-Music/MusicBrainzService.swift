import SwiftUI
import Combine

// MARK: - MusicBrainz API Service

class MusicBrainzService: ObservableObject {
    @Published var artists: [Artist] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func searchArtists(country: String, genre: String, limit: Int = 10) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            artists = []
        }
        
        // MusicBrainz uses ISO country codes (e.g., "US", "GB", "JP")
        let countryCode = getCountryCode(for: country)
        
        // Build query - search for artists from the country with the genre as a tag
        var components = URLComponents(string: "https://musicbrainz.org/ws/2/artist")!
        components.queryItems = [
            URLQueryItem(name: "query", value: "country:\(countryCode) AND tag:\(genre)"),
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            await MainActor.run {
                errorMessage = "Invalid URL"
                isLoading = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("InteractiveGlobeApp/1.0 (contact@example.com)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(MusicBrainzResponse.self, from: data)
            
            await MainActor.run {
                self.artists = response.artists.map { $0.toArtist() }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load artists: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func getCountryCode(for country: String) -> String {
        let countryCodeMap: [String: String] = [
            "United States": "US",
            "United Kingdom": "GB",
            "France": "FR",
            "Germany": "DE",
            "Japan": "JP",
            "China": "CN",
            "India": "IN",
            "Brazil": "BR",
            "Australia": "AU",
            "Canada": "CA",
            "Russia": "RU",
            "South Africa": "ZA",
            "Egypt": "EG",
            "Mexico": "MX",
            "Italy": "IT",
            "Spain": "ES",
            "Argentina": "AR",
            "South Korea": "KR",
            "Turkey": "TR",
            "Saudi Arabia": "SA"
        ]
        
        return countryCodeMap[country] ?? "US"
    }
}
