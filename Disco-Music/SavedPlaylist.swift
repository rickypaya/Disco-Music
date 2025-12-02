//
//  SavedPlaylist.swift
//  Disco-Music
//
//  Created by Ricardo Payares on 12/2/25.
//


import Foundation
import Combine

// MARK: - Saved Playlist Model

struct SavedPlaylist: Identifiable, Codable {
    let id: String
    let spotifyPlaylistId: String
    let name: String
    let description: String?
    let countryName: String
    let countryFlagEmoji: String
    let genre: String
    let imageUrl: String?
    let trackCount: Int
    let createdAt: Date
    
    init(from playlist: SpotifyPlaylist, country: Country, genre: String) {
        self.id = UUID().uuidString
        self.spotifyPlaylistId = playlist.id
        self.name = playlist.name
        self.description = playlist.description
        self.countryName = country.name
        self.countryFlagEmoji = country.flagEmoji
        self.genre = genre
        self.imageUrl = playlist.images?.first?.url
        self.trackCount = playlist.tracks?.items.count ?? 0
        self.createdAt = Date()
    }
}

// MARK: - Playlist Storage Manager

class PlaylistStorageManager: ObservableObject {
    static let shared = PlaylistStorageManager()
    
    @Published var savedPlaylists: [SavedPlaylist] = []
    
    private let storageKey = "saved_playlists"
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadPlaylists()
    }
    
    // MARK: - Public Methods
    
    /// Save a newly generated playlist to local storage
    func savePlaylist(_ playlist: SpotifyPlaylist, country: Country, genre: String) {
        let savedPlaylist = SavedPlaylist(
            from: playlist,
            country: country,
            genre: genre
        )
        
        // Add to beginning of array (most recent first)
        savedPlaylists.insert(savedPlaylist, at: 0)
        
        // Limit to 50 most recent playlists
        if savedPlaylists.count > 50 {
            savedPlaylists = Array(savedPlaylists.prefix(50))
        }
        
        persistPlaylists()
        
        print("✅ Saved playlist: \(savedPlaylist.name)")
    }
    
    /// Remove a playlist from storage
    func removePlaylist(_ playlist: SavedPlaylist) {
        savedPlaylists.removeAll { $0.id == playlist.id }
        persistPlaylists()
        
        print("🗑️ Removed playlist: \(playlist.name)")
    }
    
    /// Clear all saved playlists
    func clearAll() {
        savedPlaylists.removeAll()
        persistPlaylists()
        
        print("🗑️ Cleared all saved playlists")
    }
    
    /// Check if a playlist is already saved
    func isPlaylistSaved(spotifyId: String) -> Bool {
        savedPlaylists.contains { $0.spotifyPlaylistId == spotifyId }
    }
    
    // MARK: - Filtering & Sorting
    
    /// Get playlists filtered by country
    func playlistsForCountry(_ countryName: String) -> [SavedPlaylist] {
        savedPlaylists.filter { $0.countryName == countryName }
    }
    
    /// Get playlists filtered by genre
    func playlistsForGenre(_ genre: String) -> [SavedPlaylist] {
        savedPlaylists.filter { $0.genre == genre }
    }
    
    /// Get playlists sorted by date (newest first)
    var playlistsSortedByDate: [SavedPlaylist] {
        savedPlaylists.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Statistics
    
    /// Get total number of saved playlists
    var totalPlaylistCount: Int {
        savedPlaylists.count
    }
    
    /// Get unique countries represented
    var uniqueCountries: [String] {
        Array(Set(savedPlaylists.map { $0.countryName })).sorted()
    }
    
    /// Get unique genres represented
    var uniqueGenres: [String] {
        Array(Set(savedPlaylists.map { $0.genre })).sorted()
    }
    
    // MARK: - Private Methods
    
    private func loadPlaylists() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            print("📦 No saved playlists found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            savedPlaylists = try decoder.decode([SavedPlaylist].self, from: data)
            print("✅ Loaded \(savedPlaylists.count) saved playlists")
        } catch {
            print("❌ Failed to load playlists: \(error)")
            savedPlaylists = []
        }
    }
    
    private func persistPlaylists() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(savedPlaylists)
            userDefaults.set(data, forKey: storageKey)
            print("💾 Persisted \(savedPlaylists.count) playlists")
        } catch {
            print("❌ Failed to persist playlists: \(error)")
        }
    }
}

// MARK: - Helper Extensions

extension SavedPlaylist {
    /// Format the creation date for display
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    /// Format the creation date as a short date
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
    
    /// Format the creation date with time
    var fullDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}
