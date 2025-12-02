import SwiftUI

// MARK: - Recent Playlists View

struct RecentPlaylistsView: View {
    @StateObject private var storageManager = PlaylistStorageManager.shared
    @StateObject private var spotifyAPI = SpotifyWebAPI.shared
    @StateObject private var dataProvider = CountriesDataProvider()
    
    @State private var selectedPlaylistData: SelectedPlaylistData? = nil
    
    struct SelectedPlaylistData: Identifiable {
        let id = UUID()
        let savedPlaylist: SavedPlaylist
        let country: Country
    }
    
    @State private var searchText = ""
    @State private var showDeleteConfirmation = false
    @State private var playlistToDelete: SavedPlaylist?
    
    var filteredPlaylists: [SavedPlaylist] {
        if searchText.isEmpty {
            return storageManager.savedPlaylists
        }
        return storageManager.savedPlaylists.filter { playlist in
            playlist.name.localizedCaseInsensitiveContains(searchText) ||
            playlist.countryName.localizedCaseInsensitiveContains(searchText) ||
            playlist.genre.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if storageManager.savedPlaylists.isEmpty {
                    emptyStateView
                } else {
                    playlistListView
                }
            }
            .navigationTitle("Recent Playlists")
            .toolbar {
                if !storageManager.savedPlaylists.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive, action: {
                                showDeleteConfirmation = true
                            }) {
                                Label("Clear All", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search playlists")
            .alert("Clear All Playlists", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    storageManager.clearAll()
                }
            } message: {
                Text("Are you sure you want to delete all saved playlists? This cannot be undone.")
            }
            .sheet(item: $selectedPlaylistData) { data in
                PlaylistLoadingWrapper(
                    savedPlaylist: data.savedPlaylist,
                    country: data.country
                )
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Playlists Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start exploring countries and genres to generate your first playlist!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
                .frame(height: 40)
        }
        .padding()
    }
    
    // MARK: - Playlist List
    
    private var playlistListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Stats header
                if !searchText.isEmpty && filteredPlaylists.count != storageManager.savedPlaylists.count {
                    Text("Found \(filteredPlaylists.count) of \(storageManager.savedPlaylists.count) playlists")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                } else {
                    statsHeaderView
                }
                
                // Playlist cards
                ForEach(filteredPlaylists) { playlist in
                    PlaylistCard(playlist: playlist) {
                        handlePlaylistTap(playlist)
                    } onDelete: {
                        playlistToDelete = playlist
                        showDeleteConfirmation = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeaderView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatBadge(
                    value: "\(storageManager.totalPlaylistCount)",
                    label: "Playlists",
                    icon: "music.note.list"
                )
                
                StatBadge(
                    value: "\(storageManager.uniqueCountries.count)",
                    label: "Countries",
                    icon: "globe"
                )
                
                StatBadge(
                    value: "\(storageManager.uniqueGenres.count)",
                    label: "Genres",
                    icon: "guitars"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Actions
    
    private func handlePlaylistTap(_ playlist: SavedPlaylist) {
        // Find the matching country
        if let country = dataProvider.countries.first(where: { $0.name == playlist.countryName }) {
            selectedPlaylistData = SelectedPlaylistData(
                savedPlaylist: playlist,
                country: country
            )
        }
    }
}

// MARK: - Playlist Loading Wrapper

struct PlaylistLoadingWrapper: View {
    let savedPlaylist: SavedPlaylist
    let country: Country
    
    @StateObject private var spotifyAPI = SpotifyWebAPI.shared
    @State private var fullPlaylist: SpotifyPlaylist?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                PlaylistLoadingView(playlistName: savedPlaylist.name)
            } else if let error = errorMessage {
                PlaylistErrorView(
                    playlistName: savedPlaylist.name,
                    error: error,
                    onRetry: {
                        loadPlaylist()
                    }
                )
            } else if let playlist = fullPlaylist {
                PlaylistDetailView(
                    country: country,
                    genre: savedPlaylist.genre,
                    playlist: playlist
                )
            }
        }
        .task {
            loadPlaylist()
        }
    }
    
    private func loadPlaylist() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Fetch full playlist details from Spotify API
                let playlist = try await spotifyAPI.fetchFullPlaylist(
                    playlistId: savedPlaylist.spotifyPlaylistId,
                    market: getMarketCode(for: savedPlaylist.countryName)
                )
                
                await MainActor.run {
                    self.fullPlaylist = playlist
                    self.isLoading = false
                }
            } catch SpotifyServiceError.noAccessToken {
                await MainActor.run {
                    self.errorMessage = "Please connect your Spotify account to view this playlist."
                    self.isLoading = false
                }
            } catch SpotifyServiceError.badResponse(let status, let message) {
                await MainActor.run {
                    if status == 404 {
                        self.errorMessage = "This playlist no longer exists on Spotify."
                    } else if status == 401 {
                        self.errorMessage = "Your Spotify session has expired. Please reconnect."
                    } else {
                        self.errorMessage = "Failed to load playlist: \(message)"
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load playlist: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func getMarketCode(for countryName: String) -> String {
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
        return countryCodeMap[countryName] ?? "US"
    }
}

// MARK: - Playlist Error View

struct PlaylistErrorView: View {
    let playlistName: String
    let error: String
    let onRetry: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Couldn't Load Playlist")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(error)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                VStack(spacing: 12) {
                    Button(action: onRetry) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Close")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationTitle(playlistName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Playlist Card

struct PlaylistCard: View {
    let playlist: SavedPlaylist
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Playlist artwork
                playlistArtwork
                
                // Playlist info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(playlist.countryFlagEmoji)
                            .font(.title3)
                        
                        Text(playlist.countryName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(playlist.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Genre tag
                        Text(playlist.genre)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                        
                        Spacer()
                        
                        // Track count
                        HStack(spacing: 4) {
                            Image(systemName: "music.note")
                                .font(.caption2)
                            Text("\(playlist.trackCount)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    // Date
                    Text(playlist.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var playlistArtwork: some View {
        Group {
            if let imageUrl = playlist.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_), .empty:
                        placeholderArtwork
                    @unknown default:
                        placeholderArtwork
                    }
                }
            } else {
                placeholderArtwork
            }
        }
        .frame(width: 80, height: 80)
        .cornerRadius(8)
    }
    
    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(spacing: 4) {
                    Text(playlist.countryFlagEmoji)
                        .font(.title)
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            )
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Playlist Loading View

struct PlaylistLoadingView: View {
    let playlistName: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.bottom, 20)
                
                VStack(spacing: 8) {
                    Text("Loading Playlist")
                        .font(.headline)
                    
                    Text("Fetching \(playlistName) from Spotify...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .navigationTitle(playlistName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
