import SwiftUI

// MARK: - Playlist Preview View

struct PlaylistPreviewView: View {
    let country: Country
    let genre: String
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var musicService = MusicBrainzService()
    @StateObject private var spotifyAPI = SpotifyWebAPI.shared
    @StateObject private var storageManager = PlaylistStorageManager.shared
    
    @State private var generatedPlaylist: SpotifyPlaylist?
    @State private var isGenerating = false
    @State private var generationError: String?
    @State private var artistImageURLs: [Artist.ID: String] = [:]
    @State private var isLiked: Bool = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.appBackgroundLight, .appBackgroundDark], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 10) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Text(country.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.trailing, 8)
                        
                        Text(genre)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.25)
                                .clipShape(Capsule())
                            )
                        Spacer()
                        
                        Button(action: {
                            isLiked.toggle()
                            if isLiked {
                                storageManager.addLikedGenre(genre, for: country)
                            } else {
                                storageManager.removeLikedGenre(genre, for: country)
                            }
                        }) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                //.padding(.bottom, 20)
                .frame(maxWidth: .infinity)
                
                // Artists List
                if musicService.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Discovering artists...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Spacer()
                } else if let errorMessage = musicService.errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Try Again") {
                            Task {
                                await musicService.searchArtists(country: country.name, genre: genre)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                } else if musicService.artists.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No artists found")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text("Try searching for a different genre")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack {
                            ForEach(0..<musicService.artists.count / 6 + (musicService.artists.count % 6 == 0 ? 0 : 1), id: \.self) { groupIndex in
                                let startIndex = groupIndex * 6
                                let endIndex = min(startIndex + 6, musicService.artists.count)
                                let currentGroup = Array(musicService.artists[startIndex..<endIndex])
                                
                                ZStack {
                                    ForEach(currentGroup.indices, id: \.self) { indexInGroup in
                                        let artist = currentGroup[indexInGroup]
                                        GroupedArtistPhotoView(
                                            artist: artist,
                                            imageUrl: artistImageURLs[artist.id],
                                            positionIndex: indexInGroup
                                        )
                                        .task {
                                            await loadImageForArtist(artist)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                                
                            }
                        }
                        .padding(.horizontal, 0)
                        .padding(.top, 20)
                    }
                    
                    // Generate Button
                    VStack {
                        if isGenerating {
                            HStack {
                                ProgressView()
                                    .tint(.white)
                                Text("Generating Playlist...")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.buttonBackgroundLight, .buttonBackgroundDark], startPoint: .top, endPoint: .bottom))
                            .cornerRadius(12)
                            .padding()
                        } else {
                            Button(action: {
                                generatePlaylist()
                            }) {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title3)
                                    Text("Generate Playlist")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                            gradient: Gradient(colors: [.cyan, .blue]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding()
                            .background(.clear)
                        }
                        
                        if let error = generationError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await musicService.searchArtists(country: country.name, genre: genre)
                isLiked = storageManager.isGenreLiked(genre, for: country)
            }
            .sheet(item: $generatedPlaylist) { playlist in
                PlaylistDetailView(
                    country: country,
                    genre: genre,
                    playlist: playlist
                )
            }
        }
    }
    
    // MARK: - Generate Playlist
    
    private func generatePlaylist() {
        isGenerating = true
        generationError = nil
        
        Task {
            do {
                // Get country code for Spotify market
                let countryCode = getCountryCode(for: country.name)
                
                // Generate playlist using Spotify API
                let playlist = try await spotifyAPI.generatePlaylist(
                    countryCode: countryCode,
                    countryName: country.name,
                    genre: genre,
                    artists: musicService.artists,
                    tracksPerArtist: 2
                )
                
                await MainActor.run {
                    isGenerating = false
                    storageManager.savePlaylist(playlist, country: country, genre: genre)
                    generatedPlaylist = playlist
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    generationError = "Failed to generate playlist: \(error.localizedDescription)"
                }
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
    
    private func loadImageForArtist(_ artist: Artist) async {
        if artistImageURLs[artist.id] != nil { return }
        do {
            if let url = try await spotifyAPI.fetchArtistImageURL(for: artist) {
                await MainActor.run {
                    artistImageURLs[artist.id] = url.absoluteString
                }
            }
        } catch {
            print("Failed to load image for \(artist.name): \(error)")
        }
    }
}

// MARK: - Artist Photo View

struct ArtistPhotoView: View {
    let artist: Artist
    let imageUrl: String?
    
    var body: some View {
        VStack(spacing: 5) { // Changed to VStack with small spacing
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 75, height: 75)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.1)
                    )
                
                if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 65, height: 65) // Adjusted frame to fit new circle size
                                .clipShape(Circle())
                        case .failure(_), .empty:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
            }
            
            Text(artist.name)
                .font(.caption2)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 10)
        .padding(.top, 20)
    }
    
    private var placeholderImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 60, height: 60)
            .foregroundColor(.gray.opacity(0.5))
    }
}

