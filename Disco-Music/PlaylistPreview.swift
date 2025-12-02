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
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [.appBackgroundLight, .appBackgroundDark], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text(country.flagEmoji)
                            .font(.system(size: 60))
                        
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
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
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
                            VStack(spacing: 0) {
                                Text("Featured Artists")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(musicService.artists) { artist in
                                        ArtistCard(
                                            artist: artist,
                                            imageUrl: artistImageURLs[artist.id]
                                        )
                                        .task {
                                            await loadImageForArtist(artist)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
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
                                .background(Color.blue.opacity(0.7))
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await musicService.searchArtists(country: country.name, genre: genre)
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

// MARK: - Artist Card

struct ArtistCard: View {
    let artist: Artist
    let imageUrl: String? // TODO: Add this parameter
    let buttonCyan = Color(red: 0.0, green: 0.67, blue: 0.73)

    
    var body: some View {
        HStack(spacing: 16) {
            // Artist avatar with image or placeholder
            ZStack {
                if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        case .failure(_), .empty:
                            placeholderCircle
                        @unknown default:
                            placeholderCircle
                        }
                    }
                } else {
                    placeholderCircle
                }
            }
            
            // Rest of the card remains the same
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.appTextLight)
                
                Text(artist.displayInfo ?? "Artist")
                    .font(.caption)
                    .foregroundColor(.appTextLight)
                    .opacity(0.7)
                    //.foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
            
        }
        .padding()
        .background(
            Color(buttonCyan))
        .cornerRadius(12)
    }
    
    //TODO: REPLACE holders with images from spotify
    private var placeholderCircle: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: "music.mic")
                    .foregroundColor(.appTextLight)
                    .font(.title2)
            )
    }
}
