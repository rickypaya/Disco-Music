import SwiftUI
import Combine

// MARK: - MusicBrainz API Service

class MusicBrainzService: ObservableObject {
    @Published var artists: [Artist] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoadingImages = false
    
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
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "inc", value: "url-rels") // Include URL relationships to get Spotify links
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
            
            // Convert artists and fetch Spotify IDs
            var artistsWithSpotify: [Artist] = []
            
            for mbArtist in response.artists {
                var artist = mbArtist.toArtist()
                
                // Extract Spotify ID from relations
                if let spotifyID = extractSpotifyID(from: mbArtist) {
                    artist = Artist(
                        id: artist.id,
                        spotifyID: spotifyID,
                        name: artist.name,
                        displayInfo: artist.displayInfo,
                        type: artist.type,
                        country: artist.country,
                    )
                }
                
                artistsWithSpotify.append(artist)
            }
            
            await MainActor.run {
                self.artists = artistsWithSpotify
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load artists: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func extractSpotifyID(from artist: MusicBrainzArtist) -> String? {
        guard let relations = artist.relations else { return nil }
        
        for relation in relations {
            if relation.type == "streaming" || relation.type == "free streaming",
               let urlString = relation.url?.resource,
               urlString.contains("spotify.com/artist/") {
                // Extract Spotify ID from URL like: https://open.spotify.com/artist/1234567890
                if let url = URL(string: urlString),
                   let artistId = url.pathComponents.last {
                    return artistId
                }
            }
        }
        
        return nil
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