// MARK: - Grouped Artist Photo View

struct GroupedArtistPhotoView: View {
    let artist: Artist
    let imageUrl: String?
    let positionIndex: Int
    
    var body: some View {
        // Determine offset based on positionIndex within the group of 6
        let offsets: [(x: CGFloat, y: CGFloat)] = [
            // Define offsets that are tighter and create overlap
            (x: -100, y: -60), // Top-left
            (x: 0, y: -90),    // Top-middle (higher)
            (x: 100, y: -60),  // Top-right
            (x: -120, y: 50),   // Mid-left
            (x: 120, y: 50),    // Mid-right
            (x: 0, y: 30)      // Bottom-middle
        ]
        
        let offset = offsets[positionIndex % offsets.count]
        
        return ArtistPhotoView(
            artist: artist,
            imageUrl: imageUrl
        )
        .offset(x: offset.x, y: offset.y)
    }
}

// MARK: - Previews

struct PlaylistPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample country and genre for the preview
        let sampleCountry = Country(
            name: "United States",
            capital: "Washington, D.C.",
            latitude: 38.9072,
            longitude: -77.0369,
            population: 331002651,
            flagEmoji: "🇺🇸",
            region: "North America",
            currency: "USD",
            genres: ["Rock", "Pop", "Hip Hop", "Jazz", "Country", "Electronic"]
        )
        let sampleGenre = "Rock"
        
        // Create dummy artists for preview
        let dummyArtists: [Artist] = [
            Artist(id: UUID().uuidString, spotifyID: nil, name: "Johnny Cash", displayInfo: "Country", type: "Person", country: "US"),
            Artist(id: UUID().uuidString, spotifyID: nil, name: "Bob Dylan", displayInfo: "Folk", type: "Person", country: "US"),
            Artist(id: UUID().uuidString, spotifyID: nil, name: "Elvis Presley", displayInfo: "Rock and Roll", type: "Person", country: "US"),
            Artist(id: UUID().uuidString, spotifyID: nil, name: "Grateful Dead", displayInfo: "Rock", type: "Group", country: "US"),
            Artist(id: UUID().uuidString, spotifyID: nil, name: "Willie Nelson", displayInfo: "Country", type: "Person", country: "US"),
            Artist(id: UUID().uuidString, spotifyID: nil, name: "Wilco", displayInfo: "Alt-Country", type: "Group", country: "US"),
            Artist(id: UUID().uuidString, spotifyID: nil, name: "Ella Fitzgerald", displayInfo: "Jazz", type: "Person", country: "US"),
            Artist(id: UUID().uuidString, spotifyID: nil, name: "Miles Davis", displayInfo: "Jazz", type: "Person", country: "US"),
            Artist(id: UUID().uuidString, spotifyID: nil, name: "Louis Armstrong", displayInfo: "Jazz", type: "Person", country: "US"),
            Artist(id: UUID().uuidString, spotifyID: nil, name: "Billie Holiday", displayInfo: "Jazz", type: "Person", country: "US"),
            Artist(id: UUID().uuidString, spotifyID: nil, name: "Frank Sinatra", displayInfo: "Vocal", type: "Person", country: "US"),
            Artist(id: UUID().uuidString, spotifyID: nil, name: "Phish", displayInfo: "Rock", type: "Group", country: "US")
        ]
        
        // Create a mock MusicBrainzService
        let mockMusicService = MusicBrainzService()
        mockMusicService.artists = dummyArtists
        
        // Create dummy artistImageURLs (empty strings will trigger placeholder in ArtistPhotoView)
        var dummyImageURLs: [Artist.ID: String] = [:]
        for artist in dummyArtists {
            dummyImageURLs[artist.id] = ""
        }
        
        return PlaylistPreviewView(
            country: sampleCountry,
            genre: sampleGenre
        )
        .environmentObject(MockMusicBrainzService()) // Inject the mock service
        .environmentObject(SpotifyWebAPI.shared) // Keep if other parts of the view need it, otherwise can mock
        .environmentObject(PlaylistStorageManager.shared) // Keep if other parts of the view need it
    }
}
