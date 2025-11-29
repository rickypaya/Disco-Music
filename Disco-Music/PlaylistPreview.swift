import SwiftUI

// MARK: - Playlist Preview View

struct PlaylistPreviewView: View {
    let country: Country
    let genre: String
    //let detailViewColor = Color(red: 0.047, green: 0.490, blue: 0.627)
    private let backgroundBlue = Color(red: 0.047, green: 0.490, blue: 0.627)
    private let backgroundBlueDark = Color(red: 0.04, green: 0.25, blue: 0.31)

    
    @Environment(\.dismiss) var dismiss
    @StateObject private var musicService = MusicBrainzService()
    @StateObject private var authManager = SpotifyAuthManager.shared
    @State private var showingLoginController = false
    @State private var showingAuthAlert = false
    @State private var isGenerating = false
    @State private var generationError: String?
    
    
    
    var body: some View {
        NavigationView {
            ZStack{
                LinearGradient(colors: [backgroundBlue, backgroundBlueDark], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text(country.flagEmoji)
                            .font(.system(size: 60))
                        
                        Text(genre)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("from \(country.name)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .opacity(0.7)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    //.background(Color(.systemGray6))
                    //.background(LinearGradient(colors: [detailViewColor, .black], startPoint: .top, endPoint: .bottom))
                    
                    // Artists List
                    if musicService.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Discovering artists...")
                            .font(.caption)
                            .foregroundColor(.white)
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
                                .foregroundColor(.white)
                                .opacity(0.7)
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
                            //Image(systemName: "music.note.slash")
                            Image(systemName: "music.note")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            Text("No artists found")
                                .font(.body)
                                .foregroundColor(.white)
                                .opacity(0.7)
                            Text("Try searching for a different genre")
                                .font(.caption)
                                .foregroundColor(.white)
                                .opacity(0.7)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                Text("Featured Artists")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .foregroundColor(.white)
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(musicService.artists) { artist in
                                        ArtistCard(
                                            artist: artist,
                                            imageUrl: nil
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        // Generate / Sign In Button
                        VStack {
                            Button(action: {
                                if authManager.isAuthenticated {
                                    if !isGenerating {
                                        generatePlaylist()
                                    }
                                } else {
                                    showingAuthAlert = true
                                }
                            }) {
                                HStack {
                                    if isGenerating {
                                        ProgressView()
                                            .tint(.white)
                                        Text("Generating...")
                                            .fontWeight(.semibold)
                                    } else {
                                        Image(systemName: authManager.isAuthenticated ? "play.circle.fill" : "music.note")
                                            .font(.title3)
                                        Text(authManager.isAuthenticated ? "Generate Playlist" : "Sign In to Create Playlist")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    authManager.isAuthenticated ?
                                   backgroundBlue :
                                        Color(backgroundBlueDark)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isGenerating)
                            .padding()
                            .background(.clear)
                            
                            if let generationError {
                                Text(generationError)
                                    .font(.caption)
                                    .foregroundColor(.red)
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
            .background(
                SpotifyLoginControllerWrapper(
                    isPresented: $showingLoginController,
                    onSuccess: {
                        showingLoginController = false
                    }
                )
            )
            .alert("Sign In Required", isPresented: $showingAuthAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign In to Spotify") {
                    showingLoginController = true
                }
            } message: {
                Text("Connect your Spotify account to create and save playlists.")
            }
            .task {
                await musicService.searchArtists(country: country.name, genre: genre)
                print(musicService.artists)
                
                // Fetch artist images from Spotify
                if !musicService.artists.isEmpty {
                    let artistIds = musicService.artists.compactMap { $0.spotifyID }
                    print(artistIds)
                    if !artistIds.isEmpty {
                        //todo: fetch artists
                    }
                }
            }
        }
    }
    
    
    
    private func generatePlaylist() {
        let artistsList = musicService.artists   // allow name-based search
        
        guard !artistsList.isEmpty else {
            generationError = "No artists found."
            return
        }
        
        isGenerating = true
        generationError = nil
        
        Task {
            do {
                let playlist = try await SpotifyWebAPI.shared.generatePlaylist(
                    countryCode: "US",
                    countryName: country.name,
                    genre: genre,
                    artists: artistsList,     // <-- use full list
                    tracksPerArtist: 2
                )
                
                print("Created playlist:", playlist.name, playlist.id)
            } catch {
                print("Playlist generation failed:", error)
                generationError = "Failed to generate playlist."
            }
            
            isGenerating = false
        }
    }
}

// MARK: - Artist Card

struct ArtistCard: View {
    let artist: Artist
    let imageUrl: String? // Add this parameter
    
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
                
                Text(artist.displayInfo ?? "Artist")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
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
                    .foregroundColor(.white)
                    .font(.title2)
            )
    }
}

#Preview("Playlist Preview") {
    PlaylistPreviewView(
        country: Country(
            name: "Brazil",
            capital: "Brasília",
            latitude: -15.8267,
            longitude: -47.9218,
            population: 212559417,
            flagEmoji: "🇧🇷",
            region: "South America",
            currency: "BRL",
            genres: ["Samba", "Bossa Nova", "Forró"]
        ),
        genre: "Bossa Nova"
    )
}
