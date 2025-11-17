import SwiftUI

// MARK: - Playlist Preview View

struct PlaylistPreviewView: View {
    let country: Country
    let genre: String
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var musicService = MusicBrainzService()
    
    var body: some View {
        NavigationView {
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
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                
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
                                    ArtistCard(artist: artist)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Generate Button
                    VStack {
                        
                        Button(action: {
                            // TODO: Generate playlist action
                            print("Generate playlist for \(genre) from \(country.name)")
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title3)
                                Text("Generate Playlist")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding()
                        .background(.clear)
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
        }
    }
}

// MARK: - Artist Card

struct ArtistCard: View {
    let artist: Artist
    
    var body: some View {
        HStack(spacing: 16) {
            // Artist avatar placeholder
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: "music.mic")
                    .foregroundColor(.white)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(artist.displayInfo)
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
