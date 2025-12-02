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
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 38/255, green: 147/255, blue: 155/255),
                        Color(red: 25/255, green: 110/255, blue: 125/255),
                        Color(red: 20/255, green: 90/255, blue: 100/255)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if storageManager.savedPlaylists.isEmpty {
                    emptyStateView
                } else {
                    playlistListView
                }
            }
            .navigationTitle("Recent Playlists")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                Color(red: 38/255, green: 147/255, blue: 155/255),
                for: .navigationBar
            )
            .toolbar {
                if !storageManager.savedPlaylists.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive, action: {
                                playlistToDelete = nil
                                showDeleteConfirmation = true
                            }) {
                                Label("Clear All", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search playlists")
            .alert("Clear All Playlists", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    if let playlist = playlistToDelete {
                        storageManager.removePlaylist(playlist)
                        playlistToDelete = nil
                    } else {
                        storageManager.clearAll()
                    }
                }
            } message: {
                if playlistToDelete != nil {
                    Text("Are you sure you want to delete this playlist? This cannot be undone.")
                } else {
                    Text("Are you sure you want to delete all saved playlists? This cannot be undone.")
                }
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
        VStack(spacing: 24) {
            Spacer()
            
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            VStack(spacing: 12) {
                Text("No Playlists Yet")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Start exploring countries and genres to generate your first playlist!")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Playlist List
    
    private var playlistListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Stats header
                if !searchText.isEmpty && filteredPlaylists.count != storageManager.savedPlaylists.count {
                    HStack {
                        Text("Found \(filteredPlaylists.count) of \(storageManager.savedPlaylists.count) playlists")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                } else {
                    statsHeaderView
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                }
                
                // Playlist cards
                LazyVStack(spacing: 12) {
                    ForEach(filteredPlaylists) { playlist in
                        PlaylistCard(playlist: playlist) {
                            handlePlaylistTap(playlist)
                        } onDelete: {
                            playlistToDelete = playlist
                            showDeleteConfirmation = true
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeaderView: some View {
        HStack(spacing: 0) {
            StatBadge(
                value: "\(storageManager.totalPlaylistCount)",
                label: "Playlists",
                icon: "music.note.list"
            )
            
            Divider()
                .background(Color.white.opacity(0.3))
                .frame(height: 60)
            
            StatBadge(
                value: "\(storageManager.uniqueCountries.count)",
                label: "Countries",
                icon: "globe"
            )
            
            Divider()
                .background(Color.white.opacity(0.3))
                .frame(height: 60)
            
            StatBadge(
                value: "\(storageManager.uniqueGenres.count)",
                label: "Genres",
                icon: "guitars"
            )
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
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
            ZStack {
                // Background gradient matching theme
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 38/255, green: 147/255, blue: 155/255),
                        Color(red: 25/255, green: 110/255, blue: 125/255)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 28) {
                    Spacer()
                    
                    // Error icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow.opacity(0.9))
                    }
                    
                    VStack(spacing: 12) {
                        Text("Couldn't Load Playlist")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: onRetry) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("Try Again")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        Button(action: { dismiss() }) {
                            Text("Close")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle(playlistName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                Color(red: 38/255, green: 147/255, blue: 155/255),
                for: .navigationBar
            )
        }
    }
}

// MARK: - Playlist Card

struct PlaylistCard: View {
    let playlist: SavedPlaylist
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Playlist artwork
                playlistArtwork
                
                // Playlist info
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(playlist.countryFlagEmoji)
                            .font(.title3)
                        
                        Text(playlist.countryName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Text(playlist.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 10) {
                        // Genre tag
                        Text(playlist.genre)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.25))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        
                        // Track count
                        HStack(spacing: 4) {
                            Image(systemName: "music.note")
                                .font(.caption2)
                            Text("\(playlist.trackCount)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                    }
                    
                    // Date
                    Text(playlist.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isPressed ? 0.12 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(CardButtonStyle(isPressed: $isPressed))
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
        .frame(width: 90, height: 90)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 50/255, green: 180/255, blue: 185/255),
                        Color(red: 70/255, green: 160/255, blue: 180/255)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(spacing: 6) {
                    Text(playlist.countryFlagEmoji)
                        .font(.system(size: 32))
                    Image(systemName: "music.note")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
            )
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white.opacity(0.9))
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Playlist Loading View

struct PlaylistLoadingView: View {
    let playlistName: String
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 38/255, green: 147/255, blue: 155/255),
                        Color(red: 25/255, green: 110/255, blue: 125/255)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Loading spinner
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                            .frame(width: 60, height: 60)
                        
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                    
                    VStack(spacing: 10) {
                        Text("Loading Playlist")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Fetching \(playlistName) from Spotify...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle(playlistName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                Color(red: 38/255, green: 147/255, blue: 155/255),
                for: .navigationBar
            )
        }
    }
}
